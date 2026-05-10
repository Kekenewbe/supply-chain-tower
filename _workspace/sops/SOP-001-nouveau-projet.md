# SOP-001 — Lancer un nouveau projet

## Déclencheur
L'utilisateur tape :
```powershell
.\new-project.ps1 "NomDuProjet"
```

## Étapes
1. **Copie** de `Espace_Opti/` → `C:\Users\caste\Desktop\{NomDuProjet}\`
   (exclusions : `graphify-out/`, `.env`, `.git/`, `node_modules/`, `new-project.ps1`).
2. **Initialisation Git** dans le nouveau dossier : `git init`.
3. **Mise à jour de `CLAUDE.md`** : remplace toute mention "Espace_Opti" par `{NomDuProjet}`.
4. **Génération de `.env`** à partir de `.env.template` (placeholders, jamais de vraies clés).
5. **Création d'un dossier `graphify-out/` vide** pour accueillir le futur graphe AST.
6. **Lancement du module PRD** (SOP-002) à l'ouverture de Claude Code dans le nouveau dossier.
7. **Attente de validation utilisateur** avant toute génération de code.

## Règles
- **Ne jamais modifier `Espace_Opti/` directement.** C'est le template canonique.
- Chaque projet a **son propre index Pinecone isolé** : `{nom-projet}-memory`. Le script `sync_memory.py` doit lire le nom depuis `CLAUDE.md` ou une variable d'environnement `PROJECT_NAME`.
- `CLAUDE.md` doit refléter le nom du projet dès la copie (pas d'incohérence résiduelle).
- Le dossier `_workspace/` est **copié tel quel** : les agents, SOPs et skills sont disponibles immédiatement dans le nouveau projet.
