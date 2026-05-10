---
description: Lance @manager pour orchestrer un projet complet de A à Z. Le manager gère automatiquement PRD → Architecture → Dev → QA → Livraison avec 3 niveaux d'autonomie. Tu n'interviens que sur les décisions stratégiques.
---

Lance l'orchestration complète du projet par @manager.

Idée ou description du projet : $ARGUMENTS

Instructions pour @manager :
1. Lire l'état actuel du projet (modules.json, PRD.md, CLAUDE.md, agent-log.txt)
2. Déterminer la phase actuelle : INIT / ARCHITECTURE / DEVELOPPEMENT / VALIDATION / LIVRAISON
3. Reprendre à la bonne phase ou démarrer depuis le début si nouveau projet
4. Appliquer les 3 niveaux d'autonomie définis dans ta définition
5. Ne jamais bloquer sans expliquer clairement ce qui est attendu de l'utilisateur

Si $ARGUMENTS est vide → demander à l'utilisateur de décrire son projet.
Si PRD.md existe déjà → résumer l'état actuel et demander si on reprend ou repart de zéro.
