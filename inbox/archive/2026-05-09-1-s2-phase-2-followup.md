Le @manager voit e5a90 mais c est un bug subagent (variable env non propagee correctement). Verifications empiriques cote utilisateur :

- .env racine contient OBSIDIAN_API_KEY=4b20f...881da (canonique)
- Variable env User Windows = 4b20f...881da
- Process env PowerShell parent = 4b20f...881da
- Recherche grep "e5a90" dans tout le repo Espace_Opti = AUCUN match
- Recherche grep "e5a90" dans vault Obsidian externe = AUCUN match

Donc e5a90 n existe nulle part sur disque. C est une anomalie de propagation env vars dans le subagent @manager (anomalie A60 a graver ulterieurement).

Phase 2 utilise sync_memory.py qui charge .env via load_dotenv() directement. Le script lira 4b20f canonique peu importe ce que le subagent affiche dans son env.

GO Phase 2 S2 Option A : implementer --dry-run et --full-reindex natifs dans sync_memory.py + pivot OBSIDIAN_VAULT vers Memory/, conformement plan rapport Phase 1. Aucun blocage cle Obsidian (utilisee uniquement Phase 4 MCP, decision differee).
