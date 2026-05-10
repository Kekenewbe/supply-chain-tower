# Memory — Doctrine 5 registres + backlog snapshot

## Pourquoi cette doctrine

Espace_Opti vit sur 3 jours de pratique empirique (15 commits cumulés VP+Espace_Opti) qui ont révélé une faille structurelle : le contexte stratégique vit en mémoire conversationnelle Claude.ai, donc volatile (anomalie A15).

Le post Instagram du créateur 5-registres + l'analyse des patterns ReasoningBank (Ruflo) ont convergé sur la même solution : structurer la mémoire d'agent AVANT d'optimiser l'outillage.

"Un outil ne crée jamais de structure, il amplifie ce qui existe déjà."

Cette doctrine est la STRUCTURE. Obsidian (config dans .obsidian/) est l'AMPLIFICATEUR humain (graph view, canvas, requêtes Dataview). Les agents IA lisent les fichiers .md directement.

## Les 5 registres

1. **decisions.md** — Chaque choix structurant + le pourquoi (alternatives considérées + conséquences attendues)
2. **learnings.md** — Ce qui a été appris et qui change la façon de faire
3. **blockers.md** — Ce qui bloque ou se répète (avec dimension récurrence)
4. **journal.md** — Trace de chaque session de travail (résumé + commits + items déplacés)
5. **evals.md** — Quand l'IA hallucine, drift, ou devient obsolète (pour amélioration continue)

## Le 6e fichier — backlog.md

Snapshot append-only du backlog actif (qui vit en mémoire conversationnelle Claude.ai au quotidien). Le script scripts/end-session.ps1 propose à chaque fin de session de capturer un snapshot horodaté. Résout l'anomalie A15.

## Format des entrées

Voir Memory/SCHEMA.md.

## Comment ajouter une entrée

- Manuel (markdown brut) : ouvrir le fichier .md, ajouter section avec date + scope
- Via Obsidian + Templater : raccourci Templater → choisir template approprié
- Via end-session.ps1 (à venir Phase γ) : interactif, append automatique

## Comment lire la mémoire (avant de démarrer une session)

- Manuel : ouvrir les 5 registres, lire les 5 dernières entrées de chaque
- Obsidian : ouvrir le vault Memory/, voir Memory/_dataview/dashboard.md
- Via hook session-start (à venir Phase γ) : injection automatique top-N entrées dans contexte Claude Code

## Plugins Obsidian recommandés (à installer manuellement)

- Templater (essentiel) — templates pré-remplis avec date/scope
- Dataview (essentiel) — requêtes "tableau de bord"
- (optionnel plus tard) Tag Wrangler — nettoyage tags

## Liens

- Schéma : Memory/SCHEMA.md
- Templates : Memory/_templates/
- Tableau de bord : Memory/_dataview/dashboard.md
- Standard agents : ../AGENTS.md
