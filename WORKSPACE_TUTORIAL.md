# Tutoriel — Espace_Opti : Utilisation au quotidien

Ce guide explique comment exploiter ton atelier IA `Espace_Opti` au jour le jour : lancer l'environnement, interroger la mémoire, déclencher les agents, et enchaîner un workflow complet de création de feature.

> **Pré-requis** : l'installation est terminée. Les clés `OBSIDIAN_API_KEY`, `PINECONE_API_KEY`, `OPENAI_API_KEY` et `OBSIDIAN_BASE_URL` sont définies en variables d'environnement Windows. Obsidian est lancé avec l'extension **Local REST API** active sur le port `27124`.

---

## 1. Lancer l'espace de travail

### 1.1 Démarrer Claude Code

Ouvre un terminal **dans le dossier du projet** (via VS Code : `Terminal → New Terminal` garantit que le CWD est bon) puis lance :

```bash
cd c:/Users/caste/Desktop/Espace_Opti
claude
```

Claude Code lit automatiquement :
- `.claude/settings.json` (MCP servers + hooks)
- `CLAUDE.md` (instructions projet, règles Graphify)
- Le memory system global (`~/.claude/projects/.../memory/MEMORY.md`)

### 1.2 Vérifier les serveurs MCP

À l'intérieur de la session Claude, tape :

```
/mcp
```

Tu dois voir **les deux serveurs connectés** :

| Serveur   | État attendu | Outils exposés                                              |
|-----------|--------------|-------------------------------------------------------------|
| `obsidian`  | `connected` | `obsidian_read_note`, `obsidian_update_note`, `obsidian_global_search`, `obsidian_list_notes`, `obsidian_manage_frontmatter`, `obsidian_manage_tags`, `obsidian_search_replace`, `obsidian_delete_note` |
| `pinecone`  | `connected` | `search-records`, `upsert-records`, `list-indexes`, `describe-index`, `describe-index-stats`, `create-index-for-model`, `search-docs`, `rerank-documents`, `cascading-search` |

Si un serveur est `failed`, la cause la plus fréquente est une variable d'environnement non propagée : **ferme complètement VS Code et relance-le** (les `setx` ne se propagent pas aux processus déjà ouverts).

### 1.3 Vérifier Graphify

```bash
python -m graphify hook status
```

Et inspecte l'existence du rapport :

```bash
ls graphify-out/
# Tu dois voir : GRAPH_REPORT.md, graph.json, wiki/
```

Le hook `PreToolUse` configuré dans `.claude/settings.json` injecte automatiquement un rappel à Claude pour qu'il consulte `GRAPH_REPORT.md` **avant** toute recherche `Glob` ou `Grep`.

---

## 2. Graphify — Comprendre la topologie du code

Graphify construit un **graphe AST déterministe** du code (via tree-sitter + clustering Leiden). Il remplace les coûteux `grep` aveugles par une carte topologique que Claude peut lire en quelques centaines de tokens.

### 2.1 Mécanique automatique

Chaque fois que Claude s'apprête à lancer un `Glob` ou un `Grep`, le hook déclenche un message système qui l'oblige à lire d'abord [graphify-out/GRAPH_REPORT.md](graphify-out/GRAPH_REPORT.md). Tu n'as **rien à faire** : cette étape est transparente.

### 2.2 Régénérer manuellement le graphe

Après un ensemble de modifications importantes :

```bash
python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Pour vérifier que le hook est bien enregistré :

```bash
python -m graphify hook status
```

### 2.3 Lire `GRAPH_REPORT.md`

Le rapport contient plusieurs sections clés :

- **Corpus Check** — nombre de fichiers analysés et verdict de pertinence.
- **God Nodes** — les abstractions **les plus connectées** du projet. Ce sont les fonctions/classes où passent le plus de dépendances : les modifier impacte beaucoup de code. Exemple actuel : `main()` dans `sync_memory.py` avec 5 arêtes.
- **Communities** — regroupements détectés par l'algorithme **Leiden**. Deux nœuds dans la même communauté sont fortement couplés. Touche à l'un = pense aux autres de la même communauté.
- **Surprising Connections** — liens que l'algorithme a identifiés et que tu n'avais peut-être pas conscientisés (ex: `main() --calls--> collect_markdown_files()`).

### 2.4 Exemple d'interrogation

Avant d'éditer un module, demande simplement à Claude :

> « Quelles sont les dépendances de `sync_memory.py` d'après Graphify ? Identifie les god nodes et dis-moi quels autres fichiers je risque d'impacter. »

Claude lira `GRAPH_REPORT.md` (via le hook) avant de répondre et te listera les risques réels, sans parcourir le code brut.

---

## 3. Obsidian — Documenter les décisions architecturales

Obsidian est ton **"second cerveau"** : il stocke tes notes conceptuelles, tes décisions, tes journaux. Ces notes deviendront la mémoire sémantique du projet une fois vectorisées dans Pinecone.

### 3.1 Structure du vault

Le vault est situé à `C:\Users\caste\Documents\Obsidian Vault\` avec l'arborescence suivante (déjà créée) :

```
Obsidian Vault/
├── decisions/   ← ADR (Architecture Decision Records)
├── specs/       ← spécifications fonctionnelles / techniques
└── journal/     ← journal de session, logs quotidiens
```

### 3.2 Écrire une note manuellement

Ouvre Obsidian, crée un nouveau fichier dans `decisions/` avec la convention de nommage :

```
YYYY-MM-DD-slug-court.md
```

Exemple de contenu pour une décision JWT :

```markdown
# Décision : Authentification JWT

Date : 2026-04-12
Statut : Adopté

## Contexte
Nous devons authentifier les utilisateurs de l'API REST.

## Décision
Utiliser des JWT signés HS256 avec refresh token rotatif.

## Conséquences
- Stateless : pas de session serveur
- Refresh token stocké en httpOnly cookie
- Révocation nécessitera une blacklist Redis
```

### 3.3 Demander à Claude d'écrire une note (via MCP)

Tu peux laisser Claude créer la note directement via le serveur MCP `obsidian` :

> « Crée une note dans mon vault Obsidian à `decisions/2026-04-12-auth-jwt.md` intitulée "Décision : Authentification JWT", expliquant pourquoi nous avons choisi JWT plutôt que les sessions serveur pour notre API REST. Respecte le format ADR (contexte, décision, conséquences). »

Claude utilisera `mcp__obsidian__obsidian_update_note` (ou `obsidian_manage_frontmatter`) pour écrire directement le fichier.

### 3.4 Rechercher dans le vault via Claude

> « Cherche dans mon vault Obsidian toutes les notes qui mentionnent l'authentification. »

Claude appelle `mcp__obsidian__obsidian_global_search` et te résume les résultats. Pour ouvrir une note précise :

> « Lis la note `decisions/2026-04-12-architecture-espace-opti.md` et résume les points clés. »

---

## 4. Pinecone — La mémoire sémantique

Pinecone est la **base vectorielle** qui indexe sémantiquement tes notes Obsidian. Là où Obsidian stocke les mots bruts, Pinecone permet de retrouver des concepts par **similarité cosinus** — même si les termes exacts diffèrent.

### 4.1 Embeddings 100 % locaux — aucune clé API requise

Le script `sync_memory.py` utilise désormais le modèle **`all-MiniLM-L6-v2`** de [sentence-transformers](https://www.sbert.net/), exécuté **entièrement en local** (384 dimensions). Aucune clé API d'embedding, aucun appel réseau pendant la vectorisation, zéro coût variable.

- **Premier lancement** : téléchargement automatique du modèle (~90 Mo) depuis Hugging Face. À faire une fois.
- **Lancements suivants** : le modèle est lu depuis le cache local (`~/.cache/huggingface/`). Fonctionne sans connexion.
- **Index Pinecone** : `sync_memory.py` détecte automatiquement si l'index `obsidian-memory` existe avec une dimension incompatible (ex: ancien index 1536 d'OpenAI) et le recrée en 384 dimensions, métrique `cosine`, serverless AWS `us-east-1`.

Variables d'environnement requises désormais :

| Variable | Rôle |
|---|---|
| `PINECONE_API_KEY` | Clé Pinecone (obligatoire) |
| `OBSIDIAN_VAULT` | Chemin du vault (optionnel, défaut : `C:\Users\caste\Documents\Obsidian Vault`) |

> La variable `OPENAI_API_KEY` n'est plus utilisée par `sync_memory.py`. Tu peux la garder si d'autres outils en dépendent, mais elle est ignorée ici.

### 4.2 Synchroniser le vault vers Pinecone

À la racine du projet :

```bash
python sync_memory.py
```

Ce que fait le script :
1. Valide les variables d'environnement (`OPENAI_API_KEY`, `PINECONE_API_KEY`, `OBSIDIAN_VAULT`).
2. Collecte tous les `.md` du vault (en excluant les dossiers cachés).
3. Découpe chaque note par headers H1/H2/H3 via `MarkdownHeaderTextSplitter`.
4. Génère les embeddings via OpenAI.
5. Upsert des vecteurs dans l'index Pinecone `obsidian-memory` par batches de 100.
6. Affiche un résumé (fichiers traités, chunks upsertés, total index).

**Quand relancer ?** Après chaque session où tu as ajouté/modifié des notes Obsidian importantes. À automatiser via le skill `schedule` si besoin.

### 4.3 Interroger la mémoire sémantique via Claude

Tu n'appelles jamais Pinecone directement — tu parles à Claude en langage naturel :

> « Quelles décisions architecturales avons-nous prises la semaine dernière ? »

> « Je veux ajouter un système de cache. As-tu des contraintes ou des décisions antérieures à respecter ? »

> « Cherche dans notre mémoire toutes les discussions sur la sécurité des API. »

Claude appellera `mcp__pinecone__search-records` sur l'index `obsidian-memory`, récupérera les chunks pertinents avec leurs métadonnées (fichier source, headers), et te synthétisera la réponse.

### 4.4 Vérifier l'état de l'index

```
demande à Claude : « Décris l'index pinecone obsidian-memory et donne-moi ses stats »
```

Claude utilisera `mcp__pinecone__describe-index` et `describe-index-stats`.

---

## 5. Les plugins — L'équipe virtuelle

Chaque plugin installe des skills, des agents ou des hooks qui modifient le comportement de Claude. Les plus importants au quotidien :

### 5.1 Superpowers — L'orchestrateur TDD

Superpowers force une boucle **Test-Driven Development** stricte :

1. Planification socratique de la feature
2. Écriture des tests unitaires (**Red**)
3. Implémentation minimale (**Green**)
4. Review interne

**Exemple de prompt** :

> « Avec superpowers, implémente une fonction `parse_iso_date(s: str) -> datetime` qui gère les formats ISO 8601 avec et sans fuseau horaire. Suis la discipline TDD : tests d'abord. »

Règle cardinale : **tout code écrit avant son test est systématiquement supprimé**. C'est voulu.

### 5.2 Frontend Design — Direction esthétique intentionnelle

Empêche Claude de générer du CSS générique en imposant une **direction esthétique** avant tout codage d'UI.

**Exemple de prompt** :

> « Utilise le skill frontend-design pour créer une page de login minimaliste, dans un style brutaliste : typographie serif monumentale, fond blanc cassé, zéro ombre, boutons angulaires, asymétrie volontaire. »

Le skill va d'abord produire une **moodboard verbal** (typo, palette, espacement, mouvement) puis seulement ensuite le code React/CSS.

### 5.3 Security Guidance — Filet de sécurité automatique

**Aucune invocation nécessaire**. Le plugin installe un hook `PreToolUse` qui intercepte **chaque Edit/Write** de Claude et le scanne contre 9 motifs critiques :

- Injections SQL / shell
- XSS (innerHTML non échappé)
- `eval()`, `exec()`, `os.system()` avec inputs non validés
- Secrets en dur
- Chemins de fichiers non échappés
- Désérialisation non sûre (`pickle.loads`, `yaml.load`)
- Redirections ouvertes
- CSRF manquant
- Cryptographie faible

Si un motif est détecté, **l'écriture est bloquée** et Claude reçoit un diagnostic pour corriger avant de réessayer.

### 5.4 Code Review — Audit multi-agents

Déclenche une revue en parallèle par 4-5 sous-agents spécialisés. Chacun scrute sous un angle différent : logique métier, conformité à `CLAUDE.md`, risques de silent failures, qualité des types, pertinence des tests.

**Exemple d'invocation** :

```
/code-review
```

Ou en langage naturel :

> « Lance une code review multi-agents sur le diff courant. Je veux un score de confiance et la liste des blockers avant que je commit. »

Toute PR qui n'atteint pas **80 % de score de confiance** est renvoyée pour corrections.

### 5.5 Code Simplifier — Anti-bloat

Les LLMs ont tendance à produire du code sur-ingénié (wrappers inutiles, abstractions prématurées, duplication). Le simplifier identifie et élimine ce bruit **sans changer le comportement**.

**Quand l'utiliser** :
- Après une longue session d'itérations successives sur le même module
- Avant un commit important
- Après une feature écrite par feature-dev ou superpowers

**Invocation** :

```
/simplify
```

Ou :

> « Passe le code que tu viens d'écrire au simplifier : dégage toute la sur-ingénierie. »

### 5.6 Playwright MCP — Tests E2E dans un vrai navigateur

Pilote un Chrome headless pour tester les parcours utilisateurs.

> « Utilise playwright pour ouvrir `http://localhost:3000/login`, remplir le formulaire avec `test@example.com` / `password123`, cliquer sur "Se connecter", et me dire si la redirection vers `/dashboard` fonctionne. Prends une capture d'écran de chaque étape. »

---

## 6. Workflow complet — Exemple : créer une feature "User Login"

Voici le scénario **de bout en bout** qui exploite toute la stack. Copie-colle les prompts dans ta session Claude.

### Étape 1 — Contexte intentionnel (Pinecone)

```
/start-feature système de login utilisateur avec JWT
```

Le slash command projet fait automatiquement les étapes 1 à 3 (recherche Pinecone, lecture GRAPH_REPORT, consultation MEMORY.md). Sinon, en manuel :

> « Cherche dans Pinecone toutes les décisions architecturales liées à l'authentification, aux sessions, et aux tokens. »

### Étape 2 — Contexte structurel (Graphify)

Le hook `PreToolUse` s'en charge. Tu peux aussi demander explicitement :

> « D'après `GRAPH_REPORT.md`, existe-t-il déjà un module d'authentification dans ce projet ? Quels god nodes pourraient être impactés par l'ajout d'un login ? »

### Étape 3 — Planification TDD (Superpowers)

> « Avec superpowers, planifie la feature login : routes `POST /auth/login`, validation credentials, génération JWT (HS256, expire 15min), refresh token (httpOnly cookie, expire 7j). Écris d'abord la liste des tests à écrire avant toute ligne d'implémentation. Attends ma validation du plan avant d'écrire le moindre code. »

Claude produit un plan structuré. Tu valides ou corriges.

### Étape 4 — Écriture guidée (TDD + Security)

> « Plan validé. Commence la phase Red : écris les tests unitaires pour `/auth/login` (success, mauvais mot de passe, user inexistant, payload malformé). Puis passe en Green. »

Pendant l'écriture :
- **Security Guidance** bloque automatiquement toute tentative de comparaison de mot de passe en clair, de secret JWT en dur, ou de log de credentials.
- Si un blocage survient, Claude te montre le diagnostic et corrige.

### Étape 5 — Revue multi-agents

Une fois la feature implémentée :

```
/code-review
```

Ou :

> « Lance une code review multi-agents sur les fichiers `routes/auth.py`, `services/jwt_service.py`, et leurs tests. Je veux le score de confiance et les blockers. »

Si le score est < 80 %, corrige les points signalés et relance.

### Étape 6 — Simplification

```
/simplify
```

Élimine les wrappers inutiles, les exceptions attrapées pour rien, les helpers d'une seule utilisation.

### Étape 7 — Test E2E

> « Utilise playwright pour tester le parcours login complet sur `http://localhost:3000` : formulaire rempli, soumission, vérification du cookie `refresh_token`, redirection vers `/dashboard`. Capture d'écran à chaque étape. »

### Étape 8 — Documentation dans Obsidian

> « Crée une note dans mon vault Obsidian à `decisions/2026-04-12-auth-login-jwt.md` au format ADR qui documente : contexte (pourquoi JWT + refresh rotatif), décision (HS256, durées, stockage cookie httpOnly), alternatives écartées (sessions serveur, OAuth2 externe), conséquences (besoin d'une blacklist Redis plus tard pour révocation). »

### Étape 9 — Vectorisation de la décision

Dans un terminal :

```bash
python sync_memory.py
```

La nouvelle note est lue, splittée par headers, embedée via OpenAI, upsertée dans Pinecone. La prochaine fois que tu poseras une question sur l'auth, Claude retrouvera automatiquement cette décision.

### Étape 10 — Mise à jour du graphe

```bash
python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Le graphe AST intègre désormais les nouveaux fichiers (`routes/auth.py`, `services/jwt_service.py`) et met à jour les god nodes + communautés.

**La feature est livrée.** Elle est testée, sécurisée, documentée, mémorisée, et cartographiée.

---

## 7. Cheat sheet — Commandes de référence rapide

### Lancement / diagnostic

| Commande | Utilité |
|---|---|
| `claude` | Démarre Claude Code dans le répertoire courant |
| `/mcp` | Liste les serveurs MCP et leur état (obsidian, pinecone) |
| `/plugin` | Ouvre le marketplace des plugins |
| `/plugin list` | Liste les plugins actifs |
| `/help` | Aide intégrée Claude Code |
| `/context` | Affiche l'usage du context window |
| `.\lite.ps1` | Lance Claude seul sans hooks (petites modifications rapides) |
| `.\full.ps1` | Lance toute l'équipe virtuelle avec vérification complète |

### Slash commands projet

| Commande | Utilité |
|---|---|
| `/start-feature <description>` | Lance le workflow complet d'une feature (Pinecone → Graphify → plan TDD) |
| `/code-review` | Audit multi-agents du diff courant |
| `/simplify` | Purge la sur-ingénierie du diff courant |
| `/loop 10m /code-review` | Boucle la code review toutes les 10 min |
| `/loop "<prompt>"` | Boucle auto-cadencée (ralph-loop) |

### Mémoire & graphe (terminal)

| Commande | Utilité |
|---|---|
| `python sync_memory.py` | Synchronise le vault Obsidian vers Pinecone |
| `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` | Reconstruit le graphe AST |
| `python -m graphify hook status` | Vérifie que le hook PreToolUse est bien installé |
| `cat graphify-out/GRAPH_REPORT.md` | Lit le rapport de topologie |

### Variables d'environnement (Windows)

| Commande | Utilité |
|---|---|
| `setx OBSIDIAN_API_KEY "<clé>"` | Persiste la clé Obsidian REST API |
| `setx PINECONE_API_KEY "<clé>"` | Persiste la clé Pinecone |
| `setx OPENAI_API_KEY "<clé>"` | Persiste la clé OpenAI (pour embeddings) |
| `setx OBSIDIAN_BASE_URL "https://127.0.0.1:27124"` | URL locale Obsidian |

> Après un `setx`, **ferme et rouvre le terminal** pour que la variable soit prise en compte.

### Prompts types à mémoriser

| Besoin | Prompt |
|---|---|
| Rechercher une décision passée | « Cherche dans Pinecone toutes les décisions sur X » |
| Comprendre l'impact d'un changement | « D'après Graphify, quels god nodes impacte ce fichier ? » |
| Créer une note architecturale | « Crée une note Obsidian dans `decisions/` au format ADR sur X » |
| Démarrer une feature rigoureusement | `/start-feature <description>` |
| Auditer avant commit | `/code-review` puis `/simplify` |
| Tester un parcours UI | « Utilise playwright pour tester X » |

### Fichiers clés

| Chemin | Rôle |
|---|---|
| `.claude/settings.json` | Config MCP + hooks projet |
| `.claude/commands/start-feature.md` | Slash command projet |
| `CLAUDE.md` | Instructions permanentes pour Claude |
| `graphify-out/GRAPH_REPORT.md` | Topologie du code (god nodes + communautés) |
| `sync_memory.py` | Pipeline Obsidian → Pinecone |
| `~/.claude/projects/<projet>/memory/MEMORY.md` | Index mémoire inter-session |
| `C:\Users\caste\Documents\Obsidian Vault\` | Vault Obsidian (decisions/, specs/, journal/) |

---

## 8. Modes de travail — LITE vs FULL

### Pourquoi deux modes ?

Activer toute l'équipe IA (Graphify, hooks, security-guidance, code-review, multi-agents) pour **corriger une faute de frappe** ou **changer une couleur** est du gaspillage : temps de démarrage rallongé, contexte saturé par les rapports Graphify, latence sur chaque `Glob`/`Grep` à cause du hook `PreToolUse`.

Le **LITE MODE** résout ce problème : Claude travaille seul, sans hook, avec un lancement quasi instantané. Le **FULL MODE** reste ton mode par défaut dès que la modification mérite une vraie discipline (nouvelle feature, refactoring, code sensible).

Un principe simple : **le mode doit être proportionnel à l'impact de la modification**.

### LITE MODE — Petites modifications rapides

- **Quand l'utiliser** : typos, changements de couleur, corrections de texte, ajustements de config mineurs, renommage local d'une variable, fix de commentaire.
- **Comment le lancer** :
  ```powershell
  .\lite.ps1
  ```
- **Ce qui est désactivé** :
  - Hook `PreToolUse` Graphify → Claude ne lit **plus** `GRAPH_REPORT.md` avant chaque `Glob`/`Grep`. Gain de latence et de tokens.
- **Ce qui reste actif** :
  - Serveur MCP `obsidian` (accès au vault si besoin)
  - Serveur MCP `pinecone` (mémoire sémantique toujours interrogeable)
- **Comment sortir** : tu quittes Claude Code normalement (Ctrl+C ou `/exit`). Le script restaure automatiquement `settings.json` **même en cas d'erreur ou d'interruption**. Le hook Graphify revient sans aucune action manuelle.

### FULL MODE — Développement complet

- **Quand l'utiliser** : nouvelle feature, refactoring, code sensible à la sécurité (auth, paiement, crypto), composants UI, migrations de données, intégrations d'API tierces.
- **Comment le lancer** :
  ```powershell
  .\full.ps1
  ```
- **Ce que le script vérifie avant de lancer Claude** :
  - Hook Graphify `PreToolUse` : **ACTIF** ✅
  - MCP servers `obsidian` + `pinecone` déclarés : **ACTIF** ✅
  - Knowledge graph `graphify-out/graph.json` : **PRESENT** ✅
- Si un composant manque, le script affiche un avertissement et te demande confirmation avant de démarrer. Tu repars sur une base saine : aucune surprise en pleine session.

### Tableau comparatif

| Dimension                 | LITE MODE                          | FULL MODE                                 |
|---------------------------|------------------------------------|-------------------------------------------|
| Hook Graphify `PreToolUse`| ❌ Désactivé                        | ✅ Actif                                   |
| Security Guidance         | ❌ Non sollicité                    | ✅ Actif (bloque patterns dangereux)       |
| Code Review multi-agents  | ❌ Pas invoqué                      | ✅ Disponible (`/code-review`)             |
| Obsidian MCP              | ✅ Actif                            | ✅ Actif                                   |
| Pinecone MCP              | ✅ Actif                            | ✅ Actif                                   |
| Vitesse de réponse        | 🚀 Rapide, contexte minimal         | 🐢 Plus lente, contexte riche              |
| Cas d'usage idéal         | Typos, couleurs, petits ajustements| Features, refactors, code sensible         |

### Exemples concrets

- « Je veux changer le titre de ma page d'accueil » → `.\lite.ps1`
- « Je veux corriger une faute dans un commentaire » → `.\lite.ps1`
- « Je veux ajouter un système de paiement Stripe » → `.\full.ps1`
- « Je veux refactoriser mon module d'authentification » → `.\full.ps1`

**Règle pratique** : si tu hésites entre les deux modes, choisis **FULL**. Le coût d'un hook en trop est toujours inférieur au coût d'un bug sécurité qui serait passé entre les mailles d'un mode LITE mal choisi.

---

## Rappel final — Les trois règles d'or

1. **Ne jamais coder sans avoir interrogé la mémoire.** Pinecone pour le "pourquoi", Graphify pour le "où".
2. **Toute décision conceptuelle = une note Obsidian.** Sans documentation, pas de mémoire sémantique future.
3. **Un commit = une passe security-guidance + code-review + simplify.** L'IA produit vite ; tes garde-fous évitent la dette.

L'ingénieur humain n'écrit presque plus de code : il orchestre, valide, et capitalise. C'est le cœur de l'Espace_Opti.
