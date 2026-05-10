---
date: <% tp.date.now("YYYY-MM-DD") %>
scope: <% tp.system.suggester(["transverse", "espace_opti", "vp", "socialflow", "supply_chain_tower"], ["transverse", "espace_opti", "vp", "socialflow", "supply_chain_tower"]) %>
tags: [eval]
---

## <% tp.date.now("YYYY-MM-DD") %> — <% tp.file.title %>

- **Scope** : `<% tp.frontmatter.scope %>`
- **Tags** : #eval #<% tp.frontmatter.scope %>
- **Agent** :
- **Type** : hallucination / silent-divergence / scope-creep / outdated / autre
- **Description** :
- **Impact** : mineure / majeure / bloquante
- **Correction appliquée** :
- **Mitigation future** :
