# Contribuer a supply-chain-tower

## Standard de commits (Conventional Commits)

Tous les messages de commit DOIVENT suivre la specification
[Conventional Commits](https://www.conventionalcommits.org/).

Format :

```
type(scope): description
```

La validation est **automatique** via un hook `commit-msg` (husky + commitlint).
Un commit dont le message ne respecte pas le format est **rejete** avant creation.

### Types autorises

| Type     | Usage                                                        |
|----------|-------------------------------------------------------------|
| feat     | Nouvelle fonctionnalite                                      |
| fix      | Correction de bug                                            |
| docs     | Documentation uniquement                                     |
| style    | Formatage, point-virgule, etc. (pas de changement logique)  |
| refactor | Refactorisation sans changement de comportement             |
| perf     | Amelioration de performance                                  |
| test     | Ajout ou correction de tests                                 |
| build    | Build system, dependances                                   |
| ci       | Configuration CI/CD                                          |
| chore    | Maintenance, outillage, taches diverses                     |
| revert   | Annulation d'un commit precedent                            |

### Scopes usuels du projet

`backend`, `frontend`, `api`, `db`, `auth`, `ci`, `tooling`, `docs`, `scripts`.

### Exemples valides

```
feat(api): ajout endpoint /shipments/status
fix(db): corrige index manquant sur orders.created_at
chore(tooling): setup commitlint + husky release-please
docs(readme): mise a jour section deployment
```

### Exemple rejete

```
update stuff            # pas de type, rejete
Fixed the bug           # pas de format type(scope):, rejete
```

### Regles assouplies pour ce projet

- `subject-case` desactive : les acronymes, references et noms propres sont
  autorises dans la description.
- `header-max-length` porte a 120 caracteres (sujets descriptifs).
- `body-max-line-length` et `footer-max-line-length` desactives : les bodies
  peuvent etre descriptifs sur plusieurs lignes.

Configuration : `commitlint.config.js`.

## Setup local

Apres un `git clone`, installer les dependances pour activer le hook :

```bash
npm install
```

Le script `prepare` (npm) active husky automatiquement. Le hook
`.husky/commit-msg` valide chaque message via commitlint.
