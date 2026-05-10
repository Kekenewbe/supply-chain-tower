# Git Aliases — Worktree Cleanup

Trois alias git globaux (configures via `git config --global`) pour gerer les worktrees des agents (frontend, backend) qui sont parfois orphelins apres un kill de session ou un crash.

## Alias disponibles

### `git wt-list`
Liste tous les worktrees actifs (incluant le worktree principal).

```bash
git wt-list
```

Equivalent : `git worktree list`.

### `git wt-prune`
Supprime les references aux worktrees dont le dossier a ete supprime manuellement (orphelins).

```bash
git wt-prune
```

Equivalent : `git worktree prune -v` (verbose pour voir ce qui est supprime).

### `git wt-clean`
**Destructive.** Supprime TOUS les worktrees secondaires (garde uniquement le principal) puis prune les references restantes. A utiliser apres une session ratee ou pour reset complet.

```bash
git wt-clean
```

Equivalent shell :
```bash
git worktree list | tail -n +2 | awk '{print $1}' | xargs -I {} git worktree remove --force {} && git worktree prune -v
```

## Quand utiliser

- **Apres un crash de session Claude Code** avec agents @backend/@frontend en cours : `git wt-list` puis `git wt-clean` si orphelins.
- **Avant une nouvelle invocation parallele** : `git wt-prune` pour eviter conflits.
- **Verification routine** : `git wt-list` regulierement pour s'assurer qu'aucun worktree zombie ne traine.

## Reference

Anomalie A2 backlog VisualPrompt — Phase 1 Quick Wins (2026-04-30).

Voir aussi : `scripts/cleanup-claude-old-binaries.ps1` qui nettoie les binaires npm staging (probleme distinct mais voisin).
