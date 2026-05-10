---
description: Lance le workflow complet de création de PRD selon SOP-002. Trois phases — reformulation, questionnaire 8 questions, génération PRD.md structuré. Attend la validation utilisateur avant de terminer.
---

Lance le workflow SOP-002 — Création du PRD pour le projet : $ARGUMENTS

Étape 1 — Si `$ARGUMENTS` est vide, demande à l'utilisateur de décrire librement son idée.

Étape 2 — Reformule l'idée en maximum 5 lignes claires et demande : « Est-ce bien cela que tu veux construire ? »

Étape 3 — Si confirmé, pose ces 8 questions **une par une** en attendant la réponse avant de poser la suivante :
1. Quel est le problème principal résolu ?
2. Qui sont les utilisateurs cibles ? (personas, volume estimé)
3. Quelles sont les 3 fonctionnalités essentielles du MVP ?
4. Quelles sont les fonctionnalités secondaires pour la V2 ?
5. Quelle stack technique ? (ou laisser Claude choisir)
6. Le projet est-il B2B, B2C, ou interne ?
7. Quel est le délai souhaité ?
8. Y a-t-il des contraintes ? (budget, langue, accessibilité, RGPD, offline…)

Étape 4 — Génère `PRD.md` en utilisant le template `_workspace/prd-template.md` avec toutes les sections complètes.

Étape 5 — Affiche `PRD.md` et demande : « Valides-tu ce PRD pour démarrer l'architecture ? »

Étape 6 — **Ne passer à aucune autre action avant la validation explicite de l'utilisateur.**
