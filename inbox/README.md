# Inbox System — Communication asynchrone utilisateur <-> Claude Code

## Role

Cette inbox est le canal d'echange asynchrone entre l'utilisateur et Claude Code (et ses agents) pour ce projet.

- L'utilisateur depose des briefs, decisions, ou demandes dans `current.md`.
- Claude Code lit `current.md` au demarrage de session, execute, archive si pertinent.
- Les briefs traites sont deplaces dans `archive/AAAA-MM-JJ-N-slug.md` pour traçabilite.

## Convention de nommage des archives

Format : `AAAA-MM-JJ-N-slug.md`

- `AAAA-MM-JJ` : date de l'archive (jour ou Claude termine)
- `N` : index du jour (1, 2, 3...) si plusieurs briefs le meme jour
- `slug` : identifiant court en kebab-case (ex: `pre-systeme`, `phase1-quick-wins`, `inbox-rollout`)

Exemple : `2026-04-30-1-pre-systeme.md`, `2026-05-01-1-feature-auth.md`

## Usage quotidien

### Cote utilisateur

1. Editer `inbox/current.md` (ou utiliser `scripts/inbox-write.ps1` pour ajout horodate UTF-8 sans BOM).
2. Mentionner explicitement les ETAPES OBLIGATOIRES, l'AUTONOMIE deleguee, et les GARDE-FOUS.
3. Lancer ou rejoindre la session Claude Code.

### Cote Claude

1. Au demarrage : lire `inbox/current.md` integralement.
2. Si brief actif : executer en respectant les regles globales et projet.
3. En fin de session : archiver via `scripts/inbox-archive.ps1` (ou manuellement).
4. Statut : `scripts/inbox-status.ps1` pour vue d'ensemble.

## Garde-fous

- `current.md` versionne ou local-only au choix. Par defaut versionne (traçabilite).
- `archive/` toujours versionne (historique decisions).
- Encodage : UTF-8 sans BOM (utiliser `inbox-write.ps1`, jamais Notepad).
- Pas de secrets en clair (cles API, tokens). En cas de doute : `.env`.

## Scripts associes (dans `scripts/`)

| Script | Usage |
|--------|-------|
| `inbox-write.ps1` | Ajoute un message horodate a `current.md` |
| `inbox-archive.ps1` | Archive `current.md` vers `archive/` avec slug |
| `inbox-status.ps1` | Vue d'ensemble : taille `current.md`, dernieres archives |

## Voir aussi

- `docs/inbox-system.md` : architecture detaillee, flux complet, exemples.
- `CLAUDE.md` (racine) : reference vers `inbox/current.md` dans les regles projet.
