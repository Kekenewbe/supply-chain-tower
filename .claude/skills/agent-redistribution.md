---
name: agent-redistribution
description: Audite la repartition empirique des invocations agents Espace_Opti via agent-log.txt et suggere redistributions selon doctrine regle 14 (a-f)
owner: manager
trigger:
  - slash: /agent-audit
  - mention_utilisateur: redistribue|audit agents|qui est sous-utilise|equilibre charge agents
  - auto: fin de session si aucune invocation @architecte/@estimateur/@optimiseur/@simplifier/@securite
created: 2026-05-15
session: S17-phase-D16bis
---

# Skill - Agent Redistribution (S17 D16-bis)

Utilise par l'agent **Manager** dans son role de garant doctrine regle 14 (matching agent-tache).

Doctrine gravee : AGENTS.md regle 14 + bloc `<delegation_doctrine>` dans `.claude/agents/manager.md`.

Pendant que cross-project-propagation (S15) propage HORS du repo et que internal-sync (S16) aligne la doc interne, agent-redistribution opere INTRA-SESSION : il equilibre la charge entre agents selon les types de taches detectees, evitant la derive ou @manager traite manuellement ce qu'un agent specialise ferait mieux.

## Quand declencher

- L'utilisateur lance `/agent-audit` (avec ou sans fenetre temporelle explicite)
- L'utilisateur ecrit "redistribue", "audit agents", "qui est sous-utilise", "equilibre charge agents"
- Auto fin de session : aucune invocation @architecte/@estimateur/@optimiseur/@simplifier/@securite detectee dans agent-log.txt
- Drift cumule confirme Phase 0.5 S17 : pattern sous-utilisation chronique @estimateur/@optimiseur/@simplifier constate sur S13-S16

## Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `days` | int | 7 | Fenetre temporelle d'analyse (note : limitation HH:MM:SS dans agent-log actuel, cf Step 5) |
| `log-path` | string | .claude/agent-log.txt | Path vers agent-log.txt post-A102 fix |
| `threshold-sous-util` | int | 5 | Seuil invocations START en dessous duquel un agent est marque SOUS-UTILISE |
| `dry-run` | bool | true | LECTURE PURE par construction (dry-run N/A, jamais d'ecriture disque) |

## Auto-detection severity

Mapping type de tache vers agent recommande selon doctrine regle 14 :

| Type de tache | Agent recommande | Regle | Modele | Priorite |
|---|---|---|---|---|
| Estimation avant tache > 15min ou > 5 fichiers | @estimateur | 14.a | Haiku | HAUTE |
| Cross-check post-delegation (verification claim sous-agent) | @optimiseur | 14.b | Sonnet | HAUTE |
| Audit qualite multi-axes (score < 80 bloquant) | @qa-review | 14.c | Opus | HAUTE |
| Refactor post-implementation (post QA >= 80) | @simplifier | 14.d | Sonnet | MOYENNE |
| Tests E2E (plan, generation, reparation) | trio playwright-test | 14.e | Sonnet | MOYENNE |
| Scripts > 50 lignes PS/Python | @backend | 14.f | Sonnet | HAUTE |

## Steps (workflow obligatoire)

### Step 1 - Audit empirique agent-log.txt (post-A102 fix)

Verifier existence et format du log :
```powershell
Test-Path '.claude\agent-log.txt'
Get-Content '.claude\agent-log.txt' -TotalCount 5
```

Format attendu post-A102 (hook log-subagent-start.ps1 / log-subagent-stop.ps1) :
```
[AGENT START] HH:MM:SS - Agent: <name> demarre
[AGENT STOP]  HH:MM:SS - Agent: <name> termine
```

Si log absent ou format pre-A102 detecte (absence de "Agent:") : signaler hook defaillant dans output.

Limitation connue : timestamps agent-log = HH:MM:SS uniquement (pas de date). La fenetre `-days` ne peut pas filtrer par jour reel. Le script compte le total cumule du fichier et documente cette limitation dans l'output.

### Step 2 - Invoquer scripts/agent-audit.ps1

```powershell
.\scripts\agent-audit.ps1 `
  -DaysWindow 7 `
  -AgentLogPath '.claude\agent-log.txt' `
  -SousUtilThreshold 5
```

Lecture pure. Le script parse agent-log.txt et produit la matrice stats par agent.
Mode JSON disponible pour traitement programme :
```powershell
.\scripts\agent-audit.ps1 -JsonOutput
```

### Step 3 - Mapping tache -> agent selon table regles 14.a-f

Croiser la matrice agent-audit avec le journal Memory/journal.md (derniers 7j) :
- Identifier les types de taches traitees lors de la periode
- Pour chaque tache retrouvee sans invocation de l'agent recommande -> signaler derive

Exemple de derive detecte :
```
[DRIFT] Tache 'estimation refactor auth' sans @estimateur -> regle 14.a violee
[DRIFT] Script propagate-fix.ps1 (> 50L) redige sans @backend -> regle 14.f violee
```

### Step 4 - Suggestions justifiees empiriquement

Pour chaque agent SOUS-UTILISE dans la matrice :
1. Citer la regle 14.x applicable
2. Donner 1-2 exemples concrets de taches passees ou l'agent aurait du etre invoque
3. Formuler une suggestion actionnable pour la prochaine session

Format suggestion :
```
[SUGGESTION] @estimateur (14.a) : 0 invocations sur 7j.
  Taches candidates retrouvees dans journal.md :
  - 2026-05-14 : "refactor agent-redistribution" (> 15min) -> @estimateur aurait du etre invoque
  Action : invoquer @estimateur AVANT toute tache > 15min ou > 5 fichiers des la prochaine session
```

### Step 5 - Application doctrine + monitoring continu

Post-audit, @manager integre les suggestions dans son comportement INTRA-SESSION :
- Avant toute tache > 15min : verifier reflexe @estimateur (regle 14.a)
- Apres delegation : cross-check empirique via @optimiseur (regle 14.b)
- Apres implementation module : @qa-review obligatoire si score unknown (regle 14.c)

Monitoring via hooks A102-fixed : agent-log.txt se met a jour automatiquement a chaque SubagentStart/SubagentStop. Re-invoquer /agent-audit en cours de session si nouveau drift suspect.

### Step 6 - Output matrice ASCII Markdown

Format de sortie standard (ASCII pur, anti-A31) :

```
| Agent        | Count START | Count STOP | Last invocation | Status       | Suggestion              |
|--------------|------------:|-----------:|-----------------|--------------|-------------------------|
| @estimateur  |           0 |          0 | (jamais)        | SOUS-UTILISE | Invoquer 14.a > 15min   |
| @optimiseur  |           2 |          2 | 14:32:01        | OK           | -                       |
| @qa-review   |           1 |          1 | 11:05:47        | OK           | -                       |
| @simplifier  |           0 |          0 | (jamais)        | SOUS-UTILISE | Invoquer 14.d post-QA80 |
| @backend     |           5 |          5 | 15:48:22        | OK           | -                       |
| @frontend    |           3 |          3 | 10:21:15        | OK           | -                       |
| @architecte  |           1 |          1 | 09:15:03        | OK           | -                       |
| @securite    |           8 |          8 | 16:01:44        | OK           | (auto hook)             |
| @playwright  |           0 |          0 | (jamais)        | OK           | Phase livraison seult   |
```

Note : @securite et @playwright peuvent afficher Count 0 sans etre SOUS-UTILISES (declencheurs specifiques).

### Step 7 - Log persistant

Ecrire/appender dans `Memory/_briefs_recovered/s17-agent-redistribution-log.md` :
```
## Agent-audit <date> - fenetre <N>j - threshold <T>

| Agent | Count START | Count STOP | Status | Suggestion |
|---|---|---|---|---|
| @estimateur | 0 | 0 | SOUS-UTILISE | Invoquer 14.a |

Drifts detectes : <N>
Suggestions actionables : <liste>
Limitation log : HH:MM:SS uniquement, fenetre days N/A sans date complete.
```

## Outputs attendus

1. **Matrice agents** (tableau ASCII inline dans le rapport terminal)
2. **Suggestions redistribution** (liste actionable par agent SOUS-UTILISE avec regle 14.x citee)
3. **Log persistant** `Memory/_briefs_recovered/s17-agent-redistribution-log.md`
4. **Signal hook A102 defaillant** si agent-log absent ou format pre-A102 detecte (lignes sans "Agent:")

## Garde-fous

- ASCII pur dans tous les fichiers persistes (anti-A31)
- PowerShell : array `@()` + `-join`, jamais `+=` sur string (anti-A53)
- Anti-A105 CRITIQUE : noms parametres EXPLICITES dans scripts, ne JAMAIS reutiliser $DaysWindow/$AgentLogPath/$SousUtilThreshold comme variables locales (PowerShell case-insensitive coerce silencieusement Object[] -> [string])
- LECTURE PURE par construction : ce skill ne declenche jamais d'ecriture disque autre que le log persistant (anti-A82 N/A)
- Hook resilient : try/catch global dans scripts invoquees (exit 0 propre meme si agent-log absent)
- Ne JAMAIS marquer @securite SOUS-UTILISE si count = 0 (declenchement auto via hook PreToolUse)
- Ne JAMAIS marquer @playwright SOUS-UTILISE si count = 0 hors phase livraison

## Reference croisee

- Doctrine source : `AGENTS.md` regle 14, bloc `<delegation_doctrine>` dans `.claude/agents/manager.md`
- Slash command : `/agent-audit`
- Script d'execution : `scripts/agent-audit.ps1` (parse agent-log.txt, lecture pure)
- Skills voisins :
  - `.claude/skills/cross-project-propagation.md` (S15 -- propagation hors repo)
  - `.claude/skills/internal-sync.md` (S16 -- alignement doc interne)
- A102 fix : hooks `.claude/hooks/log-subagent-start.ps1` + `log-subagent-stop.ps1`
- Drift historique : sessions S13-S16 confirment sous-utilisation chronique @estimateur/@optimiseur/@simplifier
