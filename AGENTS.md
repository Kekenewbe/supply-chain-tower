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

12. **Propagation cross-projet (rôle officiel @architecte = cross-project-synchronizer)** : tout fix structurel commité dans Espace_Opti (origin/main) doit être audité par @architecte pour propagation vers projets dérivés (SCT/VP/SF/futurs). Workflow :
    - Fin marathon ou push origin/main = trigger automatique audit @architecte (rôle cross-project-synchronizer)
    - Sévérité HIGH (sync_memory, end-session.ps1, scripts critiques, hooks runtime) = propagation immédiate (< 24h)
    - Sévérité MEDIUM (templates, audits, helpers UX) = propagation < 7j
    - Sévérité LOW (doc, cosmétique, refactor commentaires) = propagation à l'opportunité
    - Slash `/propagate` = trigger manuel (auto-découverte derniers commits non propagés ou hash explicite)
    - Script `scripts/propagate-fix.ps1` automatise audit + apply (DryRun par défaut, anti-A82)
    - `new-project.ps1` v4 = bootstrap nouveau projet hérite V_actuelle Espace_Opti (champ metadata `doctrine_version` = hash HEAD)
    - Lecture pure 5 projets (Espace_Opti référence + SCT + VP + SF + futurs), produire matrice diff avant apply
    - Garde-fous : backup `.bak_propagate_<date>` avant chaque modif dérivé (règle 6), cross-check post-apply (règle 12)
    - Anti-patterns à éviter : A53 (PowerShell `+=` sur string → array+join), A92 (claim filesystem non cross-checké), A93 (drift silencieux template→dérivé), A101 (>50L script écrit par @architecte au lieu de @backend)
    - Référence : `Memory/_briefs_recovered/s15-phase-a-audit-report.md` (Phase A audit empirique : 1/13 propagé, 8 anomalies)
13. **Back-propagation interne (BPI) — rôle officiel @architecte = internal-sync-synchronizer** : tout commit Espace_Opti touchant code structurel interne (`.claude/skills/*`, `.claude/commands/*`, `.claude/agents/*`, `scripts/*`) doit être audité par @architecte pour synchronisation de la doc interne associée (CLAUDE.md, AGENTS.md, blocs `<...>` agents, journaux Memory/). Workflow :
    - Post-commit code structurel = trigger automatique audit @architecte (rôle internal-sync-synchronizer)
    - Sévérité HIGH (contrat utilisateur cassé : agent role, slash UX, frontmatter skill `purpose`, mots-clés BREAKING/deprecated/removed/renamed dans diff) = doc MAJ < 24h
    - Sévérité MEDIUM (fonctionnalité ajoutée sans casser existant : nouveau Step skill, nouvelle option script) = doc MAJ < 7j
    - Sévérité LOW (refactor interne, renommage variable, commentaire) = doc opportuniste avec auto-apply autorisé (backup obligatoire)
    - Slash `/internal-sync` = trigger manuel (auto-découverte derniers commits structurels non back-propagés ou hash explicite)
    - Script `scripts/internal-sync.ps1` automatise audit + apply (DryRun par défaut, anti-A82) — specs Phase D16.5
    - Hook `.claude/hooks/post-commit-bpi-marker.py` insère automatiquement un marker BPI dans la doc primaire impactée — specs Phase D16.6
    - Format marker BPI enrichi (diff hint inclus) : commentaire HTML `<!-- BPI auto: <hash-short> @ <ISO8601> Source: <path> Category: <skill|command|agent|script> Diff hint: <5-line-snippet> -->` permet à l'opérateur humain de MAJ doc sans relire le diff complet
    - Symétrie totale avec règle 12 (propagation cross-projet) : même garde-fous, même 8 steps, sens INVERSE (doc IN, pas code OUT)
    - Garde-fous : backup `.bak_bpi_<date>` avant chaque modif doc (règle 6), cross-check post-apply (règle 12), DryRun strict, validation utilisateur HIGH/MEDIUM
    - Anti-patterns à éviter : A31 (encoding Windows), A53 (PowerShell `+=`), A82 (apply sans audit), A92 (claim sans Read post-edit), A101 (>50L script écrit par @architecte au lieu de @backend), A93-bis (drift silencieux code→doc interne, équivalent A93 mais intra-repo)
    - Référence : `.claude/skills/internal-sync.md`, `.claude/commands/internal-sync.md`, bloc `<internal_propagation>` dans `.claude/agents/architecte.md`, audit Phase D16.1 `Memory/_briefs_recovered/s16-phase-d16-design.md`
14. **Doctrine redistribution agents — rôle officiel @manager = agent-redistribution-coordinator** : @manager DOIT vérifier périodiquement (slash `/agent-audit` ou auto fin de session) la répartition empirique des invocations agents via `.claude/agent-log.txt` (post-fix A102 = `agent_type` capturé par hooks `log-subagent-start.ps1` / `log-subagent-stop.ps1`). Si un agent spécialisé est sous-utilisé (< 5 invocations cumulées sur 7 jours) alors qu'un domaine correspondant a été traité manuellement, @manager applique la doctrine de redistribution :
    - 14.a Décomposition + estimations préalables tâche > 15 min ou > 5 fichiers → **@estimateur** (Haiku, coût minimal). Empirie S13-S16 : 0 invocation cumulée.
    - 14.b Cross-check empirique post-délégation (claims filesystem/git/tests/build) → **@optimiseur** (Sonnet, mémoire 2778B). Spécialisation = audit + reformulation prompt + validation chiffrée.
    - 14.c Audit matrice cross-projet ou tableau multi-axes (xlsx) → **@qa-review** (Opus + skill xlsx, scoring 4 axes pondérés, bloque sous 80).
    - 14.d Refactor post-implementation → **@simplifier** (Sonnet) UNIQUEMENT après @qa-review score ≥ 80. Invariant : tests verts avant ET après, rollback immédiat si rouge.
    - 14.e Tests E2E navigateur (planning, génération, healing) → trio **@playwright-test-planner** / **@playwright-test-generator** / **@playwright-test-healer**. Distinct de @playwright (livraison finale PRD-driven SOP-004).
    - 14.f Scripts PowerShell ou Python structurels > 50 lignes → délégation **@backend** obligatoire (anti-A24-bis : @architecte conçoit, @backend implémente).
    - Slash `/agent-audit [days]` (default 7j) = trigger manuel : parse `.claude/agent-log.txt`, produit matrice stats par agent, suggère redistribution selon 14.a-f.
    - Script `scripts/agent-audit.ps1` = LECTURE PURE seule (pas d'écriture disque, anti-A82 N/A par construction).
    - Symétrie totale avec règles 12 (cross-projet) + 13 (BPI) : skill + slash + script + bloc agent + règle. Sens nouveau : **INTRA-session** (équilibrage charge agents).
    - Garde-fous : ASCII pur (anti-A31), PowerShell array+join (anti-A53), **anti-A105 critique** (jamais variable locale = nom paramètre — coercion silencieuse array→string PowerShell case-insensitive, vue S16-D16 bug DOC_NOT_FOUND).
    - Anti-pattern bloquant : @manager traite manuellement (Bash/Read/Write) ce qu'un agent spécialisé ferait mieux ET ne justifie pas par chiffres mesurables = violation règle 2 CLAUDE.md global + règle 14.
    - Référence : `.claude/skills/agent-redistribution.md`, `.claude/commands/agent-audit.md`, `scripts/agent-audit.ps1`, bloc `<delegation_doctrine>` dans `.claude/agents/manager.md`, audit Phase 0.5 S17 (agent-log 462L, 0 nom agent pré-A102, A102 RESOLVED empirique 2026-05-15).