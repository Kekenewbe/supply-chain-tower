# SOP-001 â€” Lancer un nouveau projet

## DÃ©clencheur
L'utilisateur tape :
```powershell
.\new-project.ps1 "NomDuProjet"
```

## Ã‰tapes
1. **Copie** de `Espace_Opti/` â†’ `C:\Users\caste\Desktop\supply-chain-tower\`
   (exclusions : `graphify-out/`, `.env`, `.git/`, `node_modules/`, `new-project.ps1`).
2. **Initialisation Git** dans le nouveau dossier : `git init`.
3. **Mise Ã  jour de `CLAUDE.md`** : remplace toute mention "Espace_Opti" par `supply-chain-tower`.
4. **GÃ©nÃ©ration de `.env`** Ã  partir de `.env.template` (placeholders, jamais de vraies clÃ©s).
5. **CrÃ©ation d'un dossier `graphify-out/` vide** pour accueillir le futur graphe AST.
6. **Lancement du module PRD** (SOP-002) Ã  l'ouverture de Claude Code dans le nouveau dossier.
7. **Attente de validation utilisateur** avant toute gÃ©nÃ©ration de code.

## RÃ¨gles
- **Ne jamais modifier `Espace_Opti/` directement.** C'est le template canonique.
- Chaque projet a **son propre index Pinecone isolÃ©** : `{nom-projet}-memory`. Le script `sync_memory.py` doit lire le nom depuis `CLAUDE.md` ou une variable d'environnement `PROJECT_NAME`.
- `CLAUDE.md` doit reflÃ©ter le nom du projet dÃ¨s la copie (pas d'incohÃ©rence rÃ©siduelle).
- Le dossier `_workspace/` est **copiÃ© tel quel** : les agents, SOPs et skills sont disponibles immÃ©diatement dans le nouveau projet.

