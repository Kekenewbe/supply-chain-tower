#!/usr/bin/env python
"""
balance-check.py - Tracker outillage vs livraison sur 3 repos.

Lit git log des 3 repos (Espace_Opti, VisualPrompt, SocialFlow) sur une
periode configurable, classifie chaque commit en OUTILLAGE ou LIVRAISON,
calcule le ratio, et emet une alerte si > seuil outillage.

Usage:
    python scripts/balance-check.py           # derniers 7 jours
    python scripts/balance-check.py --days 30 # derniers 30 jours
    python scripts/balance-check.py --json    # output JSON machine-readable

Heuristique de classification (simple mais robuste) :
- Espace_Opti = OUTILLAGE par defaut (meta-repo infra)
- VisualPrompt / SocialFlow = LIVRAISON par defaut (projets metier)
    - Exceptions: chore(rules|tooling|scaffold), chore: initial scaffold,
      Clean retire worktrees... -> OUTILLAGE (configs propagees depuis
      le meta-repo)

Exit code:
    0 = sain (ratio outillage <= SEUIL_ALERTE_OUTILLAGE)
    1 = alerte (ratio outillage > SEUIL_ALERTE_OUTILLAGE)
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

DESKTOP = Path("C:/Users/caste/Desktop")

REPOS = {
    "Espace_Opti": DESKTOP / "Espace_Opti",
    "VisualPrompt": DESKTOP / "VisualPrompt",
    "SocialFlow": DESKTOP / "SocialFlow",
}

META_REPO = "Espace_Opti"

OUTILLAGE_PATTERNS_IN_PROJECT = [
    re.compile(r"^chore\((rules|tooling|scaffold|manager)\)", re.IGNORECASE),
    re.compile(r"^chore:\s*initial scaffold", re.IGNORECASE),
    re.compile(r"^Clean\s+-\s+retire\s+worktrees", re.IGNORECASE),
    re.compile(r"^chore:\s*mark.*DONE in modules\.json", re.IGNORECASE),
]

SEUIL_ALERTE_OUTILLAGE = 0.70
RATIO_CIBLE_OUTILLAGE = 0.30


@dataclass
class Commit:
    hash: str
    message: str
    repo: str
    category: str


def classify(repo: str, message: str) -> str:
    if repo == META_REPO:
        return "OUTILLAGE"
    for pat in OUTILLAGE_PATTERNS_IN_PROJECT:
        if pat.search(message):
            return "OUTILLAGE"
    return "LIVRAISON"


def collect_commits(repo_name: str, repo_path: Path, days: int) -> list[Commit]:
    if not (repo_path / ".git").exists():
        return []
    out = subprocess.run(
        ["git", "-C", str(repo_path), "log", f"--since={days} days ago", "--oneline"],
        capture_output=True,
        text=True,
        timeout=15,
    )
    if out.returncode != 0:
        return []
    commits: list[Commit] = []
    for line in out.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(" ", 1)
        if len(parts) < 2:
            continue
        h, msg = parts
        commits.append(Commit(hash=h, message=msg, repo=repo_name, category=classify(repo_name, msg)))
    return commits


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    all_commits: list[Commit] = []
    per_repo: dict[str, dict[str, int]] = {}
    for name, path in REPOS.items():
        commits = collect_commits(name, path, args.days)
        all_commits.extend(commits)
        per_repo[name] = {
            "total": len(commits),
            "outillage": sum(1 for c in commits if c.category == "OUTILLAGE"),
            "livraison": sum(1 for c in commits if c.category == "LIVRAISON"),
        }

    total = len(all_commits)
    outillage = sum(1 for c in all_commits if c.category == "OUTILLAGE")
    livraison = total - outillage
    ratio_outillage = outillage / total if total else 0.0
    alerte = ratio_outillage > SEUIL_ALERTE_OUTILLAGE and total > 0

    if args.json:
        print(json.dumps({
            "days": args.days,
            "total": total,
            "outillage": outillage,
            "livraison": livraison,
            "ratio_outillage": round(ratio_outillage, 3),
            "seuil_alerte": SEUIL_ALERTE_OUTILLAGE,
            "cible": RATIO_CIBLE_OUTILLAGE,
            "alerte": alerte,
            "per_repo": per_repo,
        }, indent=2))
        return 1 if alerte else 0

    print(f"=== Balance outillage/livraison sur {args.days} jours ===\n")
    for name, stats in per_repo.items():
        if stats["total"] == 0:
            print(f"  {name:15s} : aucun commit")
            continue
        o, l, t = stats["outillage"], stats["livraison"], stats["total"]
        print(f"  {name:15s} : {t:3d} commits | OUTILLAGE {o:3d} | LIVRAISON {l:3d}")
    print()
    print(f"TOTAL ({args.days}j) : {total} commits | OUTILLAGE {outillage} ({ratio_outillage:.0%}) | LIVRAISON {livraison} ({1-ratio_outillage:.0%})")
    print(f"Cible saine : OUTILLAGE <= {RATIO_CIBLE_OUTILLAGE:.0%}. Seuil alerte : > {SEUIL_ALERTE_OUTILLAGE:.0%}.")
    print()
    if alerte:
        print(f"[ALERTE] Ratio outillage {ratio_outillage:.0%} > seuil {SEUIL_ALERTE_OUTILLAGE:.0%}.")
        print("Action recommandee : prioriser 2-3 commits livraison (VisualPrompt / SocialFlow)")
        print("avant tout nouveau chantier outillage.")
    elif ratio_outillage > RATIO_CIBLE_OUTILLAGE:
        print(f"[WARNING] Ratio outillage {ratio_outillage:.0%} > cible {RATIO_CIBLE_OUTILLAGE:.0%} mais <= seuil alerte {SEUIL_ALERTE_OUTILLAGE:.0%}.")
        print("Tendance a surveiller : prochains commits idealement cotes livraison.")
    else:
        print(f"[OK] Ratio outillage {ratio_outillage:.0%} <= cible {RATIO_CIBLE_OUTILLAGE:.0%}.")

    return 1 if alerte else 0


if __name__ == "__main__":
    sys.exit(main())
