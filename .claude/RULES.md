---
project: supply-chain-tower
template_version: 1.0
template_source: Espace_Opti/.claude/RULES_TEMPLATE.md
generated_at: 2026-05-10
---

# Regles non-negociables — supply-chain-tower

> Snapshot operationnel des regles imposees a tous les agents du projet supply-chain-tower.
> Source : Espace_Opti/.claude/RULES_TEMPLATE.md (v1.0)
> Modifications locales tolerees mais signalees lors du prochain pull template.

## 1. Identite

- **Projet** : supply-chain-tower
- **Workspace** : reference relative uniquement (jamais hardcode `C:\Users\...`)
- **Vault Obsidian** : `Memory/` (1 vault par projet, doctrine portabilite)
- **Index Pinecone** : `supply-chain-tower-memory` (lowercase kebab, isolation memoire stricte)
- **Cles requises** : `OBSIDIAN_API_KEY`, `PINECONE_API_KEY` (User env Windows)

## 2. Memory/

5 registres canoniques append-only + meta + journal :

- `decisions.md` — decisions architecturales, format `## YYYY-MM-DD - <Titre>`
- `learnings.md` — lecons techniques, format `## YYYY-MM-DD - <Lecon>`
- `blockers.md` — anomalies A##, format `## YYYY-MM-DD - A## - <Symptome>`
- `evals.md` — evaluations agents, format `## YYYY-MM-DD - <Agent> - <Type>`
- `backlog.md` — items, format `## Snapshot YYYY-MM-DD HH:mm`
- `journal.md` — chronologie session
- `SCHEMA.md` — meta : doit etre LU avant toute gravure (anti-A30/A42)

Discipline append-only stricte. Jamais modifier une entree gravee.

## 3. Securite

- INTERDIT : commit cles API en clair. Toujours `.env` (gitignore confirme).
- INTERDIT : `git push` sans validation utilisateur explicite.
- INTERDIT : modifier directement Espace_Opti pour le projet supply-chain-tower derive (utiliser `new-project.ps1`).
- OBLIGATOIRE : fingerprint cles API au demarrage (banner check), jamais la cle complete.
- OBLIGATOIRE : anti-leak — verifier `Espace_Opti` absent du repo supply-chain-tower (critere portabilite).

## 4. Discipline

7 regles operationnelles imposees :

- TDD strict : tests verts AVANT et APRES toute modification.
- Atomicite commits : 1 domaine = 1 commit, max 100 fichiers.
- Backup obligatoire avant modif > 10 lignes : format `<fichier>.bak_<contexte>`.
- Append-only Memory/ : jamais modifier une entree gravee.
- Encoding UTF-8 sans BOM partout (anti-A53, anti-mojibake).
- Pas de here-string PowerShell complexe `@"..."@` (lecon A53).
- Cross-check empirique : tester avant declarer DONE (anti-hallucination).

## 5. Workflow

Pipeline 7 phases impose :

1. **PRD** — `/start-prd <idee>` → reformulation + 8 questions + `PRD.md`.
2. **Architecture** — `@architecte` → `ARCHITECTURE.md` + `modules.json`.
3. **Dev parallele** — `@frontend` + `@backend` simultanes (delegation parallele).
4. **QA** — `@qa-review` score >= 80 obligatoire.
5. **Simplification** — `@simplifier` post-QA, invariant tests verts.
6. **Tests E2E** — `@playwright` toutes user stories.
7. **Livraison** — `/deliver` puis validation user puis push manuel.

STOP utilisateur entre chaque phase (anti-A23 saut de phase).

## 6. Workarounds connus

| Code | Severite | Symptome court | Workaround |
|---|---|---|---|
| A8/#95 | MEDIUM | Notepad humain inbox | `scripts/inbox-write.ps1` separe |
| A30 | HIGH | Hallucination cleanup sans cross-check | Read filesystem AVANT delete |
| A37 | MEDIUM | Confusion path inbox/current.md | Toujours `inbox/current.md` (relatif racine projet) |
| A40 | HIGH | Hook UserPromptSubmit perd inbox | Marker `.claude/inbox_injected_hash` |
| A42 | MEDIUM | Gravure Memory/ sans SCHEMA | LIRE `Memory/SCHEMA.md` AVANT toute gravure |
| A53 | HIGH | Mojibake UTF-8 + BOM PowerShell | UTF-8 sans BOM strict, encodage explicite |
| A66 | LOW | Graphify rebuild non-deterministe | Tolerer `M graph.json` working tree |
| A67 | LOW | Invoke-RestMethod cold-start ~2s | Cross-check timing server-side |
| A68 | MEDIUM | Cleanup artefacts production sans verif | Phase 0 verifie presence pre-test |

Detail technique complet : `Memory/blockers.md` du projet.

## 7. Hors-perimetre (non-blockers locaux)

- **graphify** : optionnel, peut etre desactive (LITE MODE). Hook PreToolUse non critique.
- **Pinecone** : externe, latence reseau possible. Fallback : grep local `Memory/` si indispo.
- **MCP servers** (obsidian, pinecone, playwright) : si `claude mcp list` retourne `Failed`, ne pas considerer comme bloquant projet.

Rationale : eviter qu'un agent confonde `pinecone offline` avec `projet broken`.
