# SCHEMA — Format des entrées Memory/

## Champs obligatoires (toutes entrées)

- **Date** : YYYY-MM-DD format ISO
- **Scope** : un parmi {transverse, espace_opti, vp, socialflow, supply_chain_tower}
- **Tags Obsidian** : #<registre> #<scope> + tags spécifiques

## Schéma par registre

### decisions.md

```markdown
## YYYY-MM-DD — <Titre court de la décision>

- **Scope** : <scope>
- **Tags** : #decision #<scope> #<sous-domaine>
- **Contexte** : pourquoi cette décision se pose maintenant
- **Alternatives considérées** : option A / option B / option C
- **Décision** : option retenue + 1-3 phrases de justification
- **Conséquences attendues** : ce qui change après
- **Liens** : [[#<id-backlog>]] [[A<code-anomalie>]] [[<commit-hash>]]
```

### learnings.md

```markdown
## YYYY-MM-DD — <Titre court du learning>

- **Scope** : <scope>
- **Tags** : #learning #<scope> #<sous-domaine>
- **Contexte** : situation où le learning a émergé
- **Approach (ce qui a été essayé)** : description
- **Outcome (ce qui s'est passé)** : succès / échec / résultat mesurable
- **Pattern dégagé** : généralisation applicable au-delà du cas
- **Sources** : commits, articles, RFC, etc.
```

### blockers.md

```markdown
## YYYY-MM-DD — <Code A##> — <Symptôme court>

- **Scope** : <scope>
- **Tags** : #blocker #<scope> #recurrence-<n>
- **Première occurrence** : YYYY-MM-DD
- **Récurrences** : (compteur, incrémenté à chaque retour)
- **Symptôme observé** : ce qu'on voit
- **Cause racine** : ce qui le provoque vraiment
- **Mitigation actuelle** : workaround en place
- **Mitigation cible** : solution structurelle (item backlog si applicable)
- **Coût cumulé** : estimation (min ou occurrences)
- **Statut** : OPEN / MITIGATED / RESOLVED
```

### journal.md

```markdown
## YYYY-MM-DD — <Session label>

- **Scope** : <scopes touchés, peut être plusieurs>
- **Tags** : #journal-entry #<scope-principal>
- **Durée session** : ~Xh
- **Projets touchés** : liste
- **Résumé** : 3-5 lignes
- **Commits** : liste hashes courts + sujets
- **Items déplacés** : (résolus / nouveaux / repriorisés)
- **Anomalies observées** : (nouvelles A##)
- **À faire prochaine session** : note rapide
```

### evals.md

```markdown
## YYYY-MM-DD — <Agent / IA concerné> — <Type drift>

- **Scope** : <scope>
- **Tags** : #eval #<scope> #<agent-name>
- **Agent** : claude.ai / @manager / @playwright / @frontend / etc.
- **Type** : hallucination / silent-divergence / scope-creep / outdated / autre
- **Description** : ce qui s'est passé
- **Impact** : consequences (mineure / majeure / bloquante)
- **Correction appliquée** : comment résolu cette fois
- **Mitigation future** : règle à graver pour éviter récurrence
```

### backlog.md (snapshots)

```markdown
## Snapshot YYYY-MM-DD HH:mm

- **Scope** : transverse
- **Tags** : #backlog-snapshot
- **Items actifs (en cours)** : (liste)
- **Items résolus depuis dernier snapshot** : (liste)
- **Items repriorisés** : (liste)
- **Nouveaux items** : (liste)
```

## Conventions de nommage

- Anomalies : A1, A2, ..., A2-bis, A24-bis (codes assignés en conv Claude.ai)
- Items backlog Espace_Opti : #15, #23, etc. (numérotation conv Claude.ai)
- Items backlog VP : W1, W2, ..., W23
