# 📚 Index Complet - Honeypot Kali Linux

## 📖 Documentation Organisée

### 🚀 Démarrage
- **[DEMARRAGE_RAPIDE.md](DEMARRAGE_RAPIDE.md)** - Guide 5 minutes pour commencer
  - Installation automatisée
  - Vérification rapide
  - Premiers pas

### 📋 Configuration Principale
- **[RAPPORT_HONEYPOT.md](RAPPORT_HONEYPOT.md)** - Rapport technique complet (50+ pages)
  - Architecture du système
  - Installation détaillée de chaque composant
  - Configuration avancée
  - Tests et validation
  - Maintenance et sécurité

### 🏗️ Architecture
- **[ARCHITECTURE_DETAILLEE.md](ARCHITECTURE_DETAILLEE.md)** - Diagrammes et flux détaillés
  - Diagramme d'architecture complète
  - Flux de données en détail
  - Lifecycle des événements
  - Composants Docker
  - Métriques et performances

### 🔧 Commandes et Configuration
- **[COMMANDES_ET_CONFIG.md](COMMANDES_ET_CONFIG.md)** - Référence complète des commandes
  - Démarrage/Arrêt des services
  - Gestion de Cowrie
  - Vérification des services
  - Tests de connectivité
  - Recherche dans les logs
  - Maintenance

### 📊 Dashboards et Alertes
- **[DASHBOARDS_ET_ALERTES.md](DASHBOARDS_ET_ALERTES.md)** - Configurer Grafana
  - 5 dashboards pré-conçus
  - Requêtes LogQL avancées
  - Configuration d'alertes
  - Exemples de visualisations

### 🐛 Problèmes et Solutions
- **[TROUBLESHOOTING_AVANCE.md](TROUBLESHOOTING_AVANCE.md)** - Dépannage complet
  - 8+ problèmes courants avec solutions
  - Diagnostique avancée
  - Performance tuning
  - Sécurité

### 📦 Fichiers de Configuration
- **docker-compose.yml** - Services Loki + Grafana
- **loki-config/loki-config.yml** - Configuration Loki détaillée
- **install-honeypot.sh** - Script d'installation automatisée

---

## 🎯 Comment Utiliser cette Documentation

### Scénario 1 : Je veux commencer tout de suite ⏱️
1. Lire [DEMARRAGE_RAPIDE.md](DEMARRAGE_RAPIDE.md)
2. Exécuter `sudo bash install-honeypot.sh`
3. Aller sur http://localhost:3000

### Scénario 2 : Je veux comprendre l'architecture 🏛️
1. Lire [ARCHITECTURE_DETAILLEE.md](ARCHITECTURE_DETAILLEE.md)
2. Consulter les diagrammes et flux

### Scénario 3 : Je veux configurer les dashboards 📊
1. Démarrer les services
2. Lire [DASHBOARDS_ET_ALERTES.md](DASHBOARDS_ET_ALERTES.md)
3. Créer les dashboards dans Grafana

### Scénario 4 : Quelque chose ne fonctionne pas 🔧
1. Consulter [TROUBLESHOOTING_AVANCE.md](TROUBLESHOOTING_AVANCE.md)
2. Chercher le problème correspondant
3. Appliquer la solution

### Scénario 5 : Je veux tous les détails 📖
1. Lire [RAPPORT_HONEYPOT.md](RAPPORT_HONEYPOT.md) complètement
2. Puis explorer les autres documents

---

## 📌 Points Clés à Retenir

### Installation
```bash
sudo bash install-honeypot.sh  # Installation complète
```

### Services
```bash
# Loki + Grafana
cd ~/honeypot
docker-compose up -d

# Cowrie
cd ~/honeypot/cowrie
source cowrie-venv/bin/activate
bin/cowrie start
```

### Accès
```
Grafana    : http://localhost:3000 (admin/admin123)
Loki API   : http://localhost:3100
Cowrie SSH : Port 2222 ou Port 22 (redirigé)
```

### Logs
```bash
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json | jq
```

---

## 🔍 Rechercher dans la Documentation

| Sujet | Fichier | Section |
|-------|---------|---------|
| Installation | RAPPORT_HONEYPOT.md | Installation de Cowrie |
| Loki | RAPPORT_HONEYPOT.md | Configuration de Loki |
| Grafana | RAPPORT_HONEYPOT.md | Configuration de Grafana |
| Dashboards | DASHBOARDS_ET_ALERTES.md | Tous les dashboards |
| Alertes | DASHBOARDS_ET_ALERTES.md | Configuration des alertes |
| Commandes | COMMANDES_ET_CONFIG.md | Tous les services |
| Architecture | ARCHITECTURE_DETAILLEE.md | Diagramme complet |
| Problèmes | TROUBLESHOOTING_AVANCE.md | Tous les problèmes |

---

## 📊 Statistiques de Documentation

| Document | Pages | Sections | Code Examples |
|----------|-------|----------|---|
| RAPPORT_HONEYPOT.md | ~50 | 10 | 30+ |
| ARCHITECTURE_DETAILLEE.md | ~20 | 8 | 15+ |
| COMMANDES_ET_CONFIG.md | ~15 | 12 | 50+ |
| DASHBOARDS_ET_ALERTES.md | ~20 | 8 | 25+ |
| TROUBLESHOOTING_AVANCE.md | ~20 | 10 | 40+ |
| DEMARRAGE_RAPIDE.md | ~10 | 8 | 10+ |

**Total** : ~135 pages de documentation complète

---

## 🚀 Premiers Pas Recommandés

### Jour 1
- [ ] Lire DEMARRAGE_RAPIDE.md
- [ ] Exécuter install-honeypot.sh
- [ ] Vérifier que Grafana/Loki/Cowrie fonctionnent

### Jour 2
- [ ] Lire ARCHITECTURE_DETAILLEE.md
- [ ] Comprendre le flux de données
- [ ] Tester une connexion SSH

### Jour 3
- [ ] Lire DASHBOARDS_ET_ALERTES.md
- [ ] Créer les premiers dashboards
- [ ] Configurer les alertes

### Jour 4+
- [ ] Lire RAPPORT_HONEYPOT.md en détail
- [ ] Apprendre les commandes avancées
- [ ] Optimiser pour votre cas d'usage

---

## 💾 Structure du Répertoire

```
~/honeypot/
│
├── 📄 Documentation/
│   ├── README.md (ce fichier)
│   ├── DEMARRAGE_RAPIDE.md
│   ├── RAPPORT_HONEYPOT.md
│   ├── ARCHITECTURE_DETAILLEE.md
│   ├── COMMANDES_ET_CONFIG.md
│   ├── DASHBOARDS_ET_ALERTES.md
│   └── TROUBLESHOOTING_AVANCE.md
│
├── 🐳 Docker/
│   ├── docker-compose.yml
│   └── loki-config/
│       └── loki-config.yml
│
├── 🛠️ Installation/
│   └── install-honeypot.sh
│
├── 🎣 Cowrie/
│   └── (dossier Cowrie cloné)
│
└── 📦 Services/
    ├── loki-storage/ (volume Docker)
    └── grafana-storage/ (volume Docker)
```

---

## 🔐 Checklist de Sécurité

- [ ] Changer le mot de passe Grafana
- [ ] Utiliser SSL/TLS pour Grafana
- [ ] Restreindre l'accès aux ports
- [ ] Activer le firewall (ufw)
- [ ] Mettre à jour régulièrement
- [ ] Archiver les logs périodiquement
- [ ] Monitorer les ressources système

---

## 📞 Ressources Externes

- 🔗 [Documentation Cowrie](https://cowrie.readthedocs.io/)
- 🔗 [Documentation Loki](https://grafana.com/docs/loki/)
- 🔗 [Documentation Grafana](https://grafana.com/docs/grafana/)
- 🔗 [GitHub Cowrie](https://github.com/cowrie/cowrie)

---

## ✨ Prochaines Étapes

Après avoir complété l'installation initiale, vous pouvez :

1. **Intégrer Prometheus** pour les métriques système
2. **Ajouter Alertmanager** pour les alertes avancées
3. **Configurer GeoIP** pour voir d'où viennent les attaques
4. **Ajouter un reverse proxy** (nginx) pour la sécurité
5. **Implémenter la sauvegarde automatique** des données
6. **Analyser les patterns** d'attaques détectées

---

## 📊 Vue d'ensemble Rapide

### Ce que ce projet fait
✅ Capture les tentatives SSH/Telnet  
✅ Enregistre les commandes exécutées  
✅ Agrège les logs en temps réel  
✅ Visualise les attaques dans Grafana  
✅ Génère des alertes automatiques  

### Ce que ce projet ne fait PAS
❌ Bloquer les attaquants (c'est un honeypot, pas un firewall)  
❌ Contremesurer (c'est de la collecte d'intelligence)  
❌ Chiffrer les données (utiliser SSL/TLS en production)  
❌ Sauvegarder automatiquement (à configurer soi-même)  

---

## 🎓 Concepts clés

- **Honeypot** : Système intentionnellement vulnérable pour tromper les attaquants
- **Cowrie** : Faux serveur SSH/Telnet
- **Loki** : Agrégateur de logs
- **Grafana** : Plateforme de visualisation
- **LogQL** : Langage de requête pour Loki

---

**Prêt à commencer ?** 👉 Commencez par [DEMARRAGE_RAPIDE.md](DEMARRAGE_RAPIDE.md)

---

*Documentation créée pour Kali Linux - Avril 2026*
