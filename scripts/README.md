# scripts/ — Espace_Opti Setup Scripts

## bootstrap-espace-opti.ps1

Script de setup idempotent pour Espace_Opti sur une nouvelle machine Windows.

### Usage

```powershell
# Setup complet
.\scripts\bootstrap-espace-opti.ps1

# Sauter pip install (deps deja presentes)
.\scripts\bootstrap-espace-opti.ps1 -SkipDeps

# Sauter la verification MCPs
.\scripts\bootstrap-espace-opti.ps1 -SkipMCPs

# Lancer le dashboard apres setup
.\scripts\bootstrap-espace-opti.ps1 -LaunchDashboard

# Mode silencieux (erreurs/ok uniquement)
.\scripts\bootstrap-espace-opti.ps1 -Quiet

# Simulation sans modification
.\scripts\bootstrap-espace-opti.ps1 -WhatIf

# Combinaisons
.\scripts\bootstrap-espace-opti.ps1 -SkipDeps -SkipMCPs -Quiet
```

### Les 8 etapes

| Etape | Description | Comportement si echoue |
|-------|-------------|------------------------|
| 1 | Verification prerequis (git, python >=3.12, node >=20, npm) | EXIT 1 si prerequis manquant |
| 2 | git fetch --all --quiet | Warning + continue |
| 3 | pip install deps (requirements.txt ou fallback inline + requirements-dev.txt) | Warning + continue |
| 4 | Alias python3 (setup-python3-alias.ps1) | Warning + continue |
| 5 | $PROFILE UTF-8 : verification + proposition interactive | Warning + continue |
| 6 | MCPs user scope : pinecone + chrome-devtools (verification + instructions) | Warning + continue |
| 7 | balance-check.py --days 7 (etat workspace) | Warning + continue |
| 8 | Dashboard background (optionnel, flag -LaunchDashboard) | Warning + continue |

Seule l'etape 1 est bloquante (EXIT 1). Les etapes 2-8 emettent des warnings en cas d'echec mais continuent.

### Idempotence

Re-executer le script 3x de suite donne le meme resultat :
- Chaque etape verifie l'etat avant d'agir
- Si deja configure : message "[OK] ... No-op." et passe a l'etape suivante
- Aucune modification destructive (jamais git reset --hard, jamais overwrite $PROFILE sans confirmation)

---

## Troubleshooting

### "python introuvable" ou "python < 3.12"

1. Telecharger Python 3.12+ depuis https://www.python.org/downloads/
2. Lors de l'installation, cocher **"Add Python to PATH"**
3. Fermer et rouvrir le terminal PowerShell
4. Verifier : `python --version`

### "python3 introuvable" dans les hooks plugins

Les plugins Claude Code invoquent parfois `python3` qui n'existe pas sur Windows.
Le script appelle automatiquement `setup-python3-alias.ps1` qui cree un alias `python3.exe`.

Si l'etape 4 echoue avec une erreur de permissions :
```powershell
# Lancer PowerShell en tant qu'administrateur puis :
.\scripts\setup-python3-alias.ps1
```

### "node introuvable" ou "node < 20"

1. Telecharger Node.js 20+ (LTS) depuis https://nodejs.org/en/download/
2. Lors de l'installation, cocher **"Add to PATH"**
3. Fermer et rouvrir le terminal PowerShell
4. Verifier : `node --version`

### "MCP pinecone absent"

Le MCP Pinecone necessite une cle API. Instructions :
```powershell
# Remplacer YOUR_API_KEY par votre cle Pinecone
$env:PINECONE_API_KEY = "YOUR_API_KEY"
claude mcp add pinecone --transport sse https://mcp.pinecone.io/sse
```
Documentation : https://docs.pinecone.io/integrations/claude-mcp

### "MCP chrome-devtools absent"

```powershell
claude mcp add chrome-devtools npx @chrome-devtools/mcp-server
```

### "git fetch echoue"

Verifier la connectivite reseau et les droits d'acces au repo distant :
```powershell
git remote -v          # Verifier l'URL remote
git fetch --all        # Relancer en mode verbose
```

### $PROFILE UTF-8 — ajout manuel

Si le script n'a pas pu ajouter le snippet UTF-8 automatiquement :
```powershell
Add-Content -Path $PROFILE -Value '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'
```

---

## Autres scripts

| Script | Description |
|--------|-------------|
| `setup-python3-alias.ps1` | Cree python3.exe (copie de python.exe) pour compatibilite plugins |
| `cleanup-claude-old-binaries.ps1` | Nettoie les binaires claude.exe.old.* residuels apres auto-update echoue |
| `balance-check.py` | Analyse le ratio outillage/livraison sur 3 repos (Espace_Opti, VisualPrompt, SocialFlow) |
