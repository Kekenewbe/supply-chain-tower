---
description: Affiche l etat complet du workspace actuel - modules, agents, phase courante, git, tokens
---

Lance une verification complete de l etat du workspace.

Instructions pour @manager :

1. **modules.json** — si le fichier existe, afficher le status de chaque module
   (TODO / IN_PROGRESS / DONE / APPROVED) avec un compteur par statut.

2. **Phase courante** — chercher dans `.claude/agent-log.txt` les dernieres
   entrees pour determiner ou on en est dans le pipeline 7 phases
   (PRD / Architecture / Dev parallele / QA / Simplification / Tests E2E / Livraison).

3. **Dernier commit** — executer `git log -1 --oneline` et afficher le resultat.

4. **Fichiers non committes** — executer `git status --short` et afficher
   la liste (tronquer a 20 lignes max).

5. **Budget tokens** — si le contexte actuel est connu, afficher le
   pourcentage d'utilisation et le budget restant estime. Sinon, afficher
   "Non disponible".

6. **Agents actifs** — lister les agents ayant ecrit dans agent-log.txt
   dans les 30 dernieres minutes.

7. **Memoire claude-mem** — indiquer si le worker tourne sur 37777 :
   `curl -s http://localhost:37777/api/health` (timeout 2s).

Presenter tout dans un tableau markdown clair :

```
| Element        | Valeur                                |
|----------------|---------------------------------------|
| Phase courante | DEVELOPPEMENT (module auth-backend)   |
| Modules        | 2 DONE / 1 IN_PROGRESS / 3 TODO       |
| Dernier commit | abc123f - feat(phase-2): architecture |
| Non committes  | 5 fichiers (src/api/*.ts)             |
| Tokens         | 42% utilise - 116k restants           |
| Agents actifs  | backend (depuis 8 min)                |
| claude-mem     | UP sur 37777                          |
```

Utilisation : `/status` pour voir ou on en est sans poser la question.
