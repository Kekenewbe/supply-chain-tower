# PRD Espace_Opti — Template Maître

## Vision
Espace de travail IA pour création de projets logiciels
sans connaissance en développement.

## Architecture
- 9 agents natifs (manager, architecte, frontend, backend,
  securite, qa-review, simplifier, playwright, estimateur)
- 3 couches mémoire (Graphify, Obsidian, Pinecone)
- Dashboard FastAPI http://localhost:3131
- Pipeline 7 phases PRD→Livraison

## Historique des améliorations
2026-04-14 : Pré-filtre sécurité regex
2026-04-14 : MEMORY_GLOBAL/PROJECT split
2026-04-14 : Agent @manager créé
2026-04-14 : Dashboard FastAPI créé
2026-04-14 : Documentation HTML créée (docs/)
2026-04-15 : effort=max activé + adaptive thinking désactivé
2026-04-15 : Stop hook + inbox_inject hook ajoutés
2026-04-15 : Dashboard 7 onglets (UI/UX, Commandes, Projets, PRD)
2026-04-15 : Lazy loading dashboard (latence corrigée)
2026-04-15 : write-inbox.ps1 (encodage UTF-8 sans BOM)
2026-04-15 : ASCII-only dans inbox.md pour tous les agents
2026-04-15 : Agent @estimateur créé
2026-04-15 : Audit complet 85/85 PASS
2026-04-15 : MEMORY_WORKSPACE.md créé
2026-04-15 : Worker PostToolUse permanent (memory_worker.py) — SUPPRIME le 2026-04-16 (migration claude-mem)
2026-04-15 : SQLite mémoire agents (memory_db.py + FTS5) — SUPPRIME le 2026-04-16 (migration claude-mem)
2026-04-15 : Workflow 3 couches mémoire dans 7 agents
2026-04-15 : Slash command /loop (tâches récurrentes)
2026-04-16 : Migration vers claude-mem (suppression memory_worker.py + memory_db.py maison)
2026-04-16 : Passage Opus 4.7 (manager, architecte, qa-review)
2026-04-16 : Effort level xhigh (remplace max)
2026-04-16 : Scan securite exhaustif dans qa-review
2026-04-16 : Agent optimiseur couleur teal, ajout SVG organigramme

## Prochaines améliorations planifiées
- Channels Telegram alertes
- Dashboard : intégration UI claude-mem (localhost:37777) en iframe
- sync_memory.py : mode incrémental (uniquement fichiers modifiés)
