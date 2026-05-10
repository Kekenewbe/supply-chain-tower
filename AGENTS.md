# AGENTS.md — Espace_Opti

## Rôle de ce fichier

Standard ouvert (Vercel/Anthropic) — règles toujours-actives pour TOUT agent IA travaillant sur ce repo (Claude Code, Codex CLI, Cursor, Gemini CLI, etc.).

## Pacte stratégique

Espace_Opti = écosystème d'orchestration d'agents IA pour caste/Kekenewbe.
VisualPrompt = bench de test : chaque friction VP nourrit Espace_Opti.
Chaque problème → enregistrer cause racine + solution + item Espace_Opti si applicable.

## Règles non-négociables

1. JAMAIS exposer secrets en clair (DATABASE_URL, SUPABASE_SERVICE_ROLE_KEY, .env content)
2. TOUJOURS utiliser fingerprints (longueur + prefix 5 chars) pour valider env vars sans exposer
3. JAMAIS commit .env, .env.local, ou variants
4. Validation empirique non-négociable : cross-check après chaque action critique (règle 12)
5. Discipline délégation : code applicatif (TSX, PY, SQL) → agent spécialisé OBLIGATOIRE
6. STOP utilisateur entre phases majeures (pas d'enchaînement automatique)
7. Backups .bak_<id> avant modifs structurelles
8. Inbox multi-projets : inbox/current.md + scripts/inbox-*.ps1
9. Doctrine mémoire : Memory/ (5 registres + backlog snapshot)
10. Format entrées Memory/ : voir Memory/SCHEMA.md

## Anomalies majeures connues

- A24-bis CRITICAL : "Agent is not available inside subagents" (limitation runtime Claude Code, workaround = session principale dispatch)
- A25 : @manager peut diverger d'un brief sans signaler — exiger conformité signature dans rapport
- A16 : sed masking insuffisant — utiliser fingerprints, jamais regex sed ad hoc

## Conventions Espace_Opti

- Mémoire stratégique : Memory/ (racine, niveau 1)
- Inbox active : inbox/current.md
- Archives inbox : inbox/archive/<date>-<short-desc>.md
- Hooks : .claude/hooks/*.sh
- Agents Claude Code : .claude/agents/*.md (en attente migration #66 vers SKILL.md)
- Doctrine 5 registres : Memory/decisions|learnings|blockers|journal|evals.md
- Backlog snapshot : Memory/backlog.md (append-only, alimenté par end-session.ps1)

## Pour démarrer une session sur ce repo

1. Lire AGENTS.md (ce fichier)
2. Lire Memory/README.md
3. Lire les 5 dernières entrées de chaque registre (décisions, learnings, blockers, journal, evals)
4. Lire inbox/current.md pour la consigne active
