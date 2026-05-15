# SOP-002 â€” CrÃ©ation du PRD

## Phase 1 â€” IdÃ©e brute (langage naturel)
L'utilisateur dÃ©crit son idÃ©e librement, sans structure.
Claude **reformule en 5 lignes** et demande confirmation :
> Â« Est-ce bien ceci que tu veux construire ? Â»
Si l'utilisateur dit non, Claude repose la question en s'appuyant sur la reformulation prÃ©cÃ©dente.

## Phase 2 â€” Questionnaire guidÃ©
Claude pose **exactement ces 8 questions**, une Ã  la fois, en attendant la rÃ©ponse avant la suivante :

1. **Quel est le problÃ¨me principal rÃ©solu ?**
2. **Qui sont les utilisateurs cibles ?** (personas, volume estimÃ©)
3. **Quelles sont les 3 fonctionnalitÃ©s essentielles (MVP) ?**
4. **Quelles sont les fonctionnalitÃ©s secondaires (V2) ?**
5. **Stack technique prÃ©fÃ©rÃ©e ?** (ou laisser Claude choisir)
6. **Le projet est-il B2B, B2C, ou interne ?**
7. **Quel est le dÃ©lai souhaitÃ© ?**
8. **Y a-t-il des contraintes ?** (budget, langue, accessibilitÃ©, RGPD, offlineâ€¦)

## Phase 3 â€” GÃ©nÃ©ration du PRD structurÃ©
Claude gÃ©nÃ¨re `PRD.md` avec ces sections dans cet ordre :

- **Executive Summary** (3-5 lignes)
- **User Stories** â€” format impÃ©ratif : Â« En tant que X, je veux Y, afin de Z Â»
- **Functional Requirements** â€” liste numÃ©rotÃ©e, chaque ligne testable
- **Technical Requirements** â€” stack, libs, intÃ©grations tierces
- **Architecture Constraints** â€” contraintes dures (offline, on-prem, cloudâ€¦)
- **MVP Scope** â€” ce qui est inclus / explicitement exclu
- **V2 Roadmap** â€” ordonnÃ©e par prioritÃ©
- **Success Metrics** â€” KPI mesurables

## Validation
L'utilisateur **doit valider ou modifier** `PRD.md` avant que quoi que ce soit soit codÃ©.
Un PRD non validÃ© ne dÃ©clenche **jamais** le passage Ã  SOP-003.

