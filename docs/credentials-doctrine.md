---
doctrine: credentials-cross-projet
version: 1.0
created_at: 2026-05-09
status: SPECIFICATION (implementation S10+ via #176, hook anti-leak via #178)
refs: [#176, #177, #178, A8/#95, A53]
---

# Doctrine securite credentials cross-projet

Specification de la gestion des credentials API pour TOUS les projets derives du template Espace_Opti (cf `new-project.ps1`). Cette doctrine doit etre appliquee AVANT toute implementation effective du hook post-PRD (item #176) et du hook anti-leak (item #178).

Item de reference : **#177 (HIGH)** — Definir doctrine securite credentials AVANT implementation.

---

## 1. Path de stockage canonique

Format unique impose, **hors repo git** :

```
C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt
```

Regles :

- **Hors arborescence projet** (jamais dans `<project>/`, jamais dans `Espace_Opti/`).
- **Hors User env Windows** comme stockage primaire (User env reste fallback secondaire pour partage cross-session).
- **1 fichier par projet** (isolation memoire credentials, principe de cloisonnement).
- **Repertoire `Documents/Credentials/`** pre-existe ou est cree au premier usage par `new-project.ps1` v2.
- **Encoding** : UTF-8 sans BOM strict (lecon A53).
- **Permissions OS** : par defaut User-only (NTFS ACL Windows). Pas d'override.

Exception : aucune. Tout autre path est non-conforme et doit declencher un STOP utilisateur du hook post-PRD.

---

## 2. Template structure credentials.txt

Le hook post-PRD (#176, S10+) ouvre Notepad sur ce template. L'utilisateur remplit les sections necessaires au PRD detecte, supprime celles non requises.

```
# Credentials projet {PROJECT_NAME}
# Genere : {GENERATION_DATE}
# Source doctrine : Espace_Opti/docs/credentials-doctrine.md
# Lecture : @manager seul (delegation forcee, anti-leak)

## OUTILS DETECTES DANS LE PRD
# (rempli automatiquement par new-project.ps1 v2 selon stack PRD)

OUTIL_X_API_KEY=
OUTIL_X_ENDPOINT=

## STANDARDS COMMUNS

# Obsidian Local REST API (rotation annuelle 2027-05-09)
OBSIDIAN_API_KEY=

# Pinecone (rotation annuelle 2027-04-12)
PINECONE_API_KEY=
PINECONE_INDEX={PROJECT_NAME}-memory
PINECONE_ENVIRONMENT=

# Supabase (si requis par PRD)
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE=

# GitHub (si CI/CD requis)
GITHUB_TOKEN=
GITHUB_OWNER=
GITHUB_REPO=

# Anthropic (si agents Claude API custom)
ANTHROPIC_API_KEY=

# OpenAI (si embeddings ou completions OpenAI)
OPENAI_API_KEY=

# Stripe (si paiement requis par PRD)
STRIPE_SECRET_KEY=
STRIPE_PUBLISHABLE_KEY=

## CUSTOM PROJET
# (libre, rempli par utilisateur selon besoins specifiques PRD)

CUSTOM_KEY_1=
CUSTOM_KEY_2=
```

Sections vides supprimees au moment du parse (`new-project.ps1` v2 ignore les lignes `KEY=` sans valeur).

---

## 3. Privilege minimal — lecture @manager seul

Regle imposee :

- **Seul @manager lit credentials.txt et `.env` projet** au demarrage de session.
- Les agents specialises (@frontend, @backend, @architecte, etc.) **ne lisent jamais** directement les credentials.
- @manager passe les credentials necessaires aux sous-agents **par injection contextuelle ciblee** (ex : "voici le PINECONE_API_KEY pour ce module") et JAMAIS le fichier complet.
- **Delegation forcee** : un sous-agent qui demande un credential doit passer par @manager.

Rationale : reduit la surface d'exposition (1 lecteur au lieu de N), facilite l'audit (1 seul agent a tracer), aligne avec principe least-privilege.

Anti-pattern interdit : un sous-agent qui ouvre `Read` directement sur `Documents/Credentials/...txt` ou sur `.env` non-injecte.

---

## 4. Fingerprint discipline

Quand un credential doit etre journalise (logs, banner check, debug, rapport agent), JAMAIS la cle complete. Format fingerprint impose :

```
<longueur_totale>:<5_premiers_chars>...<5_derniers_chars>
```

Exemples :

- `OBSIDIAN_API_KEY` (cle de 64 chars `abc123...xyz789`) : fingerprint = `64:abc12...xyz78`
- `PINECONE_API_KEY` (cle de 38 chars) : fingerprint = `38:pcn-A...K8s2W`
- `ANTHROPIC_API_KEY` commencant par `sk-ant-` : fingerprint = `108:sk-an...AbC9X`

Implementation banner check (deja en place via `full.ps1`) :

```powershell
$key = $env:OBSIDIAN_API_KEY
if ($key) {
    $fp = "$($key.Length):$($key.Substring(0,5))...$($key.Substring($key.Length-5))"
    Write-Host "OBSIDIAN_API_KEY ok ($fp)"
}
```

Regle : si la cle a < 10 chars, **ne pas afficher du tout** le fingerprint (risque exposition sur cles courtes type tokens partages). Loger uniquement `OBSIDIAN_API_KEY ok (short, no fingerprint)`.

---

## 5. Rotation annuelle imposee

Calendrier de rotation pre-defini (depuis `Memory/decisions.md`) :

| Cle | Premiere rotation | Cycle | Notification |
|---|---|---|---|
| `OBSIDIAN_API_KEY` | 2027-05-09 | 12 mois | Hook startup `full.ps1` 30j avant |
| `PINECONE_API_KEY` | 2027-04-12 | 12 mois | Hook startup `full.ps1` 30j avant |
| `ANTHROPIC_API_KEY` | utilisateur (geree dashboard Anthropic) | recommande 12 mois | n/a |
| Autres | utilisateur | recommande 12 mois | n/a |

Procedure rotation (a documenter S11+, item futur) :

1. Generer nouvelle cle dashboard provider (Obsidian local plugin / Pinecone console).
2. Mettre a jour `credentials.txt` (4eme source).
3. Re-run `new-project.ps1 sync-credentials --project <nom>` (script futur, propagera vers `.env` + setx User env si flag `--shared`).
4. Verifier banner `full.ps1` affiche nouvelle fingerprint.
5. Revoquer ancienne cle dashboard provider.
6. Graver decision rotation dans `Memory/decisions.md` (date + fingerprint nouvelle).

---

## 6. Sync 4 sources — coherence cross-stockage

Les credentials existent en **4 emplacements differents**, qui doivent rester synchronises :

1. **`<project>/.env`** — fichier projet, gitignore confirme. Lu au runtime par scripts/agents projet.
2. **User env Windows** (`setx VAR value`) — partage cross-session/cross-projet pour cles communes (Obsidian, Pinecone). Persistant apres reboot.
3. **`Documents/Credentials/{PROJECT_NAME}-credentials.txt`** — source de verite offline, hors repo, hors env. Reference pour rotation.
4. **Notepad runtime** (#176) — buffer ephemere lors de la creation projet ou rotation, edite puis ferme par utilisateur.

Workflow de sync impose :

- **Source de verite** : `credentials.txt` (offline, modifiable via Notepad).
- **Propagation** : `new-project.ps1` (et futur `sync-credentials.ps1`) lit `credentials.txt` et **ecrit** `.env` projet + (si flag `--shared`) `setx` User env.
- **Validation cross-source** post-sync : fingerprint compare (`.env` vs User env vs `credentials.txt`). Mismatch = STOP utilisateur immediat.
- **Notepad runtime** : buffer temporaire, ferme par user = trigger parse + ecriture des 3 autres sources.

Anti-pattern interdit : modifier directement `.env` sans propager dans `credentials.txt` (perte source de verite, drift garanti a la prochaine rotation).

---

## 7. Anti-leak hook PreToolUse (item futur #178)

Item de reference : **#178** (a creer S10+ apres #176).

Specification anticipee du hook (a implementer) :

- **Trigger** : tout `Edit` ou `Write` (PreToolUse Claude Code).
- **Scan** : contenu propose vs registre de fingerprints connus (lus depuis `credentials.txt` au demarrage agent).
- **Detection** : si une cle complete (longueur > 10, prefix matchant un fingerprint connu) apparait dans le contenu propose, **bloquer l'ecriture** + alerter @manager + grever anomalie A##.
- **Patterns OWASP** : etendre les 9 patterns deja scannes par @securite (haiku) avec :
  - prefix `sk-` (OpenAI, Anthropic)
  - prefix `pcn-` (Pinecone)
  - prefix `obsd-` (Obsidian custom)
  - longueur >= 32 chars d'un blob alphanumerique sans contexte explicatif
- **Whitelist** : `credentials.txt` lui-meme (lu hors repo) + fingerprints (5+5 chars, pas une cle complete).
- **Reporting** : grave dans `Memory/blockers.md` avec format `## YYYY-MM-DD - A## - Tentative leak {KEY_NAME}`.

Implementation : **S10+** post item #176 deploye. Reference doctrine ici pour figer la specification.

---

## Refs

- Item #176 (MEDIUM) : `new-project.ps1` v2 hook post-PRD Notepad credentials.
- Item #177 (HIGH) : doctrine credentials cross-projet (CE document).
- Item #178 (a creer S10+) : hook PreToolUse anti-leak credentials.
- Anomalie A8/#95 : lien Notepad humain inbox.
- Lecon A53 : encoding UTF-8 sans BOM strict.
- Decision 2026-05-09 : doctrine credentials Notepad post-PRD.
