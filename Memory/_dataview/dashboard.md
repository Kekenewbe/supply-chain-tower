# Dashboard — Memory Espace_Opti

> Requiert le plugin Obsidian "Dataview". Installer via Settings → Community plugins.
> Les requêtes ci-dessous sont des défauts raisonnables (le brief Phase α était tronqué — à affiner en Phase β quand des entrées existeront).

## Top blockers récurrence ≥ 2

```dataview
TABLE WITHOUT ID
  file.link AS "Blocker",
  scope AS "Scope",
  recurrences AS "Récurrences",
  status AS "Statut"
FROM "Memory"
WHERE contains(tags, "blocker") AND recurrences >= 2
SORT recurrences DESC
```

## Décisions récentes (30 derniers jours)

```dataview
TABLE WITHOUT ID
  file.link AS "Décision",
  scope AS "Scope",
  date AS "Date"
FROM "Memory"
WHERE contains(tags, "decision") AND date(date) >= date(today) - dur(30 days)
SORT date DESC
```

## Learnings par scope

```dataview
TABLE WITHOUT ID
  file.link AS "Learning",
  date AS "Date"
FROM "Memory"
WHERE contains(tags, "learning")
GROUP BY scope
SORT scope ASC, date DESC
```

## Sessions récentes (journal — 14 derniers jours)

```dataview
TABLE WITHOUT ID
  file.link AS "Session",
  scope AS "Scope",
  date AS "Date"
FROM "Memory"
WHERE contains(tags, "journal-entry") AND date(date) >= date(today) - dur(14 days)
SORT date DESC
```
