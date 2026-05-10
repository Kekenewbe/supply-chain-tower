---
description: Démarre le développement d'un module spécifique ou de tous les modules TODO. Lance l'Architecte si modules.json n'existe pas, sinon lance Frontend et/ou Backend selon le ownership. L'agent Sécurité surveille automatiquement.
---

Lance le développement du module : $ARGUMENTS

1. Vérifier si `PRD.md` existe — sinon lancer `/start-prd` d'abord
2. Vérifier si `modules.json` existe et contient des modules
3. Si `modules.json` n'existe pas : invoquer `@architecte` pour décomposer le PRD en modules. Attendre la validation utilisateur de `ARCHITECTURE.md` avant de continuer.
4. Si `$ARGUMENTS` est un nom de module spécifique : filtrer `modules.json` sur cet id
5. Si `$ARGUMENTS` est vide : lister tous les modules avec `status: TODO`
6. Pour les modules `owner:frontend` → invoquer `@frontend` (isolation worktree automatique)
7. Pour les modules `owner:backend` → invoquer `@backend` (isolation worktree automatique)
8. Rappeler que `@securite` surveille automatiquement chaque écriture
9. Quand un module passe `DONE` → invoquer automatiquement `@qa-review`
