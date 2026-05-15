# SOP-003 â€” DÃ©veloppement parallÃ¨le

## Principe
L'Architecte dÃ©coupe le PRD validÃ© en modules indÃ©pendants (`modules.json` + `ARCHITECTURE.md`).
**Frontend** et **Backend** dÃ©marrent en parallÃ¨le sur leurs modules respectifs.
**SÃ©curitÃ©** surveille en temps rÃ©el via un hook automatique (pas d'invocation manuelle).

## Ordre d'exÃ©cution

1. **Architecte** â†’ `ARCHITECTURE.md` + `modules.json`
   â†’ ðŸ›‘ **validation utilisateur obligatoire**
2. **En parallÃ¨le** (deux terminaux Claude Code distincts) :
   - **Frontend Agent** â†’ composants UI, pages, styles
   - **Backend Agent** â†’ API, schÃ©ma DB, services
3. **SÃ©curitÃ©** â†’ intercepte automatiquement chaque `Edit`/`Write` (PreToolUse hook)
4. **QA Review** â†’ dÃ©clenchÃ© Ã  la fin de chaque module marquÃ© `DONE`
5. **Simplifier** â†’ aprÃ¨s QA Review, uniquement si score â‰¥ 80 %
6. **Playwright** â†’ aprÃ¨s Simplifier, avant livraison

## RÃ¨gles de parallÃ©lisme
- **Un agent = un terminal Claude Code.** Jamais deux agents dans la mÃªme session.
- Chaque agent lit `modules.json` pour connaÃ®tre son pÃ©rimÃ¨tre strict.
- **Les agents ne modifient pas les fichiers des autres agents.** Si un besoin croisÃ© apparaÃ®t, ils passent par l'Architecte pour nÃ©gocier un nouveau contrat.
- Les **contrats d'interface** dÃ©finis dans `ARCHITECTURE.md` sont **immuables** tant que l'Architecte ne les a pas rÃ©visÃ©s.
- Les mises Ã  jour de `modules.json` (statut TODO/IN_PROGRESS/DONE) sont atomiques : un seul agent Ã©crit Ã  la fois (verrouillage optimiste via git).

## Interruptions acceptables
- L'utilisateur peut demander Ã  un agent de s'arrÃªter Ã  tout moment.
- Une alerte SÃ©curitÃ© `BLOCKED` interrompt l'agent courant : il doit corriger et reprendre.
- Un Ã©chec QA Review < 80 % renvoie l'agent sur le module concernÃ© pour corrections.

