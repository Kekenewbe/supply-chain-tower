---
description: Lance une tache recurrente sur une duree definie. Le manager execute la tache puis attend l intervalle specifie avant de recommencer. Utile pour monitoring, polling builds, surveillance deployments. Maximum 72 heures.
---

Lance une tache recurrente.

Arguments : $ARGUMENTS

Format attendu : [intervalle] [tache]

Exemples :
  /loop 30m verifier que les tests passent toujours
  /loop 1h surveiller le build et alerter si echec
  /loop 15m verifier le statut des modules et mettre a jour
  /loop 5m poller le dashboard de deploiement

Intervalles supportes :
- Ns  = N secondes (minimum 30s)
- Nm  = N minutes
- Nh  = N heures
- Nd  = N jours (maximum 3 jours = 72h)

Instructions pour @manager :

1. Parser $ARGUMENTS :
   - Premier token = intervalle (ex: 30m, 1h, 2d)
   - Reste = description de la tache
   - Si intervalle absent ou invalide -> demander clarification et stopper
   - Si duree totale > 72h -> refuser et expliquer la limite

2. Convertir l intervalle en secondes :
   - 30s -> 30
   - 15m -> 900
   - 1h  -> 3600
   - 2d  -> 172800

3. Executer la tache une premiere fois immediatement.

4. Apres chaque execution :
   - Afficher un rapport court : heure, statut, resultat en 3 lignes max
   - Logger l iteration via claude-mem (capture automatique par le plugin)
   - Annoncer le prochain check : "Prochain check dans X minutes"

5. Attendre l intervalle via `Bash sleep <seconds>`.

6. Recommencer l execution jusqu a :
   - Interruption explicite utilisateur (Ctrl+C ou message stop)
   - Atteinte de la limite 72h
   - Echec critique de la tache (3 echecs consecutifs)

7. A la fin ou en cas d arret :
   - Ecrire un resume global : N iterations, M succes, P echecs
   - Mettre a jour .claude/agent-memory/manager/MEMORY_PROJECT.md
     avec le pattern decouvert

Regles dures :
- Maximum 72 heures de boucle - stopper automatiquement apres
- Maximum 3 echecs consecutifs - stopper et alerter l utilisateur
- Minimum 30 secondes d intervalle - refuser en dessous (sinon spam)
- Toujours logger chaque iteration via claude-mem (automatique)
- Respecter les niveaux d autonomie du manager pendant la boucle
- Ne jamais faire de commit ou git push sans validation utilisateur
