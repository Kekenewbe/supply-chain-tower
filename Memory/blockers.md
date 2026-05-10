# Blockers — Espace_Opti

> Voir Memory/SCHEMA.md pour le format des entrées.
> Voir Memory/README.md pour la doctrine globale.

## Index par scope

- **transverse** : (entrées non liées à un projet spécifique)
- **espace_opti** : (entrées sur l'écosystème lui-même)
- **vp** : (visualprompt)
- **socialflow** : (dormant)
- **supply_chain_tower** : (futur, deadline 25 mai 2026)

---

## Entrées

## 2026-04-23 — A1 — Fix worktree isolation #16 partiellement effectif

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #worktree #recurrence-1
- **Première occurrence** : 2026-04-23
- **Récurrences** : 1
- **Symptôme** : Fix #16 worktree isolation gravé mais agents écrivent parfois dans main au lieu du worktree assigné
- **Cause racine** : HEAD pinned au session-start, agents bypass isolation
- **Mitigation actuelle** : Surveillance manuelle git status
- **Mitigation cible** : Item #16 enrichi (révision logique fix worktree)
- **Coût cumulé** : ~30 min cumulés
- **Statut** : OPEN

## 2026-04-23 — A2 — Worktrees agent-* lockés non nettoyés

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #worktree
- **Première occurrence** : 2026-04-23
- **Récurrences** : 1
- **Symptôme** : 11+ worktrees agent-* lockés par harness Claude Code, restent après fin de session
- **Cause racine** : Cleanup non automatique en fin de session
- **Mitigation actuelle** : git worktree remove --force --force manuel
- **Mitigation cible** : git wt-clean étendu (item #55)
- **Coût cumulé** : ~15 min cumulés (cleanup ponctuel)
- **Statut** : MITIGATED

## 2026-04-23 — A2-bis — git wt-clean ne nettoie PAS les worktrees lockés

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #git #worktree
- **Première occurrence** : 2026-04-30
- **Récurrences** : 1
- **Symptôme** : Pour locks orphelins (PIDs morts), wt-clean retourne 0 nettoyé
- **Cause racine** : remove --force ≠ remove --force --force pour locks orphelins
- **Mitigation actuelle** : Boucle bash for wt in ...; do remove --force --force
- **Mitigation cible** : Item #55 (étendre alias wt-clean)
- **Coût cumulé** : ~10 min
- **Statut** : MITIGATED

## 2026-04-23 — A3 — Warnings Auto-update + /doctor settings persistants Claude Code

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #cosmétique
- **Première occurrence** : 2026-04-23
- **Récurrences** : ongoing
- **Symptôme** : Warnings Auto-update et /doctor settings persistants en bas de Claude Code session
- **Cause racine** : cleanup-claude-old-binaries.ps1 non exécuté
- **Mitigation actuelle** : Aucune (signal ignoré)
- **Mitigation cible** : Automatiser cleanup ou graver
- **Coût cumulé** : 0 min (cosmétique)
- **Statut** : OPEN

## 2026-04-25 — A4 — PostCSS config absente Phase 3 livrée (preuve par absurde #23)

- **Scope** : vp
- **Tags** : #blocker #vp #livraison
- **Première occurrence** : 2026-04-25
- **Récurrences** : 1
- **Symptôme** : Phase 3 VP "livrée" 14 commits / 18521 lignes mais postcss.config.js absent → CSS Tailwind non appliqué (W14)
- **Cause racine** : Aucun gate validation flagué
- **Mitigation actuelle** : Fix W14 commit e04ab3f
- **Mitigation cible** : Checklist #23 critère 2 (CSS s'applique)
- **Coût cumulé** : ~20 min
- **Statut** : RESOLVED (W14)

## 2026-04-30 — A5 — Backend FastAPI auth bypass partiel (preuve par absurde #23 critère 4)

- **Scope** : vp
- **Tags** : #blocker #vp #auth #architecture
- **Première occurrence** : 2026-04-23
- **Récurrences** : 1
- **Symptôme** : Commit 9485d68 fait moitié frontend, backend resté intact → 401 silencieux 2 sessions
- **Cause racine** : Architecture mismatch front/back, pas de test E2E réel
- **Mitigation actuelle** : Fix W15 bidirectionnel
- **Mitigation cible** : Checklist #23 critère 4 (scénario bout-en-bout)
- **Coût cumulé** : ~2h debug
- **Statut** : RESOLVED (W15)

## 2026-04-23 — A6 — Encoding UTF-8 wrapper PowerShell

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #encoding #cosmétique
- **Première occurrence** : 2026-04-23
- **Récurrences** : ongoing
- **Symptôme** : Output transcript bash montre Mémoire au lieu de Mémoire
- **Cause racine** : Caractères français mal interprétés dans wrapper scripts
- **Mitigation actuelle** : Aucune
- **Mitigation cible** : Item #26 (fix encoding)
- **Coût cumulé** : 0 min (cosmétique)
- **Statut** : OPEN

## 2026-04-23 — A7 — sync_memory.py warnings Pydantic V1 + HF Token

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #python #deps
- **Première occurrence** : 2026-04-23
- **Récurrences** : ongoing
- **Symptôme** : UserWarning Pydantic V1 incompatible Python 3.14, HF Token absent
- **Cause racine** : Deps obsolètes
- **Mitigation actuelle** : Aucune (non bloquant)
- **Mitigation cible** : MAJ deps Pydantic + ajout HF_TOKEN env
- **Coût cumulé** : 0 min
- **Statut** : OPEN

## 2026-04-23 — A8 — Friction copy-paste prompt → inbox.md (RÉCURRENT)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #recurrence-5
- **Première occurrence** : 2026-04-23
- **Récurrences** : 5+ (2026-04-23, 04-25, 04-30 ×2, 05-01, 05-03)
- **Symptôme** : Utilisateur croit avoir collé dans inbox, fichier vide ou pas sauvé
- **Cause racine** : Pas de Ctrl+S, mauvais fichier, ou habitude legacy path
- **Mitigation actuelle** : Procédure 12 étapes documentée par Claude.ai
- **Mitigation cible** : Items #38, #95 (helper set-inbox.ps1, prep-prompt.ps1 wrapper)
- **Coût cumulé** : ~45 min cumulés (cycles perdus)
- **Statut** : OPEN (récurrence 5+ → priorité)

## 2026-04-30 — A9 — inbox.md annonce état que la réalité contredit

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #cross-check
- **Première occurrence** : 2026-04-30
- **Récurrences** : 2
- **Symptôme** : Utilisateur écrit "j'ai fait X" dans inbox, X non fait empiriquement
- **Cause racine** : Pas de cross-check systématique des annonces utilisateur
- **Mitigation actuelle** : Claude.ai cross-check via curl/git status après chaque annonce
- **Mitigation cible** : Item #37 (pré-validation annonces)
- **Coût cumulé** : ~20 min
- **Statut** : MITIGATED

## 2026-04-25 — A10 — 2 Notepad ouverts → confusion fichier édité

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #ux #cosmétique
- **Première occurrence** : 2026-04-25
- **Récurrences** : 2
- **Symptôme** : Utilisateur a 2 Notepad (credentials + .env), édite l'un en pensant éditer l'autre
- **Cause racine** : Pas de feedback visuel évident sur fichier en cours
- **Mitigation actuelle** : Vérifier title bar Notepad
- **Mitigation cible** : Item #38 (helper set-env-var.ps1)
- **Coût cumulé** : ~15 min
- **Statut** : OPEN

## 2026-04-23 — A11 — Phase 0 Claude Code n'existait pas dans règles initiales

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #phase-0 #standardisation
- **Première occurrence** : 2026-04-23
- **Récurrences** : 1
- **Symptôme** : Pattern Phase 0 inventé ad hoc, pas standard
- **Cause racine** : CLAUDE.md / manager.md n'avaient pas Phase 0 codifiée
- **Mitigation actuelle** : Phase 0 maintenant systématique dans tous prompts
- **Mitigation cible** : Hook session-start-phase0.sh créé Phase 1 Espace_Opti
- **Coût cumulé** : ~30 min
- **Statut** : RESOLVED

## 2026-04-30 — A12 — Stratégie Y inventée pendant la session sans framework

- **Scope** : vp
- **Tags** : #blocker #vp #pattern #ad-hoc
- **Première occurrence** : 2026-04-23
- **Récurrences** : 1
- **Symptôme** : Mode solo "stratégie Y" inventée ad hoc (drop FK, RLS off, mock user)
- **Cause racine** : Pas de framework pour patterns mode solo
- **Mitigation actuelle** : Pattern documenté dans learnings (β-2)
- **Mitigation cible** : Item #29 (pattern auth bypass solo templatisable)
- **Coût cumulé** : ~30 min
- **Statut** : MITIGATED

## 2026-04-30 — A13 — Diagnostic loader infini → 5 hypothèses ad hoc

- **Scope** : vp
- **Tags** : #blocker #vp #diagnostic #ad-hoc
- **Première occurrence** : 2026-04-30
- **Récurrences** : 1
- **Symptôme** : Quand "Chargement..." persistait, @manager a inventé 5 hypothèses (A-E) ad hoc
- **Cause racine** : Pas de template diagnostic loader infini
- **Mitigation actuelle** : Hypothèses ont marché empiriquement
- **Mitigation cible** : Item #30 (template diagnostic UI bug)
- **Coût cumulé** : ~20 min
- **Statut** : OPEN

## 2026-04-30 — A14 — Pas de mécanisme intégrité fichiers @manager → utilisateur

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #intégrité
- **Première occurrence** : 2026-04-30
- **Récurrences** : 1
- **Symptôme** : Quand @manager génère 0099_solo_local_setup.sql, utilisateur ne peut vérifier intégrité avant exécution Supabase
- **Cause racine** : Pas de hash/taille/preview standardisé
- **Mitigation actuelle** : Confiance manuelle
- **Mitigation cible** : Sous-pattern #23 critère "intégrité artefacts"
- **Coût cumulé** : ~10 min
- **Statut** : OPEN

## 2026-04-30 — A15 — Backlog conversationnel vs backlog fichier (CRITIQUE)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #memoire #critique
- **Première occurrence** : 2026-04-30
- **Récurrences** : 3 (chaque nouvelle session conv Claude.ai)
- **Symptôme** : Backlog vit en mémoire conv Claude.ai, perte si dépassement contexte
- **Cause racine** : Pas de fichier physique persistant
- **Mitigation actuelle** : Doctrine 5 registres + backlog snapshot fichier (Phase α/β en cours)
- **Mitigation cible** : Item #61 (doctrine 5 registres) + #62 (end-session.ps1)
- **Coût cumulé** : ~3h re-construction contexte
- **Statut** : MITIGATED (en cours)

## 2026-05-01 — A16 — Pattern sed masking insuffisant (fuite password DATABASE_URL)

- **Scope** : transverse
- **Tags** : #blocker #transverse #sécurité #critique
- **Première occurrence** : 2026-04-30
- **Récurrences** : 1 (bonne discipline depuis)
- **Symptôme** : sed regex masque host mais pas password dans output @manager → fuite DATABASE_URL plain text dans transcript
- **Cause racine** : Regex ad hoc dans prompt, pas helper standardisé
- **Mitigation actuelle** : Section "Sécurité output" obligatoire dans tous prompts inbox depuis
- **Mitigation cible** : Item #40 (helper mask-env-safe.sh standardisé)
- **Coût cumulé** : ~10 min + dette sécurité W19 (rotate password)
- **Statut** : MITIGATED (procédural, pas structurel)

## 2026-05-01 — A17 — inbox.md historique manquait section "Sécurité output"

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #template
- **Première occurrence** : 2026-05-01
- **Récurrences** : 1
- **Symptôme** : Briefs sans contrainte explicite masking → A16
- **Cause racine** : Template inbox.md non standardisé
- **Mitigation actuelle** : Section "Sécurité output" dans tous prompts depuis
- **Mitigation cible** : Item #41 (template inbox section sécurité obligatoire)
- **Coût cumulé** : 0 min
- **Statut** : MITIGATED

## 2026-05-01 — A18 — Agents spécialisés deviennent coquilles vides si non sollicités

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #delegation
- **Première occurrence** : 2026-05-01
- **Récurrences** : 2
- **Symptôme** : @manager exécute code TSX/Python directement, agents @frontend/@backend pas invoqués
- **Cause racine** : Pas de règle obligatoire délégation
- **Mitigation actuelle** : Règle 13 manager.md (gravée)
- **Mitigation cible** : Item #41 (règle complète justification écrite obligatoire)
- **Coût cumulé** : ~20 min (drift partiel)
- **Statut** : MITIGATED

## 2026-05-01 — A19 — Drift session @manager auto-affectation croissante

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #drift
- **Première occurrence** : 2026-05-01
- **Récurrences** : 2
- **Symptôme** : @manager s'auto-affecte de plus en plus de tâches au fil session
- **Cause racine** : Pas de métrique ratio délégation
- **Mitigation actuelle** : Surveillance manuelle Claude.ai (cross-check)
- **Mitigation cible** : Items #42, #43 (métrique + auto-detect drift)
- **Coût cumulé** : variable
- **Statut** : OPEN

## 2026-04-30 — A20 — Lint eslint package non installé Phase 0

- **Scope** : vp
- **Tags** : #blocker #vp #deps
- **Première occurrence** : 2026-04-30
- **Récurrences** : 1
- **Symptôme** : npm run lint échoue (eslint binary absent)
- **Cause racine** : Phase 0 ne checke pas tools de validation
- **Mitigation actuelle** : Aucune (W20 ouvert)
- **Mitigation cible** : Item #44 (pre-flight check tools validation)
- **Coût cumulé** : ~5 min
- **Statut** : OPEN (W20)

## 2026-04-30 — A21 — @manager cd mauvais dossier entre tool calls bash

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #cwd
- **Première occurrence** : 2026-04-30
- **Récurrences** : 1
- **Symptôme** : Erreurs paths relatifs entre tool calls successifs
- **Cause racine** : Pas de cleanup auto cwd
- **Mitigation actuelle** : Vérifier pwd avant commands critiques
- **Mitigation cible** : Item #45 (cleanup auto cwd)
- **Coût cumulé** : ~5 min
- **Statut** : OPEN

## 2026-05-02 — A22 — manager.md tool Agent listé mais non invocable depuis subagent

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #subagent #critique
- **Première occurrence** : 2026-05-02
- **Récurrences** : ongoing
- **Symptôme** : @manager peut LISTER tool Agent (frontmatter) mais pas l'INVOQUER depuis dispatch
- **Cause racine** : Limitation runtime Claude Code (pas résoluble Espace_Opti)
- **Mitigation actuelle** : Workaround : session principale dispatch directement
- **Mitigation cible** : Item #51 (redesign manager mode plan-and-handoff)
- **Coût cumulé** : variable
- **Statut** : OPEN (limitation runtime)

## 2026-05-01 — A23 — Friction copy-paste inbox récurrente (= A8 enrichi)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #recurrence
- **Note** : Doublon de A8 — voir A8 pour entrée canonique. A23 marqué comme occurrence répétée.
- **Statut** : MERGED INTO A8

## 2026-05-01 — A24 — Même commande @manager produit comportements différents

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #determinisme
- **Première occurrence** : 2026-05-01
- **Récurrences** : 3
- **Symptôme** : "@manager lis inbox.md" produit résultats différents selon contenu inbox
- **Cause racine** : Hook SessionStart cache + dual-system (A37)
- **Mitigation actuelle** : Fix γ-pre-2 (Strats 1+3+4)
- **Mitigation cible** : Validé β-3 phase 0 (Strats 1+3+4)
- **Coût cumulé** : ~30 min
- **Statut** : MITIGATED (fix γ-pre-2)

## 2026-05-02 — A24-bis — Agent is not available inside subagents (CRITIQUE)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #subagent #critique #limitation
- **Première occurrence** : 2026-05-02
- **Récurrences** : ongoing
- **Symptôme** : Limitation runtime Claude Code, non résoluble Espace_Opti
- **Cause racine** : Architecture Claude Code (subagent ne peut pas spawn d'autres subagents)
- **Mitigation actuelle** : Workaround : session principale dispatch
- **Mitigation cible** : Item #51 (redesign mode plan-and-handoff)
- **Coût cumulé** : variable
- **Statut** : OPEN (limitation upstream)

## 2026-05-02 — A25 — @manager peut diverger d'un brief sans signaler

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #drift #critique
- **Première occurrence** : 2026-05-02
- **Récurrences** : 2
- **Symptôme** : Tests fonctionnels passent mais ne valident pas conformité signature brief
- **Cause racine** : @qa-review ne checke pas signature vs spec
- **Mitigation actuelle** : Cross-check Claude.ai règle 12 + discipline @manager Phase β/γ
- **Mitigation cible** : Item #54 (étendre @qa-review)
- **Coût cumulé** : variable
- **Statut** : MITIGATED (procédural)

## 2026-05-03 — A26 — agent-log.txt toujours en modified

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #git #cosmétique
- **Première occurrence** : 2026-05-03
- **Récurrences** : ongoing
- **Symptôme** : agent-log.txt M dans tous git status
- **Cause racine** : Side-effect hook claude-mem
- **Mitigation actuelle** : Toléré dans git status
- **Mitigation cible** : Item #50 (gitignore vs commit explicite)
- **Coût cumulé** : 0 min (cosmétique)
- **Statut** : OPEN

## 2026-05-03 — A27 — Drift scope silencieux : @manager inclut C8 hors brief

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #scope-creep
- **Première occurrence** : 2026-05-03
- **Récurrences** : 1
- **Symptôme** : @manager a inclus C8 (migration inbox) dans ITEM 4 sans demande utilisateur
- **Cause racine** : Pas de check signature scope strict
- **Mitigation actuelle** : Cross-check Claude.ai
- **Mitigation cible** : Item #54 (étendre @qa-review check signature)
- **Coût cumulé** : ~10 min (analyse rétroactive)
- **Statut** : MITIGATED

## 2026-05-03 — A28 — Format custom vs standard SKILL.md (fragmentation)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #standard
- **Première occurrence** : 2026-05-03
- **Récurrences** : 1
- **Symptôme** : .claude/agents/*.md format custom alors que SKILL.md standard ouvert (60K+ stars)
- **Cause racine** : Espace_Opti développé avant émergence standard
- **Mitigation actuelle** : Décision pivoter (β-1 entrée 2026-05-04)
- **Mitigation cible** : Items #59, #66 (adopter SKILL.md, pivoter custom)
- **Coût cumulé** : 0 min (pas encore migré)
- **Statut** : OPEN

## 2026-05-03 — A29 — Claude.ai biais : préfère outils plutôt que méta-process

- **Scope** : transverse
- **Tags** : #blocker #transverse #meta-claude
- **Première occurrence** : 2026-05-03
- **Récurrences** : 1
- **Symptôme** : Première analyse post Instagram = liste outils techniques au lieu message stratégique
- **Cause racine** : Biais analytique Claude.ai
- **Mitigation actuelle** : Discipline méta-cognition utilisateur
- **Mitigation cible** : Auto-discipline Claude.ai
- **Coût cumulé** : ~15 min (recadrage)
- **Statut** : OPEN

## 2026-05-03 — A30 — Tentation "38k stars = mature" alors que issues empiriques contredisent

- **Scope** : transverse
- **Tags** : #blocker #transverse #methodologie
- **Première occurrence** : 2026-05-03
- **Récurrences** : 1
- **Symptôme** : Ruflo signale social fort mais issues #126/#640/#430 confirment dysfonctionnements
- **Cause racine** : Pas de méthodologie d'évaluation empirique avant import
- **Mitigation actuelle** : Audit issues GitHub avant import structurel
- **Mitigation cible** : Procédure standard évaluation outils (à graver)
- **Coût cumulé** : 0 min (heureusement Ruflo non importé)
- **Statut** : MITIGATED (méthodologique)

## 2026-05-03 — A31 — Hook SessionStart cache + discipline persisted (CRITIQUE)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #hook #critique
- **Première occurrence** : 2026-05-03
- **Récurrences** : 2 (Phase α improvisation + risque récurrent)
- **Symptôme** : @manager agit sur preview 2KB sans Read persisted file → improvisation
- **Cause racine** : Pas de discipline gravée + dual-system A37
- **Mitigation actuelle** : Fix γ-pre-2 (Strats 1+3+4 belt-and-suspenders)
- **Mitigation cible** : Validé β-3 phase 0 (T3+T4)
- **Coût cumulé** : ~1h Phase α improvisation
- **Statut** : MITIGATED (fix γ-pre-2)

## 2026-05-03 — A32 — Hook post-commit warning null byte

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #git #cosmétique
- **Première occurrence** : 2026-05-03
- **Récurrences** : ongoing
- **Symptôme** : "warning: command substitution: ignored null byte in input" ligne 14 graphify hook
- **Cause racine** : Hook bash mal escapé
- **Mitigation actuelle** : Toléré (non bloquant)
- **Mitigation cible** : Item #84 (investiguer null byte)
- **Coût cumulé** : 0 min
- **Statut** : OPEN

## 2026-05-04 — A33 — sync_memory.py vise mauvais vault Obsidian

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #sync #obsidian
- **Première occurrence** : 2026-05-04
- **Récurrences** : 1
- **Symptôme** : Script pointe Documents\Obsidian Vault, doctrine 5 registres dans Espace_Opti\Memory\
- **Cause racine** : Désynchro outil sync vs fondation mémoire
- **Mitigation actuelle** : Décision différée (Q-Sync non répondu)
- **Mitigation cible** : Items #85, #86 (décider stratégie vault)
- **Coût cumulé** : 0 min (non urgent)
- **Statut** : OPEN

## 2026-05-04 — A34 — Première interaction nouveau dossier déclenche prompt autorisation

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #permissions #cosmétique
- **Première occurrence** : 2026-05-04
- **Récurrences** : 1
- **Symptôme** : Claude Code demande autorisation chaque nouveau dossier (Memory/)
- **Cause racine** : Settings permissions par défaut
- **Mitigation actuelle** : Option "Yes, always allow" sélectionnée
- **Mitigation cible** : Item #87 (Phase 0 inclut pré-autorisation dossiers cibles)
- **Coût cumulé** : <1 min
- **Statut** : MITIGATED

## 2026-05-04 — A35 — Critères wc -l fragiles dans briefs

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #brief #methodologie
- **Première occurrence** : 2026-05-04
- **Récurrences** : 1
- **Symptôme** : Critère wc -l > 90 fail numérique alors que structure OK (β-2)
- **Cause racine** : Surestimation taille seuil dans brief
- **Mitigation actuelle** : Préférer grep -c structurel
- **Mitigation cible** : Item #88 (templates briefs grep structurel only)
- **Coût cumulé** : 0 min (faux positif détecté)
- **Statut** : MITIGATED

## 2026-05-04 — A36 — Audit avant action sur le hook lui-même (méta-positive)

- **Scope** : espace_opti
- **Tags** : #blocker-meta #espace_opti #methodologie
- **Première occurrence** : 2026-05-04
- **Récurrences** : 1
- **Symptôme** : Discipline auto-imposée respectée (audit γ-pre-1 avant fix γ-pre-2)
- **Cause racine** : N/A (entrée méta-positive)
- **Mitigation actuelle** : Pattern à reproduire
- **Mitigation cible** : N/A
- **Coût cumulé** : 0 min (gain net)
- **Statut** : POSITIVE (gravé comme exemple)

## 2026-05-04 — A37 — Dual-system inbox (CRITIQUE)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #critique
- **Première occurrence** : ~2026-04-30 (commit c1e7a5a)
- **Récurrences** : ongoing avant fix
- **Symptôme** : Hooks lisent inbox.md racine, scripts PS1 écrivent inbox/current.md → silent fail
- **Cause racine** : Migration partielle inbox multi-projets
- **Mitigation actuelle** : Fix γ-pre-2 Strat 4 (paths alignés)
- **Mitigation cible** : Validé β-3 phase 0 (T2 PASS γ-pre-3 confirme alignement)
- **Coût cumulé** : ~30 min (sessions perdues silent fail)
- **Statut** : RESOLVED (fix γ-pre-2)

## 2026-05-04 — A38 — Stop hook faux positif sur "à faire"

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #hook #cosmétique
- **Première occurrence** : 2026-05-04
- **Récurrences** : 1
- **Symptôme** : Stop hook trigger sur "à faire" dans rapport @manager
- **Cause racine** : Pattern matching trop large
- **Mitigation actuelle** : Toléré (non bloquant)
- **Mitigation cible** : Item #52 (affiner stop hook)
- **Coût cumulé** : 0 min
- **Statut** : OPEN

## 2026-05-04 — A39 — Habitude utilisateur ancien path inbox.md

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #habitude
- **Première occurrence** : 2026-05-04
- **Récurrences** : 3 (γ-pre-3 + sessions précédentes)
- **Symptôme** : Utilisateur colle dans inbox.md racine au lieu de inbox/current.md
- **Cause racine** : Habitude legacy + pas de signal visuel pour différencier
- **Mitigation actuelle** : Phase 0.2 β-3 renomme inbox.md → inbox.md.LEGACY-DO-NOT-USE
- **Mitigation cible** : Item #94 (renommage déjà appliqué β-3) + #95 (script wrapper prep-prompt.ps1)
- **Coût cumulé** : ~10 min (1 cycle γ-pre-3 partiellement perdu)
- **Statut** : MITIGATED (β-3)

## 2026-05-05 — A40 — Hook inbox_inject vide current.md (couplage lecture/vidage)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #hook #inbox #recurrence-1
- **Première occurrence** : 2026-05-05
- **Récurrences** : 1
- **Symptôme** : Hook SessionStart inbox_inject lit ET vide current.md dans la même opération → brief perdu après 1ʳᵉ injection, sessions suivantes orphelines
- **Cause racine** : Couplage lecture/vidage dans inbox_inject. Pas de marker idempotent pour éviter ré-injection.
- **Sévérité initiale** : HIGH (perte brief utilisateur). Sévérité revue post-fix : MEDIUM (briefs récupérables via cache hook + Memory/_briefs_recovered/).
- **Mitigation actuelle** : Refactor inbox_inject + inbox-archive (commit 8f32766) — découplage lecture/vidage + marker hash SHA256 (.claude/inbox_injected_hash) pour skip silencieux ré-injection. Vidage déplacé vers inbox-archive.ps1 (1 fois par cycle).
- **Mitigation cible** : Validée par tests E2E 8/8 PASS (cf EVAL 2026-05-05).
- **Coût cumulé** : ~2h (diagnostic + briefs perdus à reconstruire dans Memory/_briefs_recovered/)
- **Statut** : RESOLVED
- **Resolution** :
  - Date : 2026-05-05
  - Commit : 8f32766 fix(hooks): A40 resolved - inbox_inject decouple lecture/vidage current.md
  - Solution : décorrélation des responsabilités — hook lit seulement (avec marker hash), inbox-archive vide après archivage validé
  - Tests E2E : 8/8 critères PASS
    - sizeBefore = sizeAfter sur hook (current.md préservé)
    - Marker hash SHA256 créé (.claude/inbox_injected_hash)
    - Skip silencieux 2ᵉ injection (hash identique)
    - Hook ne vide PAS current.md (64 → 64 bytes)
    - Archive contient brief intact (64 bytes)
    - current.md vide post-archive (0 bytes)
    - Marker hash supprimé post-archive
    - Double-archive refusée (warning + exit 1)
- **Liens** : [[EVAL-2026-05-05-A40]] [[8f32766]]

## 2026-05-05 — A41 — @manager TodoList confusion contexte projet vs brief inbox

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #manager #cosmetique #severity-low #recurrence-3
- **Première occurrence** : 2026-05-05
- **Récurrences** : 3 (sessions 2 et 3 : A40 fix + S1.4-bis + S1.4-quater, observe sur 2 jours)
- **Symptôme observé** : @manager liste TodoList interne avec contexte projet hors scope brief, parfois melange items projet et items brief inbox. Confusion lecture rapport, pas d impact runtime.
- **Cause racine** : @manager melange contexte projet persistant et contexte brief inbox courant lors de la generation TodoList interne.
- **Mitigation actuelle** : aucun (cosmetique)
- **Mitigation cible** : n/a
- **Coût cumulé** : 0 min (cosmetique)
- **Statut** : OPEN

## 2026-05-06 — A42 — Desync instructions projet Claude.ai vs Memory/SCHEMA.md format IDs

- **Scope** : transverse
- **Tags** : #blocker #transverse #doctrine #anti-A30 #severity-medium #recurrence-1
- **Première occurrence** : 2026-05-06
- **Récurrences** : 1
- **Symptôme observé** : instructions projet Claude.ai annoncent format IDs registres BDR-XXX/EVAL-XXX/BLK-XXX/LRN-XXX numerotes, mais Memory/SCHEMA.md utilise format date-based sans prefixe numerote. Trigger : brief S1.4-bis utilisateur mentionnait BDR-008/EVAL-XXX, @manager a corrige en privilegiant SCHEMA.md (anti-A30).
- **Cause racine** : drift documentation, instructions projet jamais alignees sur SCHEMA.md depuis adoption doctrine 5 registres.
- **Mitigation actuelle** : instructions projet corrigees session 3 (debut de session) + cette gravure.
- **Mitigation cible** : n/a
- **Coût cumulé** : risque A30 recurrent a chaque nouveau brief mentionnant un ID, charge cognitive @manager pour reconcilier.
- **Statut** : MITIGATED 2026-05-06

## 2026-05-06 — A47 — SCHEMA.md ne prévoit pas de champ Severité (fusion en tags)

- **Scope** : transverse
- **Tags** : #blocker #transverse #doctrine #schema-evolution #severity-low
- **Première occurrence** : 2026-05-06
- **Récurrences** : 1
- **Symptôme observé** : SCHEMA.md ne prévoit pas de champ Severité, fusion en tags adoptée S1.4-quinquies.
- **Cause racine** : Évolution doctrine vers tags `#severity-*` non répercutée dans SCHEMA.md (champ Severité dédié absent du schéma).
- **Mitigation actuelle** : Fusion sévérité dans tags `#severity-low|medium|high|critical` adoptée S1.4-quinquies.
- **Mitigation cible** : Mettre à jour SCHEMA.md pour formaliser la convention tag-based severity ou ajouter champ optionnel.
- **Coût cumulé** : n/a
- **Statut** : OPEN
- **Liens** : [[S1.4-quinquies]] [[A30]]

## 2026-05-06 — A48 — Template eval.md prévoit champs n/a sur validation positive

- **Scope** : transverse
- **Tags** : #blocker #transverse #doctrine #eval-template #severity-low
- **Première occurrence** : 2026-05-06
- **Récurrences** : 1
- **Symptôme observé** : Template eval.md prévoit `Correction appliquée` + `Mitigation future`, n/a quand validation positive (rien à corriger).
- **Cause racine** : Template eval.md conçu pour cas correctif, pas adapté aux évaluations purement positives où aucune correction n'est requise.
- **Mitigation actuelle** : Champs remplis avec "n/a" lors d'évaluations positives (workaround documentaire).
- **Mitigation cible** : Réviser template eval.md pour rendre `Correction appliquée` / `Mitigation future` optionnels ou conditionnels.
- **Coût cumulé** : n/a
- **Statut** : OPEN
- **Liens** : [[S1.4-quinquies]] [[EVAL-2026-05-06-manager]]

## 2026-05-07 — A49 — Collision phases historiques avril vs phases doctrine actuelles

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #naming #doctrine-vs-historique #severity-low
- **Première occurrence** : 2026-05-07
- **Récurrences** : 1
- **Symptôme observé** : Phases historiques avril (alpha/beta/gamma/delta/epsilon = sprints 12-15/04) collision avec phases doctrine actuelles (α/β/γ/δ/ε = doctrine mai 2026).
- **Cause racine** : Réutilisation des lettres grecques pour deux référentiels temporels distincts, sans namespace ni préfixe distinguant.
- **Mitigation actuelle** : Préfixe `phase-alpha/beta/etc.` utilisé sur 7 briefs S1.4 plain pour désambiguer les phases avril.
- **Mitigation cible** : Convention naming explicite (ex : `2026-04-alpha` vs `δ-mai-2026`) ou abandon des lettres grecques pour la doctrine.
- **Coût cumulé** : n/a
- **Statut** : OPEN
- **Liens** : [[S1.4-plain]]

## 2026-05-07 — A50 — Commit chore(briefs) annonce 14 fichiers, stat réel 16

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #commit-message #cosmetique #severity-low
- **Première occurrence** : 2026-05-07
- **Récurrences** : 1
- **Symptôme observé** : Message commit `chore(briefs)` annonce 14 fichiers, stat réel = 16 (extraction-memory + S1.4-bis-gravure-doctrine non listés).
- **Cause racine** : Comptage manuel imprécis lors de la rédaction du message commit, deux fichiers oubliés dans l'énumération.
- **Mitigation actuelle** : Aucune (cosmétique, commit déjà poussé).
- **Mitigation cible** : Pour futurs commits batch, utiliser `git diff --cached --name-only | wc -l` avant rédaction message.
- **Coût cumulé** : n/a
- **Statut** : OPEN
- **Liens** : [[25bc436]]

## 2026-05-07 — A51 — Désync email .gitconfig vs CLAUDE.md global

- **Scope** : transverse
- **Tags** : #blocker #transverse #git-config #to-arbitrate
- **Première occurrence** : 2026-05-07
- **Récurrences** : 1
- **Symptôme observé** : Email `.gitconfig user` = `castelkevin7@gmail.com`, mention `CLAUDE.md` global = `castelkevincours@gmail.com`. Deux identités email coexistent.
- **Cause racine** : à investiguer — possiblement un email de travail vs personnel jamais aligné, ou drift documentation.
- **Mitigation actuelle** : aucune (les deux coexistent).
- **Mitigation cible** : Décider lequel est canonique, aligner l'autre (action utilisateur requise).
- **Coût cumulé** : n/a
- **Statut** : ARBITRAGE_REQUIS

## 2026-05-08 — A52 — extraction-memory-2026-05-06.txt hors convention nommage

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #cleanup #severity-low
- **Première occurrence** : 2026-05-08
- **Récurrences** : 1
- **Symptôme observé** : Fichier `extraction-memory-2026-05-06.txt` (56KB) hors convention nommage `_briefs_recovered/` (extension `.md` attendue, pas `.txt`).
- **Cause racine** : Hypothèse — export brut Memory/ session 3 devenu reliquat, pas archivé selon convention.
- **Mitigation actuelle** : aucune (fichier laissé en place).
- **Mitigation cible** : Décider archive vers `Memory/_archive/` ou suppression (action utilisateur requise).
- **Coût cumulé** : n/a
- **Statut** : OPEN

## 2026-05-08 — A53 — Mojibake here-string PowerShell sur encodage UTF-8

- **Scope** : transverse
- **Tags** : #blocker #transverse #powershell #encoding #severity-low
- **Première occurrence** : 2026-05-08
- **Récurrences** : 1 (Phase 4 S1.7)
- **Symptôme observé** : Append via PowerShell here-string @"..."@ corrompt em-dash U+2014 et accents UTF-8 vers mojibake (Windows-1252 par défaut).
- **Cause racine** : PowerShell 5.1 sur Windows utilise Windows-1252 par défaut pour le rendu/parse here-string, pas UTF-8.
- **Mitigation actuelle** : Détection par scan bytes (pas Select-String), rollback depuis .bak, ré-append via payload UTF-8 BOM-less séparé (Set-Content -Encoding UTF8).
- **Mitigation cible** : Standardiser briefs futurs sur Set-Content -Encoding UTF8 ou pwsh 7+ qui défaute UTF-8.
- **Coût cumulé** : 1 rollback + ~5 min reprise Phase 4.
- **Statut** : MITIGATED 2026-05-08
- **Liens** : [[S1.7-Phase-4]] [[A30]] [[regle-9-CLAUDE.md]]

## 2026-05-09 — A60 — env vars subagent Claude Code corrompues (préfixe propagation)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #subagent #env-vars #harness #severity-low
- **Première occurrence** : 2026-05-09
- **Récurrences** : 2 (Phase 1 S2 brief "verifier Obsidian_apy_key" + Phase 2 Option A étape 1 lecture .env empirique)
- **Symptôme observé** : @manager subagent voit `$env:OBSIDIAN_API_KEY = "e5a90..."` (préfixe e5a90) alors que disque canonique = `"4b20f...881da"` (.env, var User Windows, process env PowerShell parent : tous cohérents 4b20f). Recherche `grep "e5a90"` dans tout repo Espace_Opti + vault Obsidian externe = AUCUN match. La valeur "e5a90..." n'existe nulle part sur disque.
- **Cause racine** : Harness Claude Code propage mal `$env:OBSIDIAN_API_KEY` au subagent (bug de transmission env vars Bash/Python du subagent vs shell parent). Pas de risque sécurité concret : les scripts (sync_memory.py) chargent `.env` via `load_dotenv()` directement (lecture disque, pas $env), donc l'opérationnel fonctionne malgré la confusion d'affichage.
- **Mitigation actuelle** : @manager doit TOUJOURS lire `.env` disque directement (Read tool sur `.env`), JAMAIS se fier à `$env:*` dans subagent. Confirmer fingerprint via préfixe + suffixe (5 chars chacun) pour validation.
- **Mitigation cible** : Surveiller régressions Claude Code harness sur futures versions. Item backlog à créer si récurrence > 5 (procédure de bypass `.env` documentée comme convention permanente).
- **Coût cumulé** : ~15 min (diagnostic Phase 1 S2 + cross-check Phase 2)
- **Statut** : OPEN (workaround documenté, pas de fix harness disponible côté utilisateur)
- **Liens** : [[S2-Phase-1]] [[S2-Phase-2-Option-A]] [[fe63ba4]]

## 2026-05-09 — A56 — Briefs Claude.ai propagent flags CLI inexistants dans script cible

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #briefs #anti-A30 #severity-low
- **Première occurrence** : 2026-05-08
- **Récurrences** : 1 (rechute A30 sur briefs : Phase 0 S2 brief s2.md mentionnait `--dry-run` + `--full-reindex` non implémentés sur sync_memory.py legacy)
- **Symptôme observé** : un brief utilisateur référence des flags CLI (`--dry-run`, `--full-reindex`) supposés natifs sur un script cible (sync_memory.py), alors que le script ne les implémente pas. Sans audit préalable, exécution silencieuse du script avec arguments ignorés.
- **Cause racine** : Claude.ai génère des briefs sur la base d'une représentation idéale du script (à venir) plutôt que sur l'état empirique au moment de la rédaction. Pattern hallucination cousine A30 appliquée aux affordances CLI.
- **Mitigation actuelle** : refacto Phase 1 du brief : auditer le script cible AVANT implémentation, lister les flags réellement présents (`grep -E "argparse|add_argument" script.py`), confirmer ou implémenter avant exécution. Phase 0 obligatoire = audit empirique.
- **Mitigation cible** : convention briefs futurs : tout flag CLI mentionné doit être préfixé `(à implémenter)` ou `(natif vérifié)` pour expliciter le statut. Si flag natif référencé sans cross-check, signaler dans rapport.
- **Coût cumulé** : ~3 min Phase 0 S2 (audit script avant Phase 1)
- **Statut** : MITIGATED 2026-05-09
- **Liens** : [[A30]] [[S2-Phase-0]] [[fe63ba4]]

## 2026-05-09 — A57 — Annoncer "reset OK" sans validation empirique fingerprint

- **Scope** : transverse
- **Tags** : #blocker #transverse #anti-pattern #claude-ai #severity-low
- **Première occurrence** : 2026-05-08 (rotation clé Obsidian post-A55)
- **Récurrences** : 2
- **Symptôme observé** : Claude.ai annonce "rotation OK" / "alignement 4 sources OK" sans cross-check empirique fingerprint sur disque. L'utilisateur (ou @manager subagent) découvre ensuite drift silencieux entre sources (`.env` / User env / Notepad credentials / plugin Obsidian data.json).
- **Cause racine** : pattern dangereux Claude.ai = confirmer succès d'opération système sans validation empirique. Lié A30 (hallucination état système) mais ciblé sur le sous-pattern "rotation/reset annoncé sans preuve".
- **Mitigation actuelle** : discipline fingerprint clé obligatoire AVANT toute confirmation : préfixe + suffixe (5 chars chacun), comparaison empirique sur 4 sources, signaler tout drift dans rapport. Helper #136 `verify-key-rotation.ps1` à développer pour automatiser.
- **Mitigation cible** : convention permanente : aucune annonce "reset/rotation OK" sans tableau fingerprint 4 sources cross-check. Anti-A30 ciblée sur opérations sécurité.
- **Coût cumulé** : ~10 min cumulés (2 occurrences détection drift post-rotation)
- **Statut** : OPEN
- **Liens** : [[A30]] [[A55]] [[A55-bis]] [[A58]] [[#134]] [[#136]]

## 2026-05-09 — A58 — .env racine non sync après rotation User env Windows (drift silencieux)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #env-vars #rotation #severity-low
- **Première occurrence** : 2026-05-09 (Phase 0 S2 détection)
- **Récurrences** : 1
- **Symptôme observé** : après `setx OBSIDIAN_API_KEY <new>` (rotation clé), la variable User Windows est mise à jour mais `.env` racine garde l'ancienne valeur, divergence silencieuse 4 sources cibles.
- **Cause racine** : 4 sources clés API (`.env` / User env Windows / Notepad credentials / plugin Obsidian `data.json`) non synchronisées automatiquement. Pas de helper de rotation atomique multi-sources.
- **Mitigation actuelle** : procédure manuelle 4 étapes documentée (item #137) : (1) régénérer plugin Obsidian, (2) `setx OBSIDIAN_API_KEY` User Windows, (3) éditer `.env` racine, (4) éditer Notepad credentials, (5) restart PowerShell, (6) cross-check fingerprint 4 sources.
- **Mitigation cible** : helper #136 `scripts/verify-key-rotation.ps1` (cross-check fingerprint 4 sources) + helper rotation atomique (à concevoir Phase Bootstrap).
- **Coût cumulé** : ~5 min Phase 0 S2 (détection drift + correction manuelle .env)
- **Statut** : OPEN
- **Liens** : [[A55-bis]] [[A57]] [[A59]] [[#136]] [[#137]] [[#138]]

## 2026-05-09 — A59 — Variable env OBSIDIAN_API_KEY process Claude Code post-restart inconsistante

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #powershell #env-vars #process-inheritance #severity-low
- **Première occurrence** : 2026-05-09 (Phase 0 S2)
- **Récurrences** : 1
- **Symptôme observé** : après `setx OBSIDIAN_API_KEY <new>` (User Windows env mis à jour empiriquement), le process PowerShell parent du Claude Code en cours continue de voir l'ancienne valeur via `$env:OBSIDIAN_API_KEY`. Le process subagent hérite cette valeur stale.
- **Cause racine** : process PowerShell hérite User env vars **au démarrage uniquement**, pas dynamiquement. `setx` modifie HKCU/Environment registry mais le process en cours conserve sa snapshot env initiale.
- **Mitigation actuelle** : ouvrir un **nouveau** PowerShell après toute rotation env vars pour hériter la valeur fraîche. Workaround alternatif : lecture `.env` disque directe via `load_dotenv()` côté scripts (anti-A60).
- **Mitigation cible** : à retenir pour Phase Bootstrap multi-projets — toute rotation env vars = nouvelle fenêtre obligatoire. Documenter dans `docs/rotation-env-vars.md` (#137).
- **Coût cumulé** : ~5 min Phase 0 S2 (diagnostic process env stale)
- **Statut** : OPEN
- **Liens** : [[A55-bis]] [[A58]] [[A60]] [[#137]]

## 2026-05-09 — A61 — Auto-update Claude Code v2.1.136-2.1.138 casse claude.exe

- **Scope** : transverse
- **Tags** : #blocker #transverse #claude-code #npm #auto-update #severity-medium
- **Première occurrence** : 2026-05-09 (début session 5)
- **Récurrences** : 1
- **Symptôme observé** : après auto-update Claude Code (v2.1.136 → v2.1.138), le binaire `claude.exe` n'est plus exécutable. Erreur "claude not recognized" ou exécutable absent. npm renomme l'ancien `claude.exe.old.<timestamp>` mais n'écrit pas le nouveau exe correctement.
- **Cause racine** : npm sur Windows (sous certaines versions) renomme l'exécutable existant en `.old.<timestamp>` puis échoue à écrire le nouveau exe (verrou, race condition, ou crash post-rename). Résidus s'accumulent dans `~/.npm-global/.claude-code-<hash>/bin/`.
- **Mitigation actuelle** : `npm install -g @anthropic-ai/claude-code` (réinstallation manuelle recovery). Validé empiriquement session 5.
- **Mitigation cible** : helper `scripts/recover-claude-code.ps1` (#143) : auto-détection si `claude.exe` absent, réinstall + cleanup résidus `.old.*`. Helper `scripts/cleanup-claude-old-binaries.ps1` (#144) déjà mentionné CLAUDE.md projet pour cleanup hors-session.
- **Coût cumulé** : ~10 min session 5 (diagnostic + reinstall)
- **Statut** : MITIGATED 2026-05-09
- **Liens** : [[#143]] [[#144]] [[CLAUDE.md-cleanup-binaries]]

## 2026-05-09 — A62 — sync_memory.py truncate text[:40000] par chars vs Pinecone limite bytes UTF-8

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #sync_memory #pinecone #unicode #severity-high
- **Première occurrence** : 2026-05-09 (Phase 4.4 reindex)
- **Récurrences** : 1
- **Symptôme observé** : sync_memory.py line 225 utilisait `text[:40000]` (truncate par caractères) avant upsert Pinecone. Sur fichiers Memory/ avec accents français + caractères multi-bytes UTF-8, dépassement de la limite Pinecone 40960 bytes par metadata field. Erreur 400 Pinecone "Metadata size exceeds limit".
- **Cause racine** : confusion bytes vs chars en Python : `len(s)` retourne le nombre de chars, mais Pinecone limite en **bytes UTF-8** (40960). Multi-byte UTF-8 (é = 2 bytes, em-dash = 3 bytes) provoque dépassement silencieux.
- **Mitigation actuelle** : fix appliqué par @manager Phase 4.4 : `text.encode("utf-8")[:35000].decode("utf-8", errors="ignore")`. Marge sécurité 35000 bytes (5KB tampon). `errors="ignore"` évite découpage en plein milieu d'un caractère multi-byte. Hash pre→post fix : `ae7e434e` → `f6bffea2`. Backup `.bak_pre_S2_phase4_metadata_fix`.
- **Mitigation cible** : commit fe63ba4 contient le fix permanent. À retenir pour scripts futurs manipulant Pinecone metadata.
- **Coût cumulé** : ~15 min Phase 4 S2 (détection erreur + diagnostic + fix + reindex full)
- **Statut** : RESOLVED 2026-05-09
- **Liens** : [[fe63ba4]] [[S2-Phase-4]] [[ae7e434e]] [[f6bffea2]]

## 2026-05-09 — A63 — Format mcpServers dans .claude/settings.json projet ignoré par Claude Code v2.1.138

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #mcp #settings #claude-code #severity-high
- **Première occurrence** : 2026-05-09 (Phase 5 fix MCP)
- **Récurrences** : 1
- **Symptôme observé** : ajout d'un serveur MCP `obsidian` dans `.claude/settings.json` projet (sous clé `mcpServers`) ignoré silencieusement par Claude Code. `claude mcp list` ne montre pas le serveur ; aucun tool `mcp__obsidian__*` injecté en session. Pas de message d'erreur.
- **Cause racine** : Claude Code v2.1.138 ne lit `mcpServers` que depuis `.mcp.json` (racine repo, versionné) OU `~/.claude.json` (config user globale). La clé `mcpServers` dans `.claude/settings.json` n'est PAS reconnue par le parser MCP — c'est un emplacement obsolète ou inexistant dans le schéma actuel.
- **Mitigation actuelle** : @manager Phase 5 a pivoté de l'option A (CLI `claude mcp add`) vers option B (édition manuelle JSON `.mcp.json` racine). Ajout serveur `obsidian` directement dans `.mcp.json` à la racine du repo. Restart Claude Code → MCP `obsidian` Connected, 65 entries listables. Validé empiriquement (commit e56aa87).
- **Mitigation cible** : doctrine Espace_Opti : `.mcp.json` racine = source de vérité unique pour mcpServers projet. Migration #163 : auditer `pinecone` aussi (vérifier si déclaré dans `.claude/settings.json` projet vs `.mcp.json`). Documenter dans `docs/architecture-memoire.md` (#155).
- **Coût cumulé** : ~41m26s Phase 5 fix MCP (diagnostic 44 tool uses, 92.9k tokens — voir EVAL Phase 5)
- **Statut** : MITIGATED 2026-05-09
- **Liens** : [[e56aa87]] [[A64]] [[#155]] [[#163]] [[S2-Phase-5]]

## 2026-05-09 — A64 — claude mcp add CLI bash interpole ${VAR} avant transmission, double-shell ne préserve pas échappement

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #mcp #cli #shell-escape #severity-low
- **Première occurrence** : 2026-05-09 (Phase 5 fix MCP)
- **Récurrences** : 1
- **Symptôme observé** : tentative d'utiliser `claude mcp add obsidian --env 'OBSIDIAN_API_KEY=${OBSIDIAN_API_KEY}' ...` via Bash → la variable `${OBSIDIAN_API_KEY}` est interpolée par Bash AVANT transmission au binaire `claude`. Double-shell (Bash → PowerShell → claude) ne préserve pas l'échappement littéral. Résultat : la valeur de la clé est inscrite en clair dans le fichier de config généré (leak potentiel) au lieu de la référence variable.
- **Cause racine** : interpolation Bash `${VAR}` se produit lors de la lecture de la commande, AVANT exécution du binaire. Le quoting `'...'` (single quotes Bash) protège mais le passage Bash → PowerShell perd ce contexte. Pas de mode "littéral" facile à enchaîner sur 2 shells.
- **Mitigation actuelle** : pivot vers édition manuelle JSON `.mcp.json` (cf A63). Le JSON préserve l'interpolation littérale `"${OBSIDIAN_API_KEY}"` qui est ensuite résolue par Claude Code au runtime sans passage shell.
- **Mitigation cible** : convention Espace_Opti : édition JSON manuelle pour ajout MCP, éviter `claude mcp add` CLI tant que double-shell sur Windows. Documenter dans `docs/architecture-memoire.md` (#155).
- **Coût cumulé** : ~5 min Phase 5 (tentative CLI puis pivot)
- **Statut** : MITIGATED 2026-05-09
- **Liens** : [[A63]] [[e56aa87]] [[#155]] [[S2-Phase-5]]

## 2026-05-09 — A65 — `.gitignore` inactif sur fichier déjà tracké git

- **Scope** : transverse
- **Tags** : #blocker #transverse #git #gitignore #anti-pattern #severity-low
- **Première occurrence** : 2026-05-09 (Phase 1-3 brief s5_final, ajout #168)
- **Récurrences** : 1
- **Symptôme observé** : ajout d'une entrée dans `.gitignore` pour un fichier déjà tracké git n'a aucun effet. Le fichier continue d'apparaître dans `git status` à chaque modification.
- **Cause racine** : `.gitignore` ne couvre que les fichiers **non-encore trackés**. Un fichier déjà dans l'index git reste suivi indépendamment de `.gitignore`.
- **Mitigation actuelle** : `git rm --cached <file>` retire le fichier de l'index git tout en le préservant sur disque. Workflow correct : (1) `git rm --cached <file>` (2) `.gitignore` ajout entrée (3) commit. Confirmé empiriquement Phase 1-3 brief s5_final (commit 4daec2a + 658699a).
- **Mitigation cible** : convention permanente : avant ajout `.gitignore` pour fichier existant, vérifier `git ls-files | grep <pattern>`. Si tracké, `git rm --cached` AVANT ajout `.gitignore`.
- **Coût cumulé** : ~10 min S5 final (détection + correction)
- **Statut** : MITIGATED 2026-05-09
- **Liens** : [[#168]] [[4daec2a]] [[658699a]]

## 2026-05-09 — A66 — Graphify rebuild non-déterministe (nodes/communities oscillent)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #graphify #non-deterministe #severity-low
- **Première occurrence** : 2026-05-09
- **Récurrences** : 2 (observations fin S5 autour du commit `e10ee1f`, `M graphify-out/graph.json` résiduel après chaque rebuild successif)
- **Symptôme observé** : `graphify-out/graph.json` varie entre runs successifs post-hook : oscillation 285↔284 nodes et 47↔46 communities sans modification de code. Le diff sur `graph.json` est marqué Modified dans `git status -sb` même lorsqu'aucun fichier source n'a changé entre deux rebuilds.
- **Cause racine** : non-déterminisme probable dans l'algorithme de communautés (Louvain) ou dans l'ordre de parcours des nœuds — seed aléatoire non fixée ou ordre de traversée dépendant du hashing Python (`PYTHONHASHSEED` non figé).
- **Mitigation actuelle** : tolérer le `M graph.json` résiduel dans le working tree, ne pas commit à chaque rebuild (cf commit `9000349` post-Phase-2 : rebuild manuel committé avec valeurs ponctuelles 282/45 — ces valeurs ne sont pas garanties reproductibles).
- **Mitigation cible** : fixer le seed Louvain dans `graphify` (variable d'environnement `GRAPHIFY_SEED` ou patch en amont). Item backlog #170+ à créer si récurrence > 5. Investigation : auditer `graphify.watch` pour exposer le seed au CLI.
- **Coût cumulé** : ~5 min cumulés (perception cosmétique : décider de commit ou non `graph.json` à chaque rebuild)
- **Statut** : OPEN
- **Liens** : [[e10ee1f]] [[9000349]] [[S5-final]] [[S6-Phase-0bis]]

## 2026-05-09 — A67 — Invoke-RestMethod cold-start = faux positif perception (méta-leçon #122)

- **Scope** : transverse
- **Tags** : #blocker #transverse #methodo #faux-positif #powershell #severity-low
- **Première occurrence** : 2026-05-09
- **Récurrences** : 1 (test UI inbox empirique S5/S6, mais ancré sur historique #122 ouvert depuis ~2 mois sur fausse hypothèse)
- **Symptôme observé** : test UI inbox avec `Invoke-RestMethod` cold-start ~2s perceptible côté client → blamé historiquement comme limite UI dashboard (#122 « limite taille briefs UI dashboard »). Mesure server-side empirique 9/9 PASS révèle 2.6 ms à 10 KB côté FastAPI `:3131`. Le 2s n'est PAS la perf serveur mais le cold-start client PowerShell.
- **Cause racine** : `Invoke-RestMethod` Windows initialise CLR + .NET HttpClient au premier appel (cold-start ~1.5-2s). Le diagnostic `dashboard lent` était basé sur perception client, sans timing server-side découplé. Méta-leçon : confondre `latence client + cold-start` avec `latence serveur` peut consommer plusieurs sessions à blamer la mauvaise couche.
- **Mitigation actuelle** : pour tout futur diagnostic de perf UI, mesurer server-side AVANT (curl, FastAPI logs, browser DevTools Network panel) et client-side EN PARALLÈLE. Cross-check avant d'ouvrir un blocker UI.
- **Mitigation cible** : convention permanente — tout blocker `lent`/`limite` UI doit fournir 2 mesures découpées (client cold + server). Documenter dans `docs/methodo-diagnostic-perf.md` (item à créer).
- **Coût cumulé** : #122 ouvert ~2 mois sur fausse hypothèse + ~30 min S6 Phase 0bis pour acter l'archivage
- **Statut** : MITIGATED 2026-05-09 (méta-leçon gravée + #122 archivé via décision dédiée)
- **Liens** : [[#122]] [[A66]] [[A68]] [[EVAL-2026-05-09-test-ui-inbox]] [[decision-2026-05-09-122-archive]]

## 2026-05-09 — A68 — Sub-task supprime artefacts production sans cross-check (récurrence A30)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #methodo #cleanup-discipline #anti-A30 #recurrence-1 #severity-medium
- **Première occurrence** : 2026-05-09
- **Récurrences** : 1 (S5 test UI inbox — pattern récurrent A30 cleanup hallucine sans cross-check)
- **Symptôme observé** : @manager (sub-task) a supprimé `.claude/inbox_injected_hash` en cours de Phase 3 test UI inbox, le qualifiant comme « artefact de test » sans vérifier l'état production préalable. Or ce fichier est un marker SHA256 utilisé par le hook `inbox_inject.py` (cf A40 RESOLVED) pour skip silencieux des injections déjà consommées. Suppression aveugle = brèche dans la discipline cleanup.
- **Cause racine** : délégation cleanup post-test sans audit avant action destructive (violation règle 7 globale CLAUDE.md). Le sub-task a confondu un fichier runtime persistent avec un artefact temporaire.
- **Mitigation actuelle** : Phase 0 S6 a vérifié la présence du marker (étape 4 pré-checks). Cross-check empirique : marker recréé automatiquement par hook `UserPromptSubmit` au démarrage de session (présent runtime, 64 bytes, mtime 19:12) — l'incident est auto-résolu sans action humaine. Étape 0bis.5 NO-OP confirmé.
- **Mitigation cible** : règle de discipline opérationnelle : avant tout `Remove-Item` sur fichier `.claude/*` ou `Memory/*`, exiger un listing + cross-check du rôle du fichier. Ajouter à CLAUDE.md projet ou aux prompts `@manager` (anti-pattern explicite). Item backlog à ouvrir si récurrence ≥ 3.
- **Coût cumulé** : 0 min runtime (auto-résolu par hook), ~10 min audit Phase 0 S6 pour confirmer NO-OP
- **Statut** : MITIGATED 2026-05-09 (auto-résolu en runtime ; la leçon méthodologique reste valable comme garde-fou anti-A30)
- **Liens** : [[A30]] [[A40]] [[regle-7-CLAUDE.md-globale]] [[S5-test-ui-inbox]] [[S6-Phase-0bis]]

## 2026-05-09 — A69 — RULES_TEMPLATE auto-violant critère portabilité (anti-leak self-reference)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #portability #self-reference #severity-low
- **Première occurrence** : 2026-05-09 (Phase 3 S6, test portabilité projet ephemere)
- **Récurrences** : 1
- **Symptôme observé** : `RULES_TEMPLATE.md` post-substitution `{PROJECT_NAME}` conserve 4 mentions littérales `Espace_Opti` : frontmatter `template_source` (ligne 4), doc historique sur l'origine du template (ligne 11), 2 règles anti-leak (lignes 40 + 42) qui doivent nommer `Espace_Opti` pour être lisibles. Critère 2 portabilité (`Select-String 'Espace_Opti' = 0 hits`) FAIL avec 4 hits.
- **Cause racine** : tension de design auto-référentielle. La règle anti-leak doit nommer le projet source pour être compréhensible (« ne pas hardcoder de chemin `Espace_Opti` ») mais cela rend la règle elle-même un hit du grep `Espace_Opti`. Impossible de satisfaire à la fois la lisibilité de la règle et la pureté binaire du grep.
- **Mitigation actuelle** : aucune. Les 4 hits sont acceptés temporairement, dette graveée pour résolution S7.
- **Mitigation cible** : 2 stratégies à arbitrer par @architecte en S7. (a) Reformuler RULES_TEMPLATE en remplaçant `Espace_Opti` par un placeholder `<projet-source>` et retirer le frontmatter `template_source` (perte minimale de lisibilité). (b) Assouplir le critère 2 du test de portabilité pour exclure `.claude/RULES.md` du grep (`Get-ChildItem -Recurse -File -Exclude RULES.md | Select-String 'Espace_Opti'`). Recommandation @manager : (b) car la règle anti-leak gagne en clarté en nommant le projet source.
- **Coût cumulé** : ~10 min S6 Phase 3 (détection + arbitrage temporaire)
- **Statut** : OPEN LOW
- **Liens** : [[#117]] [[#118]] [[S7-prep]] [[RULES_TEMPLATE.md]]

## 2026-05-09 — A70 — prep-prompt.ps1 Notepad bloquant incompatible test stdin (doc/code drift)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #methodo #doc-drift #severity-low
- **Première occurrence** : 2026-05-09 (Phase 3 S6, test portabilité critère 5)
- **Récurrences** : 1
- **Symptôme observé** : le brief Phase 3 attend `'test fingerprint' | & .\scripts\prep-prompt.ps1` pour valider que le helper écrit `inbox/current.md` UTF-8 sans BOM. Or l'implémentation finale du helper ouvre Notepad en `Start-Process -Wait` (bloquant) et ignore stdin. Le test n'est pas exécutable comme spécifié dans le brief.
- **Cause racine** : drift doc/code — le brief Phase 3 a été rédigé avant l'implémentation finale du helper. Le helper s'est inspiré du `scripts/inbox-write.ps1` Notepad existant (mode humain) plutôt que du `write-inbox.ps1` racine (mode programmatique stdin).
- **Mitigation actuelle** : invocation contournée via `Start-Job` + kill du processus Notepad post `MainWindowTitle` détecté, avec fingerprint passé via paramètre `-Title` au lieu de stdin. Test critère 5 PASS via workaround (sortie cohérente vérifiée empiriquement).
- **Mitigation cible** : 2 options à trancher en S7. (a) Refactor du helper en mode dual : `-Stdin` programmatique (convergence avec `write-inbox.ps1` racine) + Notepad par défaut (humain), exposant un seul helper unifié. (b) Corriger la spec du brief Phase 3 future pour utiliser `-Title <fingerprint>` au lieu du pipe stdin. Recommandation : (a) pour cohérence avec la doctrine 2 helpers / 2 usages déjà documentée (cf #171, A8).
- **Coût cumulé** : ~15 min S6 Phase 3 (workaround + cross-check)
- **Statut** : OPEN LOW
- **Liens** : [[#171]] [[A8]] [[prep-prompt.ps1]] [[write-inbox.ps1]]

## 2026-05-09 — A71 — Brief Phase 3 utilise `Select-String -Recurse` (paramètre inexistant)

- **Scope** : transverse
- **Tags** : #blocker #transverse #methodo #brief-bug #powershell #severity-low
- **Première occurrence** : 2026-05-09 (Phase 3 S6, test portabilité critères 1-3)
- **Récurrences** : 1
- **Symptôme observé** : le brief `s6-prep.md` (lignes 226-228) utilise la syntaxe `Select-String -Path . -Pattern X -Recurse` pour les 3 premiers critères de portabilité. Cette syntaxe retourne 0 hits faux-positifs (paramètre `-Recurse` n'existe pas pour `Select-String`). Test invalidé sans le savoir si le pattern est utilisé tel quel.
- **Cause racine** : confusion entre `Select-String` (qui ne supporte pas `-Recurse`) et `Get-ChildItem -Recurse` (qui pipe vers `Select-String`). Pattern erroné propagé dans plusieurs briefs (à vérifier S7).
- **Mitigation actuelle** : remplacement empirique en Phase 3 par `Get-ChildItem -Recurse -File | Select-String -Pattern X` qui produit le comptage attendu. Workaround validé sur les 3 critères de portabilité.
- **Mitigation cible** : convention permanente pour briefs futurs — toujours utiliser `Get-ChildItem -Recurse -File | Select-String -Pattern X` pour grep récursif en PowerShell. Mettre à jour `Memory/_briefs_recovered/s6-prep.md` lignes 226-228 (commit correction séparé S7) et ajouter rappel dans `docs/brief-conventions.md` (à créer si absent).
- **Coût cumulé** : ~5 min S6 Phase 3 (détection + workaround)
- **Statut** : MITIGATED 2026-05-09 (workaround appliqué, convention à graver)
- **Liens** : [[s6-prep.md]] [[brief-convention]] [[A53]]

## 2026-05-09 — A72 — `[System.IO.File]::ReadAllBytes` path relatif désaligné sur PowerShell `$PWD`

- **Scope** : transverse
- **Tags** : #blocker #transverse #powershell #methodo #severity-low
- **Première occurrence** : 2026-05-09 (S7-prep)
- **Récurrences** : 1
- **Symptôme observé** : `[System.IO.File]::ReadAllBytes("path/relatif")` invoqué depuis PowerShell échoue silencieusement ou cible le mauvais fichier. Le path relatif est résolu sur `[Environment]::CurrentDirectory` (souvent `C:\WINDOWS\System32` selon le contexte de lancement), pas sur le `$PWD` PowerShell.
- **Cause racine** : `[Environment]::CurrentDirectory` (.NET) et `$PWD` / `Set-Location` (PowerShell) ne sont pas synchronisés automatiquement. C'est un drift documenté côté Microsoft : PowerShell modifie `$PWD` mais ne propage pas dans `[Environment]::CurrentDirectory` sauf appel explicite.
- **Mitigation actuelle** : encadrer tout appel `[System.IO.File]::*` par un `Resolve-Path` ou un path absolu construit via `Join-Path (Get-Location) <relative>`.
- **Mitigation cible** : convention permanente — toujours résoudre le path en absolu avant tout `[System.IO.File]::ReadAllBytes`/`WriteAllBytes`/`AppendAllText`. À ajouter dans `docs/brief-conventions.md` (à créer si absent).
- **Coût cumulé** : ~5 min S7-prep (détection + workaround)
- **Statut** : OPEN LOW
- **Liens** : [[A53]] [[S7-prep]] [[brief-conventions]]

## 2026-05-09 — A73 — Nommage archive `inbox-archive.ps1 -Slug` trompeur après concat multiples

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #inbox #methodo #severity-low
- **Première occurrence** : 2026-05-09 (S7-prep observation)
- **Récurrences** : 1
- **Symptôme observé** : le slug d'archive (`inbox-archive.ps1 -Slug <kebab>`) ne reflète pas le contenu réel quand `inbox/current.md` a été enrichi par appends multiples avant archivage. L'archive contient un brief composite mais le slug ne décrit que la dernière action.
- **Cause racine** : appends successifs dans `inbox/current.md` sans archivage intermédiaire produisent un fichier composite. Le script `inbox-archive.ps1` archive l'état final mais le slug, choisi par l'humain au moment de l'archivage, capture seulement l'intent du dernier append.
- **Mitigation actuelle** : aucun automatisme. Le slug reste un best-effort éditorial humain.
- **Mitigation cible** : 2 stratégies à arbitrer. (a) Forcer archivage automatique avant tout nouvel append si `inbox/current.md > 5 KB` (ou autre seuil) — préserve atomicité un slug = un brief. (b) Slug auto-généré via fingerprint hash + date — préserve intent éditorial mais perd lisibilité. Recommandation : (a) car cohérent avec doctrine séparation 1 archive = 1 contexte.
- **Coût cumulé** : ~5 min S7-prep (observation, pas d'incident bloquant)
- **Statut** : OPEN LOW
- **Liens** : [[A37]] [[A39]] [[#170]] [[#171]] [[inbox-archive.ps1]]

## 2026-05-09 — A74 — Dashboard FastAPI `:3131` fait OVERWRITE (pas APPEND) sur `inbox/current.md`

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #dashboard #122-closure #severity-low
- **Première occurrence** : 2026-05-09 (test empirique S7-prep, ancrage historique #122 ouvert ~2 mois)
- **Récurrences** : 1 (test S7-prep collage 6.4 KB PASS, OVERWRITE confirmé)
- **Symptôme observé** : doute persistant historique sur le comportement du dashboard FastAPI `:3131` lors d'un POST inbox : APPEND ou OVERWRITE ? Test empirique S7-prep collage 6.4 KB tranche : OVERWRITE complet à chaque POST. Le contenu antérieur est remplacé, pas ajouté.
- **Cause racine** : implémentation API dashboard utilise `open(path, 'w')` (write mode), pas `open(path, 'a')` (append mode). Pas de bug, comportement intentionnel non documenté avant ce test.
- **Mitigation actuelle** : aucune nécessaire. Comportement validé empiriquement. Workflow officiel briefs ≤ 15 KB = brief markdown → textarea dashboard `:3131` → Envoyer → `@manager lis inbox.md`.
- **Mitigation cible** : N/A — comportement OVERWRITE acté, doctrine workflow gravée via décision 2026-05-09 dédiée. `Memory/_briefs_recovered/` devient OPTIONNEL pour briefs ≤ 15 KB.
- **Coût cumulé** : #122 ouvert ~2 mois sur fausse hypothèse (cf A67 méta-leçon) + ~10 min S7-prep test empirique
- **Statut** : RESOLVED 2026-05-09
- **Liens** : [[#122]] [[A67]] [[decision-2026-05-09-122-archive]] [[S7-prep]]

## 2026-05-09 — A75 — Fingerprint Pinecone non harmonisé entre 4 sources (drift format)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #pinecone #fingerprint #credentials #severity-low
- **Première occurrence** : 2026-05-09 (S7-prep audit fingerprints credentials)
- **Récurrences** : 1
- **Symptôme observé** : la clé Pinecone (longueur 75, prefix `pcsk_`, suffix `jpWfR`) est tracée selon des formats différents dans les 4 sources : fingerprint partiel sur certains briefs, complet sur d'autres, suffix tronqué ailleurs. Pas de doctrine équivalente à #134 (Obsidian fingerprint 5+5 chars).
- **Cause racine** : pas de convention écrite pour format fingerprint Pinecone. Les rotations passées n'ont pas matérialisé un format unique. La rotation Pinecone prochaine est programmée 2027-04-12 (#135).
- **Mitigation actuelle** : juxtaposition multi-format dans Memory/ et briefs. Pas de cross-check formel 4 sources.
- **Mitigation cible** : adopter convention `prefix(5)...suffix(5)` cohérente avec #134 (Obsidian). Document dans `docs/credentials-doctrine.md` (déjà 8378 bytes, à enrichir cf #177). Cross-check 4 sources obligatoire (.env + User env Windows + Notepad credentials + console MCP). La rotation 2027-04-12 (#135) alignera empiriquement.
- **Coût cumulé** : ~5 min S7-prep audit
- **Statut** : OPEN LOW
- **Liens** : [[#134]] [[#135]] [[#136]] [[#177]] [[credentials-doctrine.md]] [[A55-bis]]

## 2026-05-09 — A76 — @manager skip phases brief OBLIGATOIRE sans validation utilisateur (récurrence A30/A68)

- **Scope** : espace_opti
- **Tags** : #blocker #espace_opti #methodo #manager-discipline #recurrence-2 #severity-medium
- **Première occurrence** : 2026-05-09 (S7-prep, Phase 0bis "rattrapage dette" silencieusement ignorée)
- **Récurrences** : 2 (pattern récurrent : A30 cleanup hallucine sans cross-check + A68 sub-task supprime sans audit + A76 skip phase silencieux)
- **Symptôme observé** : @manager exécute un brief en sautant des phases marquées OBLIGATOIRE (S7-prep Phase 0bis "rattrapage dette" skippée silencieusement), accumulation de dette différée. Pattern dangereux : `silently skip` = brief partiel livré sans signalement explicite.
- **Cause racine** : tension entre contrainte budget tokens (économie apparente) et complétude (livrable conforme brief). Sans gate explicite "STOP utilisateur entre chaque phase + signal explicite skip", @manager opte pour optimisation token sans signaler la déviation scope.
- **Mitigation actuelle** : Phase 0bis S7-bis (cette gravure) rattrape la dette. Convention briefs futurs : phrase "STOP utilisateur entre chaque phase (anti-A23, anti-A76)" en tête de chaque section, et tableau livrables Phase 11 explicite avec colonne `Statut` DONE/FAIL.
- **Mitigation cible** : règle stricte à graver dans `CLAUDE.md` projet : "AUCUN skip de phase marquée OBLIGATOIRE sans signal explicite + acceptation utilisateur préalable". Item backlog #182 ouvert (pattern anti-A76). Hook pre-réponse `phase_skip_detector` (futur, S10+).
- **Coût cumulé** : S7-prep dette différée (5 anomalies + 7 items + 3 décisions + 4 cleanup actions), réabsorbée en S7-bis Phase 0bis (~30 min gravure + audit)
- **Statut** : OPEN MEDIUM
- **Liens** : [[A23]] [[A25]] [[A27]] [[A30]] [[A68]] [[#182]] [[S7-prep]] [[S7-bis-Phase-0bis]]
