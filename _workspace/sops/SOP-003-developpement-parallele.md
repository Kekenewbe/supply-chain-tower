# SOP-003 — Développement parallèle

## Principe
L'Architecte découpe le PRD validé en modules indépendants (`modules.json` + `ARCHITECTURE.md`).
**Frontend** et **Backend** démarrent en parallèle sur leurs modules respectifs.
**Sécurité** surveille en temps réel via un hook automatique (pas d'invocation manuelle).

## Ordre d'exécution

1. **Architecte** → `ARCHITECTURE.md` + `modules.json`
   → 🛑 **validation utilisateur obligatoire**
2. **En parallèle** (deux terminaux Claude Code distincts) :
   - **Frontend Agent** → composants UI, pages, styles
   - **Backend Agent** → API, schéma DB, services
3. **Sécurité** → intercepte automatiquement chaque `Edit`/`Write` (PreToolUse hook)
4. **QA Review** → déclenché à la fin de chaque module marqué `DONE`
5. **Simplifier** → après QA Review, uniquement si score ≥ 80 %
6. **Playwright** → après Simplifier, avant livraison

## Règles de parallélisme
- **Un agent = un terminal Claude Code.** Jamais deux agents dans la même session.
- Chaque agent lit `modules.json` pour connaître son périmètre strict.
- **Les agents ne modifient pas les fichiers des autres agents.** Si un besoin croisé apparaît, ils passent par l'Architecte pour négocier un nouveau contrat.
- Les **contrats d'interface** définis dans `ARCHITECTURE.md` sont **immuables** tant que l'Architecte ne les a pas révisés.
- Les mises à jour de `modules.json` (statut TODO/IN_PROGRESS/DONE) sont atomiques : un seul agent écrit à la fois (verrouillage optimiste via git).

## Interruptions acceptables
- L'utilisateur peut demander à un agent de s'arrêter à tout moment.
- Une alerte Sécurité `BLOCKED` interrompt l'agent courant : il doit corriger et reprendre.
- Un échec QA Review < 80 % renvoie l'agent sur le module concerné pour corrections.
