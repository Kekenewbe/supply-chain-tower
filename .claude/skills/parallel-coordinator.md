---
name: parallel-coordinator
purpose: Coordonner plusieurs agents Claude Code en parallèle sans conflits
---

# Skill — Parallel Coordinator

Utilisé quand SOP-003 est déclenché : Frontend et Backend tournent simultanément dans deux terminaux.

## Modèle de coordination

### Source de vérité unique
`modules.json` est **le** fichier partagé. Il est verrouillé optimistiquement via git :
1. L'agent lit `modules.json`
2. Modifie son propre module (`status: IN_PROGRESS`)
3. Commit immédiat : `chore(modules): <agent> claim <module-id>`
4. Autres agents re-pullent avant d'écrire

En cas de conflit git sur `modules.json`, le plus ancien commit gagne ; l'autre agent rebase et refait son update.

### Règles d'isolation des fichiers
Un module a un **périmètre de fichiers déclaré** dans `modules.json` sous la clé `files_owned`. Un agent :
- **lit** librement n'importe quel fichier du projet
- **n'écrit** que dans les fichiers de son module

Violation = blocage immédiat, rollback du commit, alerte à l'utilisateur.

### Synchronisation via interfaces
Les agents communiquent **uniquement** via les contrats définis dans `ARCHITECTURE.md`. Ils ne se parlent pas directement. Un changement de contrat ne peut être initié que par l'Architecte, après validation utilisateur.

## Démarrage d'une session parallèle

```powershell
# Terminal 1
cd C:\Users\caste\Desktop\MonProjet
claude --append-system-prompt "Tu es l'agent FRONTEND. Lis _workspace/agents/frontend.md et filtre modules.json sur owner:frontend."

# Terminal 2
cd C:\Users\caste\Desktop\MonProjet
claude --append-system-prompt "Tu es l'agent BACKEND. Lis _workspace/agents/backend.md et filtre modules.json sur owner:backend."
```

## Signal de fin de module
Quand un agent termine un module :
1. Passe son statut à `DONE` dans `modules.json`
2. Commit : `feat(<module-id>): implémentation complète`
3. Pousse (si remote configuré)
4. **Arrête sa session** : QA Review prend le relais dans un 3e terminal

## Dead-man switch
Si un agent ne commit rien pendant > 20 min, considérer qu'il est bloqué.
L'utilisateur peut libérer le verrou manuellement en repassant le statut du module à `TODO`.
