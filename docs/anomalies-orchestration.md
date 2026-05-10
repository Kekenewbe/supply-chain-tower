# Anomalies d'orchestration Espace_Opti

Ce document liste les anomalies de comportement runtime decouvertes en orchestrant les agents Claude Code.

## A24-bis : Limitation runtime tool Agent dans subagents

**Description**
Le tool `Agent` (delegation a des sous-agents specialises type `@backend`, `@frontend`, etc.) declare dans le frontmatter d'un subagent (ex: `manager.md`) n'est PAS reellement disponible a l'execution runtime. L'agent ne peut delegate qu'au niveau top-level (session principale Claude Code). En tant que subagent invoque via `@manager`, il est force d'executer manuellement (Read/Write/Edit/Bash) ce qu'il devrait deleguer a `@backend` ou `@frontend`.

**Origine**
Limitation architecturale Claude Code : les subagents tournent en isolation context window, et le tool `Agent` exige une session top-level pour spawner d'autres subagents. Le frontmatter `tools: Agent` est accepte (pas d'erreur de chargement) mais l'invocation reelle echoue silencieusement ou est ignoree.

**Impact pratique**
- Regle 2 CLAUDE.md global ("matching agent-tache") inapplicable quand `@manager` est invoque comme subagent.
- Tous les commits faits par `@manager` dans une session subagent sont en realite manuels (Bash/Edit), violant le principe de delegation specialisee.
- Le rapport de session ne reflete pas la realite : `@manager` annonce "delegue a @backend" mais execute en fait lui-meme.
- Les budgets de tokens par agent (3000 backend, 3000 frontend, etc.) ne sont jamais consommes — tout passe sur le budget de `@manager` (Opus, plus cher).

**Workarounds**
1. **Top-level invocation** : invoquer `@manager` directement depuis la session principale (pas via `@manager` imbrique). C'est le mode prevu.
2. **Accepter l'execution manuelle** : si `@manager` doit etre subagent, accepter qu'il execute manuellement (Bash/Read/Write/Edit) et noter dans le rapport "execution manuelle, delegation runtime indisponible".
3. **Refactor architectural** : redesign futur de `manager.md` pour qu'il soit un "orchestrateur passif" qui produit un plan d'action structure (markdown), que la session principale execute en deleguant aux vrais subagents.

**Priorite**
Moyenne. Pas bloquant tant que `@manager` est invoque top-level. A documenter dans CLAUDE.md projet pour que les futurs prompts respectent cette contrainte.

**Items backlog impactes**
- #41 (partiel) : matrice agent-tache inapplicable en mode subagent
- #48 (resolu A22) : ajout tool Agent dans frontmatter — necessaire mais non suffisant
- Nouveau #50 (futur) : redesign manager.md en mode "plan-and-handoff" pour gerer A24-bis
