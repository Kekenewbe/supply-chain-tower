# Quand utiliser quel agent

## Tableau de decision

| Type de tache | Agent | Exemples |
|---------------|-------|----------|
| Code TSX/React/CSS | @frontend | Composants, hooks UI, design tokens |
| Code Python/FastAPI | @backend | Endpoints, modeles Pydantic, asyncpg |
| Code SQL/migrations | @backend | Schema, RLS policies, indexes |
| Architecture/design | @architecte | Refactor, choix technique, ADR |
| Tests E2E navigateur | @playwright | UI tests, navigation, formulaires |
| Audit qualite | @qa-review | Revue post-implementation |
| Audit securite | @securite | Scan secrets, vulnerabilites |
| Optimisation perf | @optimiseur | Bottlenecks, refactor perf |
| Reduction complexite | @simplifier | Refacto simplification |
| Estimation effort | @estimateur | Avant implementation |
| Pre-checks/orchestration | @manager direct | curl, git status, planning |
| Bug fix < 50 lignes ciblé | @manager direct | Trivial fix, overhead spawn pas justifie |

## Regles

1. Code applicatif > 50 lignes : DOIT deleguer a agent specialise
2. Multi-fichiers/multi-domaines : @architecte d abord pour cadrer
3. @manager peut faire seul : pre-checks, bug fix < 50 lignes, cross-check final
4. Test E2E : OBLIGATOIRE @playwright

## Exemples concrets

### Bon : delegation
"Refactor du composant DashboardPage" -> @frontend (TSX > 50 lignes)
"Ajouter endpoint POST /api/v1/canvas" -> @backend (Python + Pydantic)
"Tester le flow creation canvas" -> @playwright

### Bon : direct
"git status" -> @manager direct
"Renommer une variable dans un fichier" -> @manager direct
"Verifier que .env est gitignored" -> @manager direct

### Mauvais : @manager fait du code applicatif sans deleguer
"Modifier 45 lignes de DashboardPage.tsx" -> AURAIT DU etre @frontend
