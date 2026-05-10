# SOP-002 — Création du PRD

## Phase 1 — Idée brute (langage naturel)
L'utilisateur décrit son idée librement, sans structure.
Claude **reformule en 5 lignes** et demande confirmation :
> « Est-ce bien ceci que tu veux construire ? »
Si l'utilisateur dit non, Claude repose la question en s'appuyant sur la reformulation précédente.

## Phase 2 — Questionnaire guidé
Claude pose **exactement ces 8 questions**, une à la fois, en attendant la réponse avant la suivante :

1. **Quel est le problème principal résolu ?**
2. **Qui sont les utilisateurs cibles ?** (personas, volume estimé)
3. **Quelles sont les 3 fonctionnalités essentielles (MVP) ?**
4. **Quelles sont les fonctionnalités secondaires (V2) ?**
5. **Stack technique préférée ?** (ou laisser Claude choisir)
6. **Le projet est-il B2B, B2C, ou interne ?**
7. **Quel est le délai souhaité ?**
8. **Y a-t-il des contraintes ?** (budget, langue, accessibilité, RGPD, offline…)

## Phase 3 — Génération du PRD structuré
Claude génère `PRD.md` avec ces sections dans cet ordre :

- **Executive Summary** (3-5 lignes)
- **User Stories** — format impératif : « En tant que X, je veux Y, afin de Z »
- **Functional Requirements** — liste numérotée, chaque ligne testable
- **Technical Requirements** — stack, libs, intégrations tierces
- **Architecture Constraints** — contraintes dures (offline, on-prem, cloud…)
- **MVP Scope** — ce qui est inclus / explicitement exclu
- **V2 Roadmap** — ordonnée par priorité
- **Success Metrics** — KPI mesurables

## Validation
L'utilisateur **doit valider ou modifier** `PRD.md` avant que quoi que ce soit soit codé.
Un PRD non validé ne déclenche **jamais** le passage à SOP-003.
