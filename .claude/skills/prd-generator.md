---
name: prd-generator
purpose: Template + instructions pour générer un PRD structuré en suivant SOP-002
---

# Skill — PRD Generator

## Quand l'utiliser
- À l'ouverture d'un nouveau projet après `new-project.ps1`
- Quand l'utilisateur dit « je veux construire … » sans plan écrit
- Relancé par SOP-001 étape 6

## Ordre d'exécution
1. Lire `_workspace/sops/SOP-002-creation-prd.md`
2. Suivre **strictement** les 3 phases (reformulation → questionnaire → génération)
3. Utiliser le template ci-dessous pour la phase 3
4. Écrire le résultat dans `PRD.md` à la racine du projet
5. Demander validation utilisateur **avant** toute autre action

## Template du PRD (phase 3)

```markdown
# PRD — {NomDuProjet}

> **Statut :** Draft | **Date :** YYYY-MM-DD | **Auteur :** {user}

## Executive Summary
<3-5 lignes qui résument le problème, la solution et le public cible.>

## User Stories
- En tant que {persona}, je veux {action}, afin de {bénéfice}.
- …

## Functional Requirements
1. FR-01 — <exigence testable>
2. FR-02 — …

## Technical Requirements
- Stack : <frontend / backend / DB>
- Intégrations tierces : <stripe, auth0, …>
- Contraintes de perf : <latence, throughput, …>

## Architecture Constraints
- <offline-first, on-prem, multi-tenant, …>

## MVP Scope
**Inclus :**
- …

**Exclu :**
- …

## V2 Roadmap
1. <feature prioritaire>
2. …

## Success Metrics
- <KPI mesurable, ex: 95 % des logins réussissent en < 200 ms>
```

## Règles dures
- Ne jamais inventer de réponses aux 8 questions : toujours demander à l'utilisateur.
- Ne jamais passer à SOP-003 sans validation écrite du PRD.
- Un PRD généré sans les 8 réponses est invalide et doit être re-drafté.
