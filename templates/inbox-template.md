[TITRE de la tache]

==========================
CONTEXTE
==========================
- Etat actuel
- Pre-requis valides

==========================
DELEGATION ATTENDUE PAR PHASE
==========================

| Phase | Tache | Agent attendu | Justification si different |
|-------|-------|---------------|----------------------------|
| Phase 0 | Pre-checks (curl, git status, file existence) | @manager direct | Meta-orchestration |
| Phase X.1 | [code TSX/React/CSS] | @frontend OBLIGATOIRE | - |
| Phase X.2 | [code Python/FastAPI/SQL/scripts] | @backend OBLIGATOIRE | - |
| Phase X.3 | [architecture/design] | @architecte OBLIGATOIRE | - |
| Phase Y | Test E2E navigateur | @playwright OBLIGATOIRE | - |
| Phase Z | Cross-check fichier genere | @manager direct | Validation finale |

REGLE : si une phase touche du code applicatif, @manager DOIT deleguer
a l agent specialise sauf justification ecrite dans le rapport.

==========================
PHASES DETAILLEES
==========================
[...]

==========================
GARDE-FOUS
==========================
- Cle Supabase NE JAMAIS exposee
- Backup avant modification (.bak_<feature>)
- Si depasse X lignes : STOP utilisateur
- Respect regle 12 cross-check empirique

==========================
RAPPORT ATTENDU
==========================
| Phase | Statut | Evidence |
|-------|--------|----------|

==========================
APRES VALIDATION
==========================
STOP utilisateur pour go suivant.

Vas-y.
