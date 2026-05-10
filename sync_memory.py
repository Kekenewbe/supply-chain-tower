#!/usr/bin/env python
"""
sync_memory.py — Sync Obsidian vault notes into Pinecone vector store.

Reads all .md files from the Obsidian vault, splits them by markdown headers
using LangChain's MarkdownHeaderTextSplitter, generates embeddings locally via
sentence-transformers (all-MiniLM-L6-v2, 384 dims), and upserts vectors +
metadata into Pinecone. 100% free, no cloud embedding API required.

# First run will download ~90MB model "all-MiniLM-L6-v2" automatically.
# Subsequent runs use the cached model — no internet needed.

Environment variables (loaded from .env if present):
    PINECONE_API_KEY — Pinecone API key (required)
    OBSIDIAN_VAULT   — Path to Obsidian vault (default: C:\\Users\\caste\\Documents\\Obsidian Vault)

Flags:
    --force          Bypass vault-unchanged check and always sync
    --dry-run        Preview operations (scan, split, embed-count) without
                     touching Pinecone or persisting state. Network-free.
    --full-reindex   Ignore the local fingerprint cache and re-embed every
                     note. Combinable with --dry-run.
"""

import os
import re
import sys
import json
import argparse
import hashlib
from pathlib import Path
from datetime import datetime, timezone

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from dotenv import load_dotenv
from langchain_text_splitters import MarkdownHeaderTextSplitter
from sentence_transformers import SentenceTransformer
from pinecone import Pinecone, ServerlessSpec

# ─── Configuration ────────────────────────────────────────────────────────────

# Load .env from the script's own directory, regardless of current CWD.
# encoding='utf-8-sig' strips a leading BOM if the file was saved as UTF-8 with BOM
# (otherwise the first key gets parsed as '\ufeffPINECONE_API_KEY' and is invisible).
_DOTENV_PATH = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=_DOTENV_PATH, encoding="utf-8-sig", override=False)

DEFAULT_INDEX_NAME = "obsidian-memory"  # Resolution: --index CLI > PINECONE_INDEX env > this default
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
EMBEDDING_DIMENSION = 384
BATCH_SIZE = 100  # Pinecone upsert batch size

# State file stores the last vault fingerprint (hash + timestamp).
# Stored in Espace_Opti/.claude/, never in the vault itself.
_STATE_FILE = Path(__file__).resolve().parent / ".claude" / "memory_state.json"

HEADERS_TO_SPLIT_ON = [
    ("#", "Header1"),
    ("##", "Header2"),
    ("###", "Header3"),
]

# Regex pour blocs <private>...</private> : exclus avant vectorisation
PRIVATE_BLOCK_RE = re.compile(r"<private>.*?</private>", re.DOTALL | re.IGNORECASE)


# ─── Vault fingerprint (Option D: MD5 hash over sorted mtime+size+path) ───────

def compute_vault_fingerprint(md_files: list[Path]) -> str:
    """Compute a stable fingerprint of the vault state.

    Strategy (Option D):
    - For each .md file (sorted by path): combine str(mtime_ns) + str(size) + str(path)
    - MD5 over the concatenated string.

    This detects: additions, deletions, modifications, renames — all without
    reading file contents. Cost: one os.stat() per file (~1ms for 35 files).
    Deletion is caught because the sorted file list itself changes.
    """
    parts = []
    for f in md_files:
        try:
            st = f.stat()
            parts.append(f"{f}:{st.st_mtime_ns}:{st.st_size}")
        except OSError:
            # File disappeared between listing and stat — treat as changed
            parts.append(f"{f}:missing")
    raw = "\n".join(parts)
    return hashlib.md5(raw.encode("utf-8")).hexdigest()


def load_state() -> dict:
    """Load persisted sync state from _STATE_FILE. Returns {} if absent."""
    try:
        return json.loads(_STATE_FILE.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_state(fingerprint: str) -> None:
    """Persist the current vault fingerprint + timestamp to _STATE_FILE."""
    _STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    state = {
        "vault_fingerprint": fingerprint,
        "last_sync": datetime.now(timezone.utc).isoformat(),
    }
    _STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")


def is_vault_unchanged(md_files: list[Path], force: bool, full_reindex: bool = False) -> tuple[bool, str]:
    """Return (skip, fingerprint).

    skip=True  → vault is unchanged since last sync, embedding can be skipped.
    skip=False → vault changed (or first run, or --force, or --full-reindex), must sync.
    Also returns the current fingerprint so caller can save it after sync.

    --full-reindex implies bypassing the cache: every chunk is re-embedded.
    """
    if force or full_reindex:
        return False, compute_vault_fingerprint(md_files)

    current_fp = compute_vault_fingerprint(md_files)
    state = load_state()
    stored_fp = state.get("vault_fingerprint", "")

    if current_fp == stored_fp:
        last_sync = state.get("last_sync", "unknown")
        print(f"\n[SKIP] Vault unchanged since last sync ({last_sync}) — skipping embedding.")
        return True, current_fp

    return False, current_fp


# ─── Original helpers ─────────────────────────────────────────────────────────

def strip_private_blocks(content: str, note_name: str) -> str:
    """Supprime les blocs <private>...</private> d'une note avant vectorisation."""
    if "<private>" not in content.lower():
        return content
    matches = PRIVATE_BLOCK_RE.findall(content)
    if matches:
        cleaned = PRIVATE_BLOCK_RE.sub("", content)
        print(f"  [PRIVATE] Note {note_name} : {len(matches)} bloc(s) prive(s) exclu(s)")
        return cleaned
    return content


def validate_env():
    """Validate that all required environment variables are set.

    Read after load_dotenv() so values from the .env file are visible even
    when the module-level import order is unusual.
    """
    pinecone_key = os.getenv("PINECONE_API_KEY")
    vault_str = os.getenv("OBSIDIAN_VAULT", r"C:\Users\caste\Documents\Obsidian Vault")

    if not pinecone_key:
        print("[-] Missing environment variable: PINECONE_API_KEY")
        print(f"   Looked for .env at: {_DOTENV_PATH}")
        print("   Set it in a .env file or export it before running.")
        sys.exit(1)

    vault_path = Path(vault_str)
    if not vault_path.exists():
        print(f"[-] Obsidian vault not found at: {vault_path}")
        print("   Set OBSIDIAN_VAULT env var to the correct path.")
        sys.exit(1)

    return vault_path, pinecone_key


def collect_markdown_files(vault_path: Path) -> list[Path]:
    """Recursively collect all .md files from the vault, skipping hidden dirs."""
    md_files = []
    for md_file in vault_path.rglob("*.md"):
        parts = md_file.relative_to(vault_path).parts
        if any(part.startswith(".") for part in parts):
            continue
        md_files.append(md_file)
    return sorted(md_files)


def split_document(file_path: Path, vault_path: Path) -> list[dict]:
    """Split a markdown file into chunks using header-based splitting."""
    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        print(f"  [WARN] Could not read {file_path.name}: {e}")
        return []

    if not content.strip():
        return []

    # Strip blocs <private>...</private> avant vectorisation (P4.2)
    content = strip_private_blocks(content, file_path.name)

    if not content.strip():
        return []

    splitter = MarkdownHeaderTextSplitter(
        headers_to_split_on=HEADERS_TO_SPLIT_ON,
        strip_headers=False,
    )
    splits = splitter.split_text(content)

    relative_path = str(file_path.relative_to(vault_path)).replace("\\", "/")
    chunks = []

    for i, doc in enumerate(splits):
        text = doc.page_content.strip()
        if not text:
            continue

        chunk_id = hashlib.md5(
            f"{relative_path}::chunk_{i}".encode()
        ).hexdigest()

        # Truncate text in UTF-8 bytes (not chars) to respect Pinecone 40960 metadata limit.
        # Reserve ~5KB for other metadata fields + JSON overhead. Decode with errors='ignore'
        # to drop any partial multi-byte char at the truncation boundary (S2 Phase 4.4 fix).
        text_safe = text.encode("utf-8")[:35000].decode("utf-8", errors="ignore")
        metadata = {
            "text": text_safe,
            "source": relative_path,
            "chunk_index": i,
            "header1": doc.metadata.get("Header1", ""),
            "header2": doc.metadata.get("Header2", ""),
            "header3": doc.metadata.get("Header3", ""),
            "synced_at": datetime.now(timezone.utc).isoformat(),
        }
        chunks.append({"id": chunk_id, "text": text, "metadata": metadata})

    return chunks


def create_index_if_absent(pc: Pinecone, index_name: str, confirm: bool = True) -> bool:
    """Create Pinecone index if absent, with user confirmation (rule 13 anti-API-silent).

    Args:
        pc: Pinecone client.
        index_name: Index name (kebab-case <project-name>-memory recommended).
        confirm: If True, prompts user via input() before API call. False = bypass (CI/automation).

    Returns:
        True if index exists or was just created, False if user declined creation.
    """
    existing = [idx.name for idx in pc.list_indexes()]
    if index_name in existing:
        print(f"[OK] Index '{index_name}' existe deja")
        return True

    if confirm:
        ans = input(f"[CONFIRM] Creer index Pinecone '{index_name}' ? (y/N): ")
        if ans.strip().lower() != "y":
            print("[SKIP] Creation annulee par utilisateur")
            return False

    print(f"[CREATE] Creating Pinecone index '{index_name}' (dim={EMBEDDING_DIMENSION}, metric=cosine, aws us-east-1)...")
    pc.create_index(
        name=index_name,
        dimension=EMBEDDING_DIMENSION,
        metric="cosine",
        spec=ServerlessSpec(cloud="aws", region="us-east-1"),
    )
    print(f"   [OK] Index '{index_name}' created.")
    return True


def ensure_pinecone_index(pc: Pinecone, index_name: str) -> None:
    """Create the Pinecone index if missing, or recreate it if the dimension mismatches."""
    existing = {idx.name: idx for idx in pc.list_indexes()}

    if index_name in existing:
        desc = pc.describe_index(index_name)
        current_dim = getattr(desc, "dimension", None)
        if current_dim != EMBEDDING_DIMENSION:
            print(
                f"[WARN] Index '{index_name}' has dimension {current_dim}, "
                f"expected {EMBEDDING_DIMENSION}. Recreating..."
            )
            pc.delete_index(index_name)
        else:
            print(f"[OK] Index '{index_name}' already exists (dim={current_dim}).")
            return

    print(f"[CREATE] Creating Pinecone index '{index_name}' (dim={EMBEDDING_DIMENSION})...")
    pc.create_index(
        name=index_name,
        dimension=EMBEDDING_DIMENSION,
        metric="cosine",
        spec=ServerlessSpec(cloud="aws", region="us-east-1"),
    )
    print(f"   [OK] Index '{index_name}' created.")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse CLI flags. Kept separate so tests can call it without sys.argv side-effects."""
    parser = argparse.ArgumentParser(
        prog="sync_memory.py",
        description="Sync Obsidian vault notes into Pinecone vector store.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Bypass the vault-unchanged fingerprint check and always sync.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview the operations (scan, split, embed-count) without "
             "touching Pinecone or persisting state. Network-free.",
    )
    parser.add_argument(
        "--full-reindex",
        action="store_true",
        help="Ignore the local fingerprint cache and re-embed every note. "
             "Combinable with --dry-run for a preview.",
    )
    parser.add_argument(
        "--index",
        type=str,
        default=None,
        metavar="NAME",
        help="Override Pinecone index name. Resolution: --index > PINECONE_INDEX env > "
             "default 'obsidian-memory'. Recommended kebab-case <project-name>-memory.",
    )
    parser.add_argument(
        "--create-index",
        action="store_true",
        help="Create the Pinecone index (dim=384, metric=cosine, aws us-east-1) then exit "
             "without sync. Prompts for confirmation. Combinable with --index.",
    )
    return parser.parse_args(argv)


def main():
    args = parse_args()
    force = args.force
    dry_run = args.dry_run
    full_reindex = args.full_reindex

    # Resolve index name: --index CLI > PINECONE_INDEX env > DEFAULT_INDEX_NAME
    index_name = args.index or os.getenv("PINECONE_INDEX") or DEFAULT_INDEX_NAME

    # Mode --create-index : create then exit (no sync). Rule 13 anti-API-silent.
    if args.create_index:
        print("=" * 60)
        print(f"  [--create-index] Creating Pinecone index '{index_name}' then exit (no sync)")
        print("=" * 60)
        _, pinecone_key = validate_env()
        pc = Pinecone(api_key=pinecone_key)
        ok = create_index_if_absent(pc, index_name, confirm=True)
        sys.exit(0 if ok else 1)

    print("=" * 60)
    print(f"  Obsidian -> Pinecone Memory Sync (index='{index_name}')")
    if force:
        print("  [--force] Bypassing vault-unchanged check")
    if full_reindex:
        print("  [--full-reindex] Ignoring fingerprint cache — re-embedding all notes")
    if dry_run:
        print("  [--dry-run] Preview mode — no Pinecone writes, no state persisted")
    print("=" * 60)
    print()

    vault_path, pinecone_key = validate_env()
    print(f"[VAULT] {vault_path}")

    md_files = collect_markdown_files(vault_path)
    print(f"[FILES] Found {len(md_files)} markdown files")

    if not md_files:
        print("   Nothing to sync.")
        return

    # ── Option D: skip early if vault fingerprint unchanged ───────────────────
    skip, current_fingerprint = is_vault_unchanged(md_files, force, full_reindex)
    if skip:
        return
    # ─────────────────────────────────────────────────────────────────────────

    print("\n[SPLIT] Splitting documents by headers...")
    all_chunks = []
    for md_file in md_files:
        chunks = split_document(md_file, vault_path)
        if chunks:
            all_chunks.extend(chunks)
            print(f"   {md_file.relative_to(vault_path)} -> {len(chunks)} chunks")

    print(f"\n[STATS] Total chunks to embed: {len(all_chunks)}")

    if not all_chunks:
        print("   No content to sync.")
        # Still save fingerprint so next run also skips correctly,
        # but only when actually persisting (not in dry-run).
        if not dry_run:
            save_state(current_fingerprint)
        return

    if dry_run:
        # Preview-only summary: report what would happen without touching Pinecone.
        print(f"\n{'=' * 60}")
        print(f"  [DRY-RUN] Preview complete — no Pinecone writes performed")
        print(f"     Files scanned   : {len(md_files)}")
        print(f"     Chunks to embed : {len(all_chunks)} (would-be upsert)")
        print(f"     Chunks to delete: 0 (script is upsert-only by chunk_id)")
        print(f"     Fingerprint     : {current_fingerprint[:12]}... (would be persisted)")
        print(f"     State file path : {_STATE_FILE}")
        print(f"{'=' * 60}")
        return

    pc = Pinecone(api_key=pinecone_key)
    ensure_pinecone_index(pc, index_name)
    index = pc.Index(index_name)

    print(f"\n[EMBED] Loading local model '{EMBEDDING_MODEL}' (dim={EMBEDDING_DIMENSION})...")
    model = SentenceTransformer(EMBEDDING_MODEL)
    texts = [c["text"] for c in all_chunks]
    embeddings = model.encode(texts, show_progress_bar=True, convert_to_numpy=True)
    print(f"   [OK] Generated {len(embeddings)} embeddings")

    print(f"\n[UPSERT] Upserting to Pinecone index '{index_name}'...")
    vectors = []
    for chunk, embedding in zip(all_chunks, embeddings):
        vectors.append({
            "id": chunk["id"],
            "values": embedding.tolist(),
            "metadata": chunk["metadata"],
        })

    upserted = 0
    for i in range(0, len(vectors), BATCH_SIZE):
        batch = vectors[i : i + BATCH_SIZE]
        index.upsert(vectors=batch)
        upserted += len(batch)
        print(f"   [UP] Upserted {upserted}/{len(vectors)} vectors")

    # ── Persist fingerprint only after successful upsert ──────────────────────
    save_state(current_fingerprint)

    stats = index.describe_index_stats()
    print(f"\n{'=' * 60}")
    print(f"  [DONE] Sync complete!")
    print(f"     Files processed : {len(md_files)}")
    print(f"     Chunks upserted : {len(vectors)}")
    print(f"     Index total     : {stats.total_vector_count}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
