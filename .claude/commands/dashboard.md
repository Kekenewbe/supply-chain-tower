---
description: Lance le dashboard web local pour gérer et monitorer tous les projets en développement. Ouvre automatiquement http://localhost:3131 dans le navigateur.
---

Lance le dashboard de gestion des projets Espace_Opti.

1. Vérifier que les dépendances sont installées : pip install fastapi uvicorn websockets watchdog
2. Lancer le serveur : python C:\Users\caste\Desktop\Espace_Opti\dashboard.py
3. Le navigateur s'ouvre automatiquement sur http://localhost:3131
4. Arrêter : Ctrl+C dans le terminal

Le dashboard permet de :
- Voir tous les projets dérivés d'Espace_Opti avec leur état
- Monitorer les agents en temps réel via WebSocket
- Éditer PRD.md, modules.json, CLAUDE.md directement dans le navigateur
- Lancer full.ps1, lite.ps1, sync_memory.py depuis l'interface
- Créer un nouveau projet sans ligne de commande
- Kanban visuel des modules avec drag-and-drop
