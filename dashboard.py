"""Espace_Opti Dashboard — FastAPI server for project management and live agent monitoring."""
import asyncio
import json
import os
import re
import socket
import subprocess
import time
import urllib.request
import urllib.error
import webbrowser
from pathlib import Path
from typing import Any, Optional
from datetime import datetime, timedelta

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, FileResponse
from pydantic import BaseModel
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import uvicorn

# Metrics & cache globaux (lazy loading + temps de reponse)
_STARTUP_TIME = datetime.now()
_FILES_CACHE: dict[str, tuple[float, list[dict]]] = {}
FILES_CACHE_TTL = 30.0  # secondes - cache 30s pour onglet Fichiers
_RESPONSE_TIMES: dict[str, list[float]] = {}  # endpoint -> [ms,...] (cap a 100)

# Fix P1 - cache scan_projects + api_project (TTL 10s)
# Clef "scan" pour la liste des projets, "project:<name>" pour un projet donne.
_PROJECTS_CACHE: dict[str, tuple[float, Any]] = {}
_PROJECT_CACHE_TTL = 10.0

# Fix P1 os.walk - dossiers lourds a ne JAMAIS descendre.
# Applique via pruning in-place dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
# pour eviter la recursion sur des milliers de fichiers sans interet metier.
SKIP_DIRS = frozenset({
    "node_modules",
    ".git",
    "__pycache__",
    "worktrees",          # .claude/worktrees peut contenir des milliers de fichiers
    "graphify-out",
    "dist",
    "build",
    ".next",
    ".turbo",
    ".parcel-cache",
    ".mypy_cache",
    ".cache",
    "venv",
    ".venv",
    "env",
    ".pytest_cache",
})


def _fast_mtime_max(base: Path) -> float:
    """mtime du fichier le plus recent dans `base`, sans rglob.

    Utilise os.walk avec pruning SKIP_DIRS. Prealablement, scan_projects
    utilisait proj.rglob("*") qui plongeait dans node_modules + worktrees
    + graphify-out -> jusqu'a 10s par projet. Ici on reste sur les dossiers
    source et les dossiers de travail Claude Code.
    """
    try:
        max_mtime = base.stat().st_mtime if base.exists() else 0.0
    except OSError:
        max_mtime = 0.0
    try:
        for root, dirs, files in os.walk(str(base)):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for fname in files:
                fp = os.path.join(root, fname)
                try:
                    mtime = os.path.getmtime(fp)
                except (OSError, FileNotFoundError):
                    continue
                if mtime > max_mtime:
                    max_mtime = mtime
    except OSError:
        pass
    return max_mtime


def _invalidate_project_cache(name: Optional[str] = None) -> None:
    """Invalide le cache projet apres ecriture (POST file/inbox/command).

    name=None => clear complet (cas d'un nouveau projet cree).
    Sinon, on supprime l'entree du projet + l'entree "scan" puisque le
    mtime max aurait pu changer.
    """
    if name is None:
        _PROJECTS_CACHE.clear()
        return
    _PROJECTS_CACHE.pop(f"project:{name}", None)
    _PROJECTS_CACHE.pop("scan", None)


def _cached_scan_projects() -> list[dict]:
    now = time.time()
    cached = _PROJECTS_CACHE.get("scan")
    if cached and (now - cached[0]) < _PROJECT_CACHE_TTL:
        return cached[1]
    result = scan_projects()
    _PROJECTS_CACHE["scan"] = (now, result)
    return result


def _build_project_data(name: str) -> dict:
    """Corps (synchrone) de /api/project/{name}. Extrait pour cacher."""
    proj = _find_project(name)
    modules_data = _safe_json(proj / "modules.json") or {}
    is_template = (name == "Espace_Opti")
    if is_template and (proj / "PRD_WORKSPACE.md").exists():
        prd_content = _safe_read(proj / "PRD_WORKSPACE.md") or ""
    else:
        prd_content = _safe_read(proj / "PRD.md") or ""
    reviews = collect_module_reviews(proj)
    return {
        "name": name,
        "path": str(proj),
        "is_template": is_template,
        "claude_md": _safe_read(proj / "CLAUDE.md") or "",
        "prd": prd_content,
        "architecture": _safe_read(proj / "ARCHITECTURE.md") or "",
        "modules": modules_data.get("modules", []) if isinstance(modules_data, dict) else [],
        "modules_raw": _safe_read(proj / "modules.json") or "",
        "reviews": reviews,
        "ui_rules": _safe_read(proj / "UI_PROJECT.md") or "",
    }


def _cached_api_project(name: str) -> dict:
    now = time.time()
    key = f"project:{name}"
    cached = _PROJECTS_CACHE.get(key)
    if cached and (now - cached[0]) < _PROJECT_CACHE_TTL:
        return cached[1]
    data = _build_project_data(name)
    _PROJECTS_CACHE[key] = (now, data)
    return data

DESKTOP = Path("C:/Users/caste/Desktop")
ESPACE_OPTI = DESKTOP / "Espace_Opti"
OBSIDIAN_VAULT = Path(os.environ.get("OBSIDIAN_VAULT", r"C:\Users\caste\Documents\Obsidian Vault"))
PORT = 3131

app = FastAPI(title="Espace_Opti Dashboard")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Response-Time"],
)


@app.middleware("http")
async def add_response_time_header(request, call_next):
    """Mesure le temps de chaque requete et expose X-Response-Time header.

    Permet au frontend de correler latence client-side (console.time) et
    latence serveur-side sans outillage externe (BUG 3 diagnostic).
    """
    started = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - started) * 1000.0
    response.headers["X-Response-Time"] = f"{elapsed_ms:.1f}"
    try:
        path = request.url.path
        if path.startswith("/api/"):
            _record_response_time(path, elapsed_ms)
    except Exception:
        pass
    return response


class FileWrite(BaseModel):
    path: str
    content: str


class CommandRun(BaseModel):
    command: str


class NewProject(BaseModel):
    name: str


class InboxMessage(BaseModel):
    content: str


class ObsidianNote(BaseModel):
    folder: str
    title: str
    content: str


class UIRules(BaseModel):
    rules: Optional[str] = ""
    reference_url: Optional[str] = ""
    reference_description: Optional[str] = ""
    code_sample: Optional[str] = ""
    palette: Optional[dict] = None
    typography: Optional[dict] = None


class GithubSetup(BaseModel):
    repo_url: str


class PRDEvolution(BaseModel):
    idea: str


def _safe_read(path: Path) -> Optional[str]:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None


def _safe_json(path: Path) -> Optional[dict]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def _project_status(total: int, done: int, approved: int, has_prd: bool, has_modules: bool) -> str:
    if total == 0 and not has_prd:
        return "New"
    if total == 0 and has_prd:
        return "Starting"
    if total > 0 and (done + approved) >= total:
        return "Done"
    return "InProgress"


def _iter_project_dirs():
    try:
        for entry in DESKTOP.iterdir():
            if not entry.is_dir():
                continue
            if (entry / ".claude" / "settings.json").exists():
                yield entry
    except Exception:
        return


def scan_projects() -> list[dict]:
    projects = []
    for proj in _iter_project_dirs():
        try:
            name = proj.name
            modules_data = _safe_json(proj / "modules.json") or {}
            modules = modules_data.get("modules", []) if isinstance(modules_data, dict) else []
            total = len(modules)
            done = sum(1 for m in modules if m.get("status") == "DONE")
            approved = sum(1 for m in modules if m.get("status") == "APPROVED")
            has_prd = (proj / "PRD.md").exists()
            has_architecture = (proj / "ARCHITECTURE.md").exists()
            has_modules = (proj / "modules.json").exists()
            # Fix P1 os.walk - _fast_mtime_max remplace rglob("*") (facteur 40x+)
            try:
                mtime = _fast_mtime_max(proj)
                if mtime == 0.0:
                    mtime = proj.stat().st_mtime
            except Exception:
                mtime = proj.stat().st_mtime
            is_template = (name == "Espace_Opti")
            projects.append({
                "name": name,
                "path": str(proj),
                "module_count": total,
                "done_count": done,
                "approved_count": approved,
                "has_prd": has_prd,
                "has_architecture": has_architecture,
                "has_modules": has_modules,
                "last_modified": datetime.fromtimestamp(mtime).isoformat(),
                "status": _project_status(total, done, approved, has_prd, has_modules),
                "is_template": is_template,
            })
        except Exception:
            continue
    # Tri : template en premier, puis par dernière modification
    projects.sort(key=lambda p: (not p["is_template"], datetime.fromisoformat(p["last_modified"])), reverse=False)
    projects = sorted(projects, key=lambda p: (not p["is_template"], -datetime.fromisoformat(p["last_modified"]).timestamp()))
    return projects


def _find_project(name: str) -> Path:
    proj = DESKTOP / name
    if not (proj / ".claude" / "settings.json").exists():
        raise HTTPException(status_code=404, detail=f"Project {name} not found")
    return proj


def _list_files(base: Path, max_entries: int = 500) -> list[dict]:
    """Scan projet avec exclusions aggressives + cache 30s (lazy loading).

    Utilise os.walk + pruning in-place de dirs pour eviter la recursion
    dans les dossiers lourds (worktrees peut contenir des milliers de
    fichiers, node_modules/graphify-out/cache idem).
    """
    cache_key = str(base.resolve())
    now_ts = time.time()
    cached = _FILES_CACHE.get(cache_key)
    if cached and (now_ts - cached[0]) < FILES_CACHE_TTL:
        return cached[1]

    skip_dirs = {
        ".git", "node_modules", "__pycache__", ".venv", "venv",
        "dist", "build", "worktrees", ".mypy_cache", ".pytest_cache",
        ".next", ".turbo", ".parcel-cache",
    }
    excluded_prefixes = (
        ".claude/worktrees",
        "graphify-out/cache",
        "graphify-out/wiki",
    )

    items: list[dict] = []
    try:
        for root, dirs, files in os.walk(str(base)):
            dirs[:] = [d for d in dirs if d not in skip_dirs]
            root_path = Path(root)
            try:
                rel_root = root_path.relative_to(base).as_posix()
            except ValueError:
                continue
            if rel_root != "." and any(
                rel_root.startswith(pref) for pref in excluded_prefixes
            ):
                dirs[:] = []
                continue
            if rel_root != ".":
                items.append({"path": rel_root, "is_dir": True, "size": 0})
            for fname in files:
                fpath = root_path / fname
                try:
                    rel = fpath.relative_to(base).as_posix()
                    items.append({
                        "path": rel,
                        "is_dir": False,
                        "size": fpath.stat().st_size,
                    })
                except (OSError, ValueError):
                    continue
                if len(items) >= max_entries:
                    break
            if len(items) >= max_entries:
                break
    except Exception:
        pass

    items.sort(key=lambda x: (not x["is_dir"], x["path"].lower()))
    _FILES_CACHE[cache_key] = (now_ts, items)
    return items


def _parse_agent_frontmatter(path: Path) -> Optional[dict]:
    """Parse YAML frontmatter (--- ... ---) d'un fichier .md d'agent.

    Retourne un dict plat {clef: valeur string}. Support minimal :
    clefs simples et listes courtes (stockees en brut).
    """
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    if not content.startswith("---"):
        return None
    end_idx = content.find("\n---", 3)
    if end_idx < 0:
        return None
    fm_block = content[3:end_idx].strip()
    data: dict[str, str] = {}
    current_key: Optional[str] = None
    list_buf: list[str] = []
    for raw_line in fm_block.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            if current_key and list_buf:
                data[current_key] = ",".join(list_buf)
                list_buf = []
                current_key = None
            continue
        if line.startswith("  -") or line.startswith("- "):
            if current_key:
                list_buf.append(line.lstrip(" -").strip())
            continue
        if ":" in line and not line.startswith(" "):
            if current_key and list_buf:
                data[current_key] = ",".join(list_buf)
                list_buf = []
            key, _, value = line.partition(":")
            key = key.strip()
            value = value.strip()
            if value:
                data[key] = value
                current_key = None
            else:
                current_key = key
    if current_key and list_buf:
        data[current_key] = ",".join(list_buf)
    return data


def scan_agents(project_path: Path) -> list[dict]:
    """Liste tous les agents .claude/agents/*.md avec leur frontmatter parse."""
    agents_dir = project_path / ".claude" / "agents"
    if not agents_dir.exists():
        return []
    result: list[dict] = []
    for agent_file in sorted(agents_dir.glob("*.md")):
        fm = _parse_agent_frontmatter(agent_file)
        if not fm:
            continue
        result.append({
            "name": fm.get("name", agent_file.stem),
            "description": fm.get("description", ""),
            "model": fm.get("model", ""),
            "memory": fm.get("memory", ""),
            "color": fm.get("color", ""),
            "isolation": fm.get("isolation", ""),
            "tools": fm.get("tools", ""),
            "skills": fm.get("skills", ""),
            "file": agent_file.name,
        })
    return result


def _record_response_time(endpoint: str, elapsed_ms: float) -> None:
    bucket = _RESPONSE_TIMES.setdefault(endpoint, [])
    bucket.append(elapsed_ms)
    if len(bucket) > 100:
        del bucket[:-100]


# ─── P2.2 — Activité des agents ──────────────────────────────────────────
AGENT_FILE_RULES = [
    # (pattern, agent)
    (re.compile(r"\.(tsx|jsx|css|scss)$"), "frontend"),
    (re.compile(r"^(src[/\\])?api[/\\].*\.(ts|js|py)$"), "backend"),
    (re.compile(r"^(src[/\\])?services[/\\].*\.(ts|js|py)$"), "backend"),
    (re.compile(r"modules\.json$"), "manager"),
    (re.compile(r"REVIEW_REPORT\.md$"), "qa-review"),
    (re.compile(r"^tests[/\\]e2e[/\\]"), "playwright"),
    (re.compile(r"ARCHITECTURE\.md$"), "architecte"),
    (re.compile(r"simplified.*\.ts$"), "simplifier"),
    (re.compile(r"simplified.*\.js$"), "simplifier"),
]

ALL_AGENTS = ["manager", "architecte", "frontend", "backend",
              "securite", "qa-review", "simplifier", "playwright"]


def get_agent_activity(project_path: Path) -> dict:
    """Scanner les fichiers modifiés dans les 5 dernières minutes
    pour déduire l'agent actif. Retourne un dict { agent_name: {status, since_minutes} }.

    Fix P1 os.walk : remplace root.rglob("*") (qui plongeait dans
    node_modules, worktrees, graphify-out) par os.walk + pruning SKIP_DIRS.
    Gain attendu ~20-40x sur projets avec deps installees.
    """
    result = {a: {"status": "idle", "since_minutes": None} for a in ALL_AGENTS}
    now = datetime.now()
    cutoff_ts = (now - timedelta(minutes=5)).timestamp()

    scan_roots = [
        project_path / "src",
        project_path / ".claude" / "agent-memory",
        project_path,
    ]
    seen_files: set[str] = set()
    project_base = str(project_path)

    for root_path in scan_roots:
        if not root_path.exists():
            continue
        try:
            for root_dir, dirs, files in os.walk(str(root_path)):
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
                for fname in files:
                    fp = os.path.join(root_dir, fname)
                    if fp in seen_files:
                        continue
                    seen_files.add(fp)
                    try:
                        mtime_ts = os.path.getmtime(fp)
                    except (OSError, FileNotFoundError):
                        continue
                    if mtime_ts < cutoff_ts:
                        continue
                    # Chemin relatif au projet (pas au scan_root) pour matcher
                    # les AGENT_FILE_RULES inchangees.
                    if fp.startswith(project_base):
                        rel = fp[len(project_base):].lstrip("\\/").replace("\\", "/")
                    else:
                        try:
                            rel = str(Path(fp).relative_to(project_path)).replace("\\", "/")
                        except ValueError:
                            continue
                    for pattern, agent in AGENT_FILE_RULES:
                        if pattern.search(rel):
                            since = int((now.timestamp() - mtime_ts) / 60)
                            existing = result[agent]
                            if existing["status"] == "idle" or (existing["since_minutes"] or 999) > since:
                                result[agent] = {"status": "active", "since_minutes": since}
                            break
        except OSError:
            continue

    return result


# ─── P3.2 — Parse REVIEW_REPORT.md ────────────────────────────────────────
REVIEW_SCORE_RE = re.compile(r"Score\s*:\s*(\d+)\s*/\s*100", re.IGNORECASE)
REVIEW_STATUS_RE = re.compile(r"(APPROUVÉ|REJETÉ|APPROVED|REJECTED)", re.IGNORECASE)


def parse_review_report(path: Path) -> dict:
    content = _safe_read(path) or ""
    if not content:
        return {"score": None, "status": None, "blockers": []}
    score_match = REVIEW_SCORE_RE.search(content)
    status_match = REVIEW_STATUS_RE.search(content)
    blockers = []
    in_blockers = False
    for line in content.splitlines():
        low = line.lower()
        if "blocker" in low or "bloquant" in low:
            in_blockers = True
            continue
        if in_blockers:
            stripped = line.strip()
            if not stripped:
                in_blockers = False
                continue
            if stripped.startswith(("-", "*", "•")):
                blockers.append(stripped.lstrip("-*• ").strip())
            elif stripped.startswith("#"):
                in_blockers = False
    return {
        "score": int(score_match.group(1)) if score_match else None,
        "status": status_match.group(1).upper() if status_match else None,
        "blockers": blockers,
    }


def collect_module_reviews(project_path: Path) -> dict:
    """Retourne { module_id: {score, status, blockers} } en scannant les REVIEW_REPORT*.md.

    Fix P1 os.walk : remplace project_path.rglob("REVIEW_REPORT*.md") par
    os.walk + pruning SKIP_DIRS. Sur SocialFlow (node_modules installe)
    passe de ~5s a <200ms.
    """
    reviews: dict = {}
    try:
        for root, dirs, files in os.walk(str(project_path)):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for fname in files:
                if not (fname.startswith("REVIEW_REPORT") and fname.endswith(".md")):
                    continue
                review_file = Path(root) / fname
                info = parse_review_report(review_file)
                name = review_file.stem.replace("REVIEW_REPORT", "").strip("-_. ")
                if not name:
                    content = _safe_read(review_file) or ""
                    m = re.search(r"module\s+([a-zA-Z0-9_-]+)", content)
                    if m:
                        name = m.group(1)
                if name:
                    reviews[name] = info
    except OSError:
        pass
    return reviews


@app.get("/", response_class=HTMLResponse)
async def root():
    html_path = Path(__file__).parent / "dashboard.html"
    if not html_path.exists():
        return HTMLResponse("<h1>dashboard.html missing</h1>", status_code=500)
    return FileResponse(str(html_path))


# Fix P0 - def (pas async def) : FastAPI delegue au threadpool (40 threads
# par defaut) ce qui parallelise les I/O synchrones et debloque l'event loop.
@app.get("/api/projects")
def api_projects():
    return _cached_scan_projects()


@app.get("/api/project/{name}")
def api_project(name: str):
    return _cached_api_project(name)


# ─── Lazy endpoints — chargés uniquement quand l'onglet est cliqué ─────────
@app.get("/api/project/{name}/files-list")
async def api_files_list(name: str):
    proj = _find_project(name)
    return {"files": _list_files(proj)}


@app.get("/api/project/{name}/log")
async def api_agent_log(name: str):
    proj = _find_project(name)
    return {
        "agent_log": _safe_read(proj / ".claude" / "agent-log.txt") or "",
        "graph_report": _safe_read(proj / "graphify-out" / "GRAPH_REPORT.md") or "",
    }


@app.get("/api/project/{name}/file")
async def api_get_file(name: str, path: str):
    proj = _find_project(name)
    target = (proj / path).resolve()
    try:
        target.relative_to(proj.resolve())
    except ValueError:
        raise HTTPException(status_code=400, detail="Path escapes project")
    if not target.exists() or not target.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    try:
        content = target.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"path": path, "content": content}


@app.post("/api/project/{name}/file")
async def api_write_file(name: str, payload: FileWrite):
    proj = _find_project(name)
    target = (proj / payload.path).resolve()
    try:
        target.relative_to(proj.resolve())
    except ValueError:
        raise HTTPException(status_code=400, detail="Path escapes project")
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(payload.content, encoding="utf-8")
        # Fix P1 - ecriture fichier => cache projet obsolete
        _invalidate_project_cache(name)
        _FILES_CACHE.pop(str(proj.resolve()), None)
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


COMMAND_MAP = {
    "lite": ["powershell", "-NoProfile", "-File", "lite.ps1"],
    "full": ["powershell", "-NoProfile", "-File", "full.ps1"],
    "sync": ["python", "sync_memory.py"],
    "graphify": [
        "python", "-c",
        "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
    ],
    "git-status": ["git", "status", "--short"],
    "git-log": ["git", "log", "--oneline", "-10"],
}


@app.post("/api/project/{name}/command")
async def api_run_command(name: str, payload: CommandRun):
    proj = _find_project(name)
    cmd = COMMAND_MAP.get(payload.command)
    if not cmd:
        raise HTTPException(status_code=400, detail=f"Unknown command {payload.command}")
    try:
        result = subprocess.run(
            cmd,
            cwd=str(proj),
            capture_output=True,
            text=True,
            timeout=120,
        )
        # Fix P1 - commande peut avoir modifie des fichiers
        _invalidate_project_cache(name)
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr,
            "returncode": result.returncode,
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": "Command timed out after 120s", "returncode": -1}
    except Exception as e:
        return {"success": False, "output": "", "error": str(e), "returncode": -1}


@app.post("/api/projects/new")
async def api_new_project(payload: NewProject):
    if not re.match(r"^[A-Za-z0-9][A-Za-z0-9-]*$", payload.name):
        raise HTTPException(status_code=400, detail="Invalid project name")
    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-File", "new-project.ps1", payload.name],
            cwd=str(ESPACE_OPTI),
            capture_output=True,
            text=True,
            timeout=120,
        )
        # Fix P1 - nouveau projet : invalide TOUT le cache
        _invalidate_project_cache()
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr,
        }
    except Exception as e:
        return {"success": False, "output": "", "error": str(e)}


# ─── P2.2 — Activité des agents ──────────────────────────────────────────
# Fix P0 - def pour threadpool (get_agent_activity fait du rglob bloquant).
@app.get("/api/project/{name}/agents/activity")
def api_agents_activity(name: str):
    proj = _find_project(name)
    return get_agent_activity(proj)


# ─── P2.5 — Inbox ────────────────────────────────────────────────────────
def _inbox_side_effects(proj: Path, content_len: int) -> None:
    """Effets secondaires differes : marker + log + invalidation cache.

    S'execute APRES la reponse HTTP (BackgroundTasks) pour garantir une
    latence < 500ms perceptible par l'utilisateur cote dashboard.
    """
    try:
        marker = proj / ".claude" / "inbox_ready"
        marker.parent.mkdir(parents=True, exist_ok=True)
        marker.write_text(datetime.now().isoformat(), encoding="utf-8")
    except OSError:
        pass
    try:
        log_path = proj / ".claude" / "dashboard.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(
                f"[INBOX] {datetime.now().isoformat()} "
                f"len={content_len} marker=inbox_ready\n"
            )
    except OSError:
        pass
    _FILES_CACHE.pop(str(proj.resolve()), None)
    # Fix P1 - invalide le cache projet : inbox/current.md modifie change mtime
    _invalidate_project_cache(proj.name)


@app.post("/api/project/{name}/inbox")
async def api_inbox_write(
    name: str,
    payload: InboxMessage,
    background_tasks: BackgroundTasks,
):
    """Ecrit inbox/current.md et renvoie 200 le plus vite possible.

    Optimistic UI : la reponse HTTP est emise des que inbox/current.md est sur
    disque. Les effets secondaires (marker inbox_ready, log, invalidation
    cache) sont delegues a BackgroundTasks et s'executent APRES la
    reponse pour minimiser la latence percue (< 500ms vise).
    """
    started = time.perf_counter()
    proj = _find_project(name)
    inbox_path = proj / "inbox" / "current.md"
    try:
        inbox_path.parent.mkdir(parents=True, exist_ok=True)
        existing = inbox_path.read_text(encoding="utf-8") if inbox_path.exists() else ""
        sep = "\n\n---\n\n" if existing.strip() else ""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        new_content = existing + sep + f"[{timestamp}]\n{payload.content}"
        inbox_path.write_text(new_content, encoding="utf-8")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    background_tasks.add_task(_inbox_side_effects, proj, len(payload.content))
    elapsed_ms = (time.perf_counter() - started) * 1000.0
    _record_response_time("inbox", elapsed_ms)
    return {
        "success": True,
        "path": "inbox/current.md",
        "elapsed_ms": round(elapsed_ms, 1),
    }


# ─── BUG 6 — UI/UX auto-remplissage depuis UI_DIRECTIVES.md ──────────────
_UI_SECTION_RE = re.compile(
    r"^##\s+(?:\d+\.\s+)?([A-Z][^\n]+?)\s*$",
    re.MULTILINE,
)
_URL_RE = re.compile(r"https?://[^\s)\"']+")


def _split_markdown_sections(content: str) -> dict[str, str]:
    """Decoupe un markdown en sections indexees par titre H2 (insensible a la casse)."""
    sections: dict[str, str] = {}
    matches = list(_UI_SECTION_RE.finditer(content))
    for idx, match in enumerate(matches):
        title = match.group(1).strip().upper()
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(content)
        sections[title] = content[start:end].strip()
    return sections


def _find_section(sections: dict[str, str], *keywords: str) -> str:
    """Cherche une section dont le titre contient un des keywords."""
    upper_keywords = [k.upper() for k in keywords]
    for title, body in sections.items():
        if any(kw in title for kw in upper_keywords):
            return body
    return ""


def _extract_css_root(body: str) -> str:
    """Extrait le bloc CSS entre :root { et } s'il existe dans la section."""
    idx_start = body.find(":root")
    if idx_start < 0:
        return ""
    brace = body.find("{", idx_start)
    if brace < 0:
        return ""
    depth = 1
    cursor = brace + 1
    while cursor < len(body) and depth > 0:
        ch = body[cursor]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        cursor += 1
    if depth != 0:
        return body[idx_start:].strip()
    return body[idx_start:cursor].strip()


def parse_ui_directives(path: Path) -> dict:
    """Parse UI_DIRECTIVES.md en 3 champs : a (regles), b (urls), c (CSS).

    Section A = "PHILOSOPHIE DESIGN" + "A NE JAMAIS FAIRE" concatene.
    Section B = URLs extraites de "REFERENCES".
    Section C = Bloc CSS :root { ... } de "PALETTE DE COULEURS".
    """
    if not path.exists():
        return {"a": "", "b": [], "c": "", "source": None}
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return {"a": "", "b": [], "c": "", "source": str(path)}
    sections = _split_markdown_sections(content)
    philo = _find_section(sections, "PHILOSOPHIE")
    never = _find_section(sections, "A NE JAMAIS", "JAMAIS FAIRE", "NE JAMAIS")
    section_a_parts = [p for p in (philo, ("A NE JAMAIS FAIRE\n" + never) if never else "") if p]
    section_a = "\n\n".join(section_a_parts).strip()

    refs = _find_section(sections, "REFERENCE")
    urls = []
    seen = set()
    for line in refs.splitlines():
        for url in _URL_RE.findall(line):
            if url in seen:
                continue
            seen.add(url)
            label = line.strip().lstrip("-*• ").strip()
            if url in label:
                label = label.replace(url, "").strip(" :-—")
            urls.append({"url": url, "label": label or url})
    if not urls:
        for line in refs.splitlines():
            stripped = line.strip().lstrip("-*• ").strip()
            if not stripped:
                continue
            if ":" in stripped:
                name, _, rest = stripped.partition(":")
                guessed = f"https://{name.strip().lower()}"
                if guessed not in seen:
                    seen.add(guessed)
                    urls.append({"url": guessed, "label": stripped})

    palette = _find_section(sections, "PALETTE")
    css_block = _extract_css_root(palette)

    return {
        "a": section_a,
        "b": urls,
        "c": css_block,
        "source": str(path),
    }


@app.get("/api/project/{name}/ui-directives")
async def api_ui_directives(name: str):
    """Auto-remplissage onglet UI/UX depuis UI_DIRECTIVES.md.

    Retourne les 3 sections A/B/C pretes a etre injectees dans les champs
    du formulaire frontend. Si UI_DIRECTIVES.md est absent, retourne des
    champs vides + un flag source=null pour que le frontend propose un
    bouton "Creer depuis template".
    """
    proj = _find_project(name)
    return parse_ui_directives(proj / "UI_DIRECTIVES.md")


@app.get("/api/project/{name}/agents")
async def api_agents_list(name: str):
    """Liste les agents .claude/agents/*.md parse depuis leur frontmatter.

    Fixe BUG 4 : l'onglet Agents restait vide car aucun endpoint ne
    retournait la liste. On parse le YAML frontmatter manuellement pour
    eviter une dependance PyYAML.
    """
    proj = _find_project(name)
    return {"agents": scan_agents(proj)}


@app.get("/api/health")
async def api_health():
    """Statut dashboard + temps de reponse moyens par endpoint."""
    uptime = (datetime.now() - _STARTUP_TIME).total_seconds()
    averages = {
        endpoint: round(sum(values) / len(values), 1)
        for endpoint, values in _RESPONSE_TIMES.items()
        if values
    }
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "uptime_seconds": round(uptime, 1),
        "response_time_ms_avg": averages,
        "cache_entries": len(_FILES_CACHE),
    }


@app.post("/api/project/{name}/obsidian-note")
async def api_obsidian_note(name: str, payload: ObsidianNote):
    if payload.folder not in {"decisions", "specs", "journal"}:
        raise HTTPException(status_code=400, detail="folder must be decisions, specs, or journal")
    safe_title = re.sub(r"[^A-Za-z0-9_\-]", "_", payload.title).strip("_") or "note"
    filename = f"{datetime.now().strftime('%Y-%m-%d')}-{safe_title}.md"
    target = OBSIDIAN_VAULT / payload.folder / filename
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(payload.content, encoding="utf-8")
        return {"success": True, "path": str(target)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─── P2.7 — UI rules & screenshots ───────────────────────────────────────
@app.get("/api/project/{name}/ui-rules")
async def api_get_ui_rules(name: str):
    proj = _find_project(name)
    ui_file = proj / "UI_PROJECT.md"
    content = _safe_read(ui_file) or ""
    refs_dir = proj / "ui-refs"
    screenshots = []
    if refs_dir.exists():
        for f in refs_dir.iterdir():
            if f.is_file() and f.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".webp"}:
                screenshots.append(f.name)
    return {"content": content, "screenshots": screenshots}


@app.post("/api/project/{name}/ui-rules")
async def api_save_ui_rules(name: str, payload: UIRules):
    proj = _find_project(name)
    target = proj / "UI_PROJECT.md"
    blocks = []
    blocks.append("# UI/UX — Règles du projet\n")
    if payload.rules:
        blocks.append("## Règles textuelles\n" + payload.rules.strip() + "\n")
    if payload.reference_url:
        blocks.append(f"## URL de référence\n[{payload.reference_description or payload.reference_url}]({payload.reference_url})\n")
    if payload.code_sample:
        blocks.append("## Code de référence\n```\n" + payload.code_sample.strip() + "\n```\n")
    if payload.palette:
        pal = "\n".join(f"- {k}: {v}" for k, v in payload.palette.items())
        blocks.append("## Palette\n" + pal + "\n")
    if payload.typography:
        typo = "\n".join(f"- {k}: {v}" for k, v in payload.typography.items())
        blocks.append("## Typographie\n" + typo + "\n")
    try:
        target.write_text("\n".join(blocks), encoding="utf-8")
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/project/{name}/ui-screenshot")
async def api_ui_screenshot(name: str, file: UploadFile = File(...)):
    proj = _find_project(name)
    refs_dir = proj / "ui-refs"
    refs_dir.mkdir(parents=True, exist_ok=True)
    safe_name = re.sub(r"[^A-Za-z0-9_.\-]", "_", file.filename or "screenshot.png")
    target = refs_dir / safe_name
    try:
        content = await file.read()
        target.write_bytes(content)
        return {"success": True, "filename": safe_name}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─── P2.8 — Évolution PRD ────────────────────────────────────────────────
@app.post("/api/project/{name}/prd-evolution")
async def api_prd_evolution(name: str, payload: PRDEvolution):
    proj = _find_project(name)
    prd_path = proj / "PRD.md"
    current_prd = prd_path.read_text(encoding="utf-8") if prd_path.exists() else "(aucun PRD)"
    inbox_path = proj / "inbox" / "current.md"
    inbox_path.parent.mkdir(parents=True, exist_ok=True)
    msg = (
        "@manager ÉVOLUTION PRD DEMANDÉE:\n"
        f"Idée: {payload.idea}\n\n"
        f"PRD actuel:\n{current_prd}\n\n"
        "Produis un diff clair :\n"
        "AVANT: [texte original]\n"
        "APRÈS: [texte proposé]\n"
        "MODULES IMPACTÉS: [liste]\n"
        "Attends la validation avant toute modification."
    )
    existing = inbox_path.read_text(encoding="utf-8") if inbox_path.exists() else ""
    sep = "\n\n---\n\n" if existing.strip() else ""
    inbox_path.write_text(existing + sep + msg, encoding="utf-8")
    return {"success": True}


# ─── P3.4 — MCP status ───────────────────────────────────────────────────
# Fix P0 - def : urllib.urlopen est 100% synchrone, blocait l'event loop
# jusqu'a 4s quand MCP offline. En def, s'execute dans threadpool.
_MCP_STATUS_CACHE: dict[str, tuple[float, dict]] = {}
_MCP_STATUS_TTL = 45.0


@app.get("/api/status")
@app.get("/api/mcp/status")
def api_mcp_status():
    now_ts = time.time()
    cached = _MCP_STATUS_CACHE.get("status")
    if cached and (now_ts - cached[0]) < _MCP_STATUS_TTL:
        return cached[1]

    obsidian_ok = False
    pinecone_ok = False
    # Obsidian check
    try:
        req = urllib.request.Request("https://127.0.0.1:27124/")
        import ssl
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        urllib.request.urlopen(req, timeout=2, context=ctx)
        obsidian_ok = True
    except Exception:
        obsidian_ok = False
    # Pinecone check — try import + api key
    try:
        api_key = os.environ.get("PINECONE_API_KEY")
        if api_key:
            env_path = ESPACE_OPTI / ".env"
            if env_path.exists():
                pinecone_ok = True
            else:
                pinecone_ok = True
        else:
            env_path = ESPACE_OPTI / ".env"
            if env_path.exists():
                content = env_path.read_text(encoding="utf-8", errors="replace")
                if "PINECONE_API_KEY" in content:
                    pinecone_ok = True
    except Exception:
        pinecone_ok = False

    payload = {"obsidian": obsidian_ok, "pinecone": pinecone_ok}
    _MCP_STATUS_CACHE["status"] = (now_ts, payload)
    return payload


# ─── P3.4b — Ecosystem status ────────────────────────────────────────────
# Cache TTL 60s — dict module-level, same pattern as _MCP_STATUS_CACHE
_ECOSYSTEM_CACHE: dict[str, tuple[float, dict]] = {}
_ECOSYSTEM_CACHE_TTL = 60.0

_ECOSYSTEM_REPOS = {
    "Espace_Opti": DESKTOP / "Espace_Opti",
    "VisualPrompt": DESKTOP / "VisualPrompt",
    "SocialFlow": DESKTOP / "SocialFlow",
}


@app.get("/api/ecosystem-status")
def api_ecosystem_status():
    """Retourne l etat global de l ecosysteme Espace_Opti (agents, hooks, MCP, projets, backlog, balance)."""
    now_ts = time.time()
    cached = _ECOSYSTEM_CACHE.get("status")
    if cached and (now_ts - cached[0]) < _ECOSYSTEM_CACHE_TTL:
        return cached[1]

    # agents_count
    try:
        agents_count = len(list((ESPACE_OPTI / ".claude" / "agents").glob("*.md")))
    except Exception:
        agents_count = 0

    # hooks_count — exclure les .bak
    try:
        hooks_count = len([
            f for f in (ESPACE_OPTI / ".claude" / "hooks").glob("*.py")
            if not f.name.endswith(".bak")
        ])
    except Exception:
        hooks_count = 0

    # mcp_count — parser .mcp.json, fallback 0
    mcp_count = 0
    try:
        mcp_file = ESPACE_OPTI / ".mcp.json"
        if mcp_file.exists():
            mcp_data = json.loads(mcp_file.read_text(encoding="utf-8"))
            mcp_count = len(mcp_data.get("mcpServers", mcp_data.get("servers", {})))
    except Exception:
        mcp_count = 0

    # projects — liste fixe
    projects = ["Espace_Opti", "VisualPrompt", "SocialFlow"]

    # backlog_open_count — compter les "- [ ]" dans BACKLOG.md
    backlog_open_count = None
    try:
        backlog_path = ESPACE_OPTI / "BACKLOG.md"
        if backlog_path.exists():
            content = backlog_path.read_text(encoding="utf-8", errors="replace")
            backlog_open_count = content.count("- [ ]")
    except Exception:
        backlog_open_count = None

    # balance_ratio — scripts/balance-check.py --days 7 --json
    balance_ratio = None
    try:
        balance_script = ESPACE_OPTI / "scripts" / "balance-check.py"
        if balance_script.exists():
            result = subprocess.run(
                ["python", str(balance_script), "--days", "7", "--json"],
                capture_output=True, text=True, timeout=10,
                cwd=str(ESPACE_OPTI),
            )
            if result.returncode == 0 and result.stdout.strip():
                balance_data = json.loads(result.stdout)
                balance_ratio = float(balance_data["ratio_outillage"])
    except Exception:
        balance_ratio = None

    # last_commit_per_repo — git log --format=%h -1
    last_commit_per_repo: dict[str, Optional[str]] = {}
    for repo_name, repo_path in _ECOSYSTEM_REPOS.items():
        try:
            if repo_path.exists():
                result = subprocess.run(
                    ["git", "-C", str(repo_path), "log", "--format=%h", "-1"],
                    capture_output=True, text=True, timeout=5,
                )
                h = result.stdout.strip()
                last_commit_per_repo[repo_name] = h[:7] if h else None
            else:
                last_commit_per_repo[repo_name] = None
        except Exception:
            last_commit_per_repo[repo_name] = None

    payload = {
        "agents_count": agents_count,
        "hooks_count": hooks_count,
        "mcp_count": mcp_count,
        "projects": projects,
        "backlog_open_count": backlog_open_count,
        "balance_ratio": balance_ratio,
        "last_commit_per_repo": last_commit_per_repo,
        "generated_at": datetime.now().isoformat(),
    }
    _ECOSYSTEM_CACHE["status"] = (now_ts, payload)
    return payload


# ─── P3.4c — Regles agents ───────────────────────────────────────────────
@app.get("/api/rules")
def api_rules():
    """Retourne les regles <regles_dures> et delegation extraites de manager.md."""
    manager_path = ESPACE_OPTI / ".claude" / "agents" / "manager.md"
    content = _safe_read(manager_path)
    if content is None:
        raise HTTPException(status_code=404, detail=".claude/agents/manager.md introuvable")

    # Bloc 1 : contenu entre <regles_dures> et </regles_dures>
    regles_dures = ""
    if "<regles_dures>" in content and "</regles_dures>" in content:
        after_open = content.split("<regles_dures>", 1)[1]
        regles_dures = after_open.split("</regles_dures>", 1)[0].strip()

    # Bloc 2 : tout ce qui suit "## Regles de delegation et d autonomie"
    delegation = ""
    marker = "## Regles de delegation et d autonomie"
    if marker in content:
        delegation = content.split(marker, 1)[1].strip()
        delegation = marker + "\n\n" + delegation

    return {
        "regles_dures": regles_dures,
        "delegation": delegation,
        "source": ".claude/agents/manager.md",
        "generated_at": datetime.now().isoformat(),
    }


# ─── P3.5 — Ouvrir explorer ──────────────────────────────────────────────
@app.post("/api/project/{name}/open")
async def api_project_open(name: str):
    proj = _find_project(name)
    try:
        subprocess.Popen(["explorer.exe", str(proj)])
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─── P3.6 — GitHub projects ──────────────────────────────────────────────
def _git_remote_url(cwd: Path) -> Optional[str]:
    try:
        out = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            cwd=str(cwd), capture_output=True, text=True, timeout=5,
        )
        if out.returncode == 0:
            return out.stdout.strip()
    except Exception:
        pass
    return None


@app.get("/api/project/{name}/github-status")
async def api_github_status(name: str):
    proj = _find_project(name)
    url = _git_remote_url(proj)
    return {"remote": url}


@app.post("/api/project/{name}/github-setup")
async def api_github_setup(name: str, payload: GithubSetup):
    proj = _find_project(name)
    try:
        # Remove existing then add
        subprocess.run(["git", "remote", "remove", "origin"], cwd=str(proj), capture_output=True, text=True, timeout=5)
        r = subprocess.run(
            ["git", "remote", "add", "origin", payload.repo_url],
            cwd=str(proj), capture_output=True, text=True, timeout=10,
        )
        if r.returncode != 0:
            return {"success": False, "error": r.stderr or r.stdout}
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}


@app.post("/api/project/{name}/github-push")
async def api_github_push(name: str):
    proj = _find_project(name)
    try:
        subprocess.run(["git", "add", "-A"], cwd=str(proj), capture_output=True, text=True, timeout=30)
        subprocess.run(
            ["git", "-c", "user.email=dashboard@local", "-c", "user.name=dashboard",
             "commit", "-m", "chore: dashboard push"],
            cwd=str(proj), capture_output=True, text=True, timeout=30,
        )
        r = subprocess.run(
            ["git", "push", "-u", "origin", "HEAD"],
            cwd=str(proj), capture_output=True, text=True, timeout=120,
        )
        return {
            "success": r.returncode == 0,
            "output": r.stdout,
            "error": r.stderr,
        }
    except Exception as e:
        return {"success": False, "output": "", "error": str(e)}


# ─── P3.7 — GitHub template ──────────────────────────────────────────────
@app.get("/api/template/github-status")
async def api_template_github_status():
    url = _git_remote_url(ESPACE_OPTI)
    return {"remote": url}


@app.post("/api/template/github-setup")
async def api_template_github_setup(payload: GithubSetup):
    try:
        subprocess.run(["git", "remote", "remove", "origin"], cwd=str(ESPACE_OPTI), capture_output=True, text=True, timeout=5)
        r = subprocess.run(
            ["git", "remote", "add", "origin", payload.repo_url],
            cwd=str(ESPACE_OPTI), capture_output=True, text=True, timeout=10,
        )
        if r.returncode != 0:
            return {"success": False, "error": r.stderr or r.stdout}
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}


@app.post("/api/template/github-push")
async def api_template_github_push():
    try:
        subprocess.run(["git", "add", "-A"], cwd=str(ESPACE_OPTI), capture_output=True, text=True, timeout=30)
        subprocess.run(
            ["git", "-c", "user.email=dashboard@local", "-c", "user.name=dashboard",
             "commit", "-m", "chore: dashboard backup"],
            cwd=str(ESPACE_OPTI), capture_output=True, text=True, timeout=30,
        )
        r = subprocess.run(
            ["git", "push", "-u", "origin", "HEAD"],
            cwd=str(ESPACE_OPTI), capture_output=True, text=True, timeout=120,
        )
        return {
            "success": r.returncode == 0,
            "output": r.stdout,
            "error": r.stderr,
        }
    except Exception as e:
        return {"success": False, "output": "", "error": str(e)}


class ConnectionManager:
    def __init__(self):
        self.connections: dict[str, list[WebSocket]] = {}

    async def connect(self, project_name: str, websocket: WebSocket):
        await websocket.accept()
        self.connections.setdefault(project_name, []).append(websocket)

    def disconnect(self, project_name: str, websocket: WebSocket):
        if project_name in self.connections:
            try:
                self.connections[project_name].remove(websocket)
            except ValueError:
                pass
            if not self.connections[project_name]:
                del self.connections[project_name]

    async def broadcast(self, project_name: str, message: dict):
        dead = []
        for ws in self.connections.get(project_name, []):
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(project_name, ws)


manager = ConnectionManager()


class AgentLogHandler(FileSystemEventHandler):
    def __init__(self, project_name: str, log_path: Path, loop: asyncio.AbstractEventLoop):
        self.project_name = project_name
        self.log_path = log_path
        self.loop = loop
        self.position = log_path.stat().st_size if log_path.exists() else 0

    def on_modified(self, event):
        if Path(event.src_path).resolve() != self.log_path.resolve():
            return
        try:
            with open(self.log_path, "r", encoding="utf-8", errors="replace") as f:
                f.seek(self.position)
                new = f.read()
                self.position = f.tell()
            if new.strip():
                for line in new.splitlines():
                    if line.strip():
                        asyncio.run_coroutine_threadsafe(
                            manager.broadcast(self.project_name, {
                                "type": "log",
                                "line": line,
                                "timestamp": datetime.now().isoformat(),
                            }),
                            self.loop,
                        )
        except Exception:
            pass


@app.websocket("/ws/{project_name}")
async def websocket_endpoint(websocket: WebSocket, project_name: str):
    await manager.connect(project_name, websocket)
    proj = DESKTOP / project_name

    observer = None
    poll_task = None
    heartbeat_task = None

    try:
        modules_data = _safe_json(proj / "modules.json")
        await websocket.send_json({"type": "modules", "data": modules_data})

        log_path = proj / ".claude" / "agent-log.txt"
        if log_path.exists():
            loop = asyncio.get_running_loop()
            handler = AgentLogHandler(project_name, log_path, loop)
            observer = Observer()
            observer.schedule(handler, str(log_path.parent), recursive=False)
            observer.start()

        async def poll_modules():
            last_raw = None
            while True:
                await asyncio.sleep(3)
                raw = _safe_read(proj / "modules.json")
                if raw and raw != last_raw:
                    last_raw = raw
                    try:
                        data = json.loads(raw)
                        await manager.broadcast(project_name, {"type": "modules", "data": data})
                    except Exception:
                        pass

        async def heartbeat():
            while True:
                await asyncio.sleep(10)
                await manager.broadcast(project_name, {
                    "type": "heartbeat",
                    "timestamp": datetime.now().isoformat(),
                })

        poll_task = asyncio.create_task(poll_modules())
        heartbeat_task = asyncio.create_task(heartbeat())

        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        if poll_task:
            poll_task.cancel()
        if heartbeat_task:
            heartbeat_task.cancel()
        if observer:
            observer.stop()
            observer.join(timeout=2)
        manager.disconnect(project_name, websocket)


async def open_browser():
    await asyncio.sleep(1.5)
    webbrowser.open(f"http://localhost:{PORT}")


@app.on_event("startup")
async def startup():
    print(f"\n{'=' * 50}")
    print(f"  Espace_Opti Dashboard")
    print(f"  http://localhost:{PORT}")
    print(f"{'=' * 50}\n")
    asyncio.create_task(open_browser())


if __name__ == "__main__":
    uvicorn.run("dashboard:app", host="0.0.0.0", port=PORT, reload=False)
