---
name: security-scanner
purpose: Les 9 patterns de vulnérabilité scannés par l'agent Sécurité sur chaque Edit/Write
---

# Skill — Security Scanner

Utilisé par l'agent **Sécurité** comme source de vérité des patterns bloquants.
Chaque pattern doit être détectable par regex ou AST simple, pour rester dans le budget de 500 tokens.

## Les 9 patterns

### 1. Injection SQL
**Signaux** : concaténation ou f-string qui construit une requête.
```py
db.execute(f"SELECT * FROM users WHERE id = {user_id}")   # BLOCKED
db.execute("SELECT * FROM users WHERE id = " + user_id)   # BLOCKED
```
**Fix** : requête paramétrée.
```py
db.execute("SELECT * FROM users WHERE id = ?", (user_id,))
```

### 2. Injection shell
**Signaux** : `os.system`, `subprocess.run(..., shell=True)`, `subprocess.Popen(..., shell=True)` avec des strings concaténées.
**Fix** : `subprocess.run([...])` sans `shell=True`, args en liste.

### 3. XSS
**Signaux** : `innerHTML =`, `document.write(`, `dangerouslySetInnerHTML={`, `v-html="..."`.
**Fix** : `textContent`, `.innerText`, ou sanitize via DOMPurify si HTML vraiment requis.

### 4. `eval` / `exec` dangereux
**Signaux** : `eval(`, `exec(`, `Function(`, `new Function(` avec input non constant.
**Fix** : parser explicite (JSON.parse, regex validée), jamais d'exécution dynamique.

### 5. Secrets en dur
**Signaux regex** :
- `sk-[A-Za-z0-9]{20,}` (OpenAI, Stripe)
- `pcsk_[A-Za-z0-9_-]{20,}` (Pinecone)
- `AKIA[A-Z0-9]{16}` (AWS)
- `ghp_[A-Za-z0-9]{36}` (GitHub)
- `xox[baprs]-[A-Za-z0-9-]{10,}` (Slack)
**Fix** : `os.getenv(...)` + `.env` hors git.

### 6. Path traversal
**Signaux** : concaténation `base_dir + user_input` pour ouvrir un fichier, sans `Path.resolve()` ni vérification que le résultat reste sous `base_dir`.
**Fix** : `Path(base).joinpath(user_input).resolve().relative_to(base)` (lève ValueError si échappe).

### 7. Désérialisation non sûre
**Signaux** : `pickle.loads(`, `yaml.load(` sans `Loader=yaml.SafeLoader`, `marshal.loads(`.
**Fix** : `json.loads`, `yaml.safe_load`, ou format structuré typé (pydantic, zod).

### 8. Redirection ouverte
**Signaux** : `res.redirect(req.query.X)`, `Response.Redirect(Request.Params[...])`.
**Fix** : whitelist des URL autorisées ou chemins relatifs uniquement.

### 9. Crypto faible
**Signaux** : `md5(`, `sha1(`, `DES`, `RC4`, `ECB` pour hashing passwords ou chiffrement sensible.
**Fix** : `bcrypt`/`argon2` pour passwords, `AES-GCM` ou `ChaCha20-Poly1305` pour chiffrement.

## Contournement légitime
Si le développeur a une raison valide, il peut marquer la ligne :
```py
db.execute("SELECT 1")  # security-ok: constant query, no user input
```
Le scanner respecte ce marqueur **sur la même ligne uniquement**.
