---
description: Audite la repartition empirique des invocations agents (agent-log.txt) sur N jours et suggere redistributions selon AGENTS.md regle 14 (a-f). Invoque @manager en mode agent-redistribution-coordinator.
argument-hint: [days]
allowed-tools: Read, Grep, Bash(scripts/agent-audit.ps1:*)
---

Lance un audit de redistribution agents pour reequilibrer la charge entre les 13 agents project Espace_Opti selon la doctrine regle 14.

# Arguments

Aucun argument requis (default 7 jours) OU `<days>` int.

- `/agent-audit` -> fenetre 7j sur agent-log.txt
- `/agent-audit 30` -> fenetre 30j

# Workflow

Instructions pour @manager :

1. **Activer le role** `agent-redistribution-coordinator` (role secondaire S17)
2. Invoquer `scripts/agent-audit.ps1 -DaysWindow <N>` (lecture pure)
3. Executer le skill `.claude/skills/agent-redistribution.md` (7 steps)
4. Produire :
   - Matrice ASCII stats par agent (count START/STOP, last invoke, ratio)
   - Liste agents sous-utilises (< 5 invocations dans la fenetre)
   - Suggestions redistribution mappees aux regles 14.a-f
5. **STOP utilisateur** : presenter matrice + suggestions, demander si appliquer la doctrine sur prochaines taches
6. Logger dans `Memory/_briefs_recovered/s17-agent-redistribution-log.md`

# Garde-fous

- LECTURE PURE par construction (anti-A82 N/A, script ne write rien)
- ASCII pur dans inbox/log persistants (anti-A31)
- Anti-A105 PowerShell ($param vs variable locale, vue S16-D16 fix DOC_NOT_FOUND)
- Anti-A53 PowerShell (array+join, jamais += sur string)
- Cross-check empirique : si agent-log.txt vide ou 0 nom agent capture -> hook A102 defaillant, signaler

# Reference

- Doctrine : AGENTS.md regle 14
- Skill : `.claude/skills/agent-redistribution.md`
- Script : `scripts/agent-audit.ps1`
- Agent : `.claude/agents/manager.md` bloc `<delegation_doctrine>`

# Exemple

```
/agent-audit
-> matrice 7j, suggestions basees sur 14.a-f

/agent-audit 30
-> matrice 30j (fenetre etendue pour tendance long terme)
```
