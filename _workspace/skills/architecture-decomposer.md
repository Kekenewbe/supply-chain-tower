---
name: architecture-decomposer
purpose: Découper un PRD validé en modules indépendants codables en parallèle
---

# Skill — Architecture Decomposer

Utilisé par l'agent **Architecte** pour produire `modules.json` et `ARCHITECTURE.md`.

## Heuristiques de découpe

### 1. Un module = une responsabilité
Si tu peux décrire un module avec une seule phrase sans "et", c'est bon signe.
Mauvais : "Gestion des utilisateurs et des paiements".
Bon : "Authentification (login, logout, refresh token)".

### 2. Axe de découpe prioritaire : les frontières de données
Un module possède **ses** tables / ses endpoints. Deux modules qui se partagent une table sont un smell — probablement un seul module mal découpé.

### 3. Parallélisable = indépendant
Un module est parallélisable s'il peut être implémenté **sans attendre** un autre module. Le seul couplage admis est via les **contrats d'interface** (schémas, types, endpoints) définis en amont.

### 4. Un module `fullstack` doit être scindé
Si une fonctionnalité touche à la fois UI et API, produire **deux modules** (un `frontend`, un `backend`) avec un contrat explicite entre eux.

## Format de sortie : `modules.json`

```json
{
  "project": "{NomDuProjet}",
  "generated_at": "YYYY-MM-DD",
  "modules": [
    {
      "id": "auth-backend",
      "owner": "backend",
      "depends_on": [],
      "interface": {
        "endpoints": [
          "POST /auth/login -> { token: string, refresh: string }",
          "POST /auth/refresh -> { token: string }"
        ],
        "tables": ["users", "refresh_tokens"]
      },
      "status": "TODO"
    },
    {
      "id": "auth-frontend",
      "owner": "frontend",
      "depends_on": ["auth-backend"],
      "interface": {
        "components": ["LoginForm", "LogoutButton"],
        "pages": ["/login"]
      },
      "status": "TODO"
    }
  ]
}
```

## Format de sortie : `ARCHITECTURE.md`
- **Diagramme textuel** des modules et leurs dépendances (ASCII ou mermaid)
- **Contrats d'interface** complets (types TS, schémas JSON, SQL des tables)
- **Ordre d'exécution** (DAG topologique)
- **Risques identifiés** et mitigations proposées
