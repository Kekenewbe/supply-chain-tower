---
name: close-session
description: Cloture une session Espace_Opti en appendant snapshot backlog + entree journal, avec auto-remplissage des sections via skill session-chronicler (claude --print).
---

# /close-session

Alias trigger pour `scripts/end-session.ps1 v4`. Combine snapshot backlog + entree journal + auto-remplissage des 6 placeholders via skill `session-chronicler`.

## Usage

```
/close-session "s15-phase-d-clearinbox"   # SessionLabel explicite
/close-session                            # auto-detecte depuis derniere entree journal.md
/close-session -DryRun                    # preview sans ecriture disque
/close-session -SkipChronicler            # mode v3 fallback (placeholders manuels)
```

## Arguments

| Arg | Type | Default | Description |
|---|---|---|---|
| `SessionLabel` | string positionnel | auto-detect | Ex: "s15-phase-d-clearinbox" |
| `-DryRun` | switch | false | Preview (snapshot + entree journal + chronicle JSON) sans ecrire |
| `-SkipChronicler` | switch | false | Force fallback v3 (laisse les placeholders manuels) |
| `-Scope` | string | espace_opti | Scope tag (espace_opti, vp, sf, sct) |

## Auto-detection SessionLabel

Si aucun label fourni :
1. Lire `Memory/journal.md` derniere entree, extraire `Session N - <label>`
2. Incrementer N de 1, conserver pattern label (ex: s14 -> s15)
3. Si echec : prompt utilisateur pour saisir le label

## Workflow d'execution

1. Backup `Memory/backlog.md.bak_pre_<label>` + `Memory/journal.md.bak_endsession_<timestamp>` (regle 6)
2. Append snapshot squelette dans `backlog.md` (placeholders 4)
3. Append entree squelette dans `journal.md` (placeholders 2)
4. **Si `-SkipChronicler` absent ET `claude` CLI disponible** :
   - Invoque `claude --print --skill session-chronicler` avec contexte (label, paths, journal precedent, snapshot frais, git log session, git status)
   - Parse JSON stdout
   - Regex replace les 6 placeholders dans backlog + journal
   - Cross-check post-write : compte placeholders restants (doit etre 0)
5. **Sinon** : laisse les placeholders en place + warn utilisateur
6. Exit 0 si OK, 1 si verification post-write fail

## Garde-fous

- Backup obligatoire avant tout Edit (regle 6 CLAUDE.md global)
- DryRun strict pour preview (snapshot + chronicle JSON imprime sans ecriture)
- ASCII pur dans fichiers persistes (anti-A31)
- Cross-check post-write empirique (anti-A92, anti-A30)
- Idempotence : meme header dans la meme heure -> exit 0 sans modification

## Reference croisee

- Script : `scripts/end-session.ps1` v4 (extension Phase D.2 @backend)
- Skill : `.claude/skills/session-chronicler.md` (Phase D.1.B)
- Audit source : Phase D.1.A @manager
- Doctrine memoire : `Memory/SCHEMA.md`
