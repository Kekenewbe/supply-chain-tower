---
name: qa-scorer
purpose: Grille de scoring QA — 4 dimensions, pondérations, seuil 80 %
---

# Skill — QA Scorer

Utilisé par l'agent **QA Review** pour calculer le score de confiance sur un diff de module.

## Les 4 dimensions et leurs poids

| Dimension | Poids | Sous-agent responsable |
|---|---|---|
| Logique métier | 30 % | `logic-reviewer` |
| Qualité des types | 20 % | `type-reviewer` |
| Couverture tests | 25 % | `test-reviewer` |
| Conformité archi | 25 % | `arch-reviewer` |

**Score final** = `0.30·logic + 0.20·types + 0.25·tests + 0.25·arch`.
**Seuil de passage** : **80/100**.

## Grilles de notation

### Logique métier (30 %)
| Points | Critère |
|---|---|
| 30 | Tous les cas limites couverts, invariants explicites, erreurs typées |
| 25 | Cas limites couverts mais pas documentés |
| 20 | Happy path solide, cas limites partiels |
| 10 | Happy path seulement, branches d'erreur absentes |
| 0 | Bug logique évident |

### Qualité des types (20 %)
| Points | Critère |
|---|---|
| 20 | Pas de `any`/`unknown`, null safety, discriminated unions utilisés |
| 15 | 1-2 `any` justifiés ou cast explicites documentés |
| 10 | Types présents mais permissifs (`object`, `Record<string, any>`) |
| 5 | Types absents ou incorrects |
| 0 | Aucun type, tout en dynamic |

### Couverture tests (25 %)
| Points | Critère |
|---|---|
| 25 | ≥ 90 % lignes, happy + erreurs + cas limites |
| 20 | ≥ 80 % lignes, happy + erreurs |
| 15 | ≥ 60 % lignes, happy path uniquement |
| 10 | Tests présents mais superficiels |
| 0 | Aucun test |

### Conformité archi (25 %)
| Points | Critère |
|---|---|
| 25 | Respect strict du contrat, zéro fuite inter-modules |
| 20 | Contrat respecté, fuites mineures (imports croisés non critiques) |
| 15 | Contrat respecté mais contournement visible |
| 5 | Contrat modifié sans passer par l'Architecte |
| 0 | Module touche aux fichiers d'un autre agent |

## Politique de décision

- **score ≥ 80** → module approuvé → passe au Simplifier
- **70 ≤ score < 80** → retour à l'agent d'origine avec blockers listés
- **score < 70** → retour à l'Architecte : le découpage est peut-être en cause

## Format du `REVIEW_REPORT.md`
(voir `_workspace/agents/qa-review.md` pour le template exact)
