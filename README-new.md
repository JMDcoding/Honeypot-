# 🎣 Honeypot Kali Linux - Cowrie + Loki + Grafana

**Un piège à intrusion complet pour détecter et analyser les attaques SSH/Telnet**

## 🚀 Démarrage en 5 minutes

```bash
# 1. Cloner/télécharger ce projet
git clone <URL> ~/honeypot && cd ~/honeypot

# 2. Lancer l'installation (automatisée)
sudo bash install-honeypot.sh

# 3. Démarrer Cowrie
cd cowrie && source cowrie-venv/bin/activate && bin/cowrie start

# 4. Accéder à Grafana
# Ouvrir : http://localhost:3000
# Login : admin / admin123
```

**C'est tout !** Votre honeypot est maintenant actif et capture les attaques en temps réel.

---

## 📚 Documentation Complète

- 📖 **[INDEX.md](INDEX.md)** - Table des matières complète
- 🏃 **[DEMARRAGE_RAPIDE.md](DEMARRAGE_RAPIDE.md)** - Guide 5 minutes
- 📋 **[RAPPORT_HONEYPOT.md](RAPPORT_HONEYPOT.md)** - Rapport technique complet (50+ pages)
- 🏛️ **[ARCHITECTURE_DETAILLEE.md](ARCHITECTURE_DETAILLEE.md)** - Diagrammes et flux
- 🔧 **[COMMANDES_ET_CONFIG.md](COMMANDES_ET_CONFIG.md)** - Commandes utiles
- 📊 **[DASHBOARDS_ET_ALERTES.md](DASHBOARDS_ET_ALERTES.md)** - Grafana dashboards
- 🐛 **[TROUBLESHOOTING_AVANCE.md](TROUBLESHOOTING_AVANCE.md)** - Dépannage

---

## 🎯 Qu'est-ce que c'est ?

Un **honeypot** (piège à intrusion) est un système informatique intentionnellement vulnérable qui :

✅ Simule un vrai serveur SSH/Telnet  
✅ Capture les tentatives d'accès non autorisées  
✅ Enregistre les commandes exécutées  
✅ Collecte des données sur les attaques  
✅ Génère des alertes en temps réel  

---

## 📌 Architecture

```
[Attaquants] → SSH/Telnet (Port 22/23)
                ↓
            [Cowrie Honeypot]
                ↓
            [Logs JSON]
                ↓
            [Loki Agrégateur]
                ↓
           [Grafana Dashboard]
                ↓
          [Alertes & Visualisations]
```

---

## 📊 Composants

| Composant | Port | Fonction |
|-----------|------|----------|
| **Cowrie** | 2222 | Faux serveur SSH |
| **Loki** | 3100 | Agrégation des logs |
| **Grafana** | 3000 | Visualisation |

---

## ✨ Fonctionnalités

- 🔍 **Capture d'intrusions** : Enregistre toutes les tentatives SSH
- 📊 **Dashboards temps réel** : Visualisez les attaques en direct
- 🚨 **Alertes automatiques** : Soyez notifié des menaces
- 📈 **Statistiques détaillées** : Adresses IP, usernames, commandes
- 🔐 **Isolation réseau** : Honeypot isolé des autres systèmes
- 📦 **Déploiement facile** : Installation en 1 commande

---

## 🔑 Identifiants par défaut

```
Grafana
├── URL: http://localhost:3000
├── Utilisateur: admin
└── Mot de passe: admin123 ⚠️ (À changer !)

Loki API
├── URL: http://localhost:3100
└── Port: 3100

Cowrie SSH
├── Port: 2222 (ou 22 redirigé)
├── Utilisateur: test
└── Mot de passe: n'importe lequel
```

---

## 🛠️ Prérequis

- **OS** : Kali Linux (ou toute distribution Linux)
- **RAM** : 4 Go minimum
- **Disque** : 20 Go
- **Docker** : Installation incluant Docker Compose
- **Python 3** : Pour Cowrie

---

## 📋 Installation Complète

### Option 1: Installation Automatisée (Recommandée)
```bash
chmod +x install-honeypot.sh
sudo bash install-honeypot.sh
```

### Option 2: Installation Manuelle
Voir [RAPPORT_HONEYPOT.md](RAPPORT_HONEYPOT.md) pour les détails complets.

---

## 🎮 Utilisation

### Démarrer les services
```bash
# Loki + Grafana (Docker)
docker-compose up -d

# Cowrie
cd cowrie
source cowrie-venv/bin/activate
bin/cowrie start
```

### Arrêter les services
```bash
docker-compose down
cd cowrie && bin/cowrie stop
```

### Voir les logs en temps réel
```bash
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json | jq
```

### Accéder aux interfaces
```
Grafana  : http://localhost:3000
Loki API : http://localhost:3100
```

---

## 📊 Dashboards Disponibles

1. **Vue d'ensemble** - Statistiques en temps réel
2. **Connexions** - Détails des tentatives d'accès
3. **Commandes** - Analyse des commandes exécutées
4. **Sécurité** - Alertes et patterns suspects
5. **Transferts de fichiers** - Fichiers téléchargés

Voir [DASHBOARDS_ET_ALERTES.md](DASHBOARDS_ET_ALERTES.md) pour les requêtes LogQL.

---

## 🔐 Sécurité

⚠️ **Important** : Ce honeypot est intentionnellement vulnérable. À utiliser dans un environnement isolé.

Recommandations :
- [ ] Changer le mot de passe Grafana
- [ ] Isoler le honeypot en réseau si possible
- [ ] Utiliser un firewall pour restreindre l'accès
- [ ] Mettre à jour régulièrement
- [ ] Monitorer les ressources système

---

## 🐛 Dépannage

### Problème courant : Pas de logs dans Grafana
```bash
# 1. Vérifier que Cowrie fonctionne
cd cowrie && bin/cowrie status

# 2. Vérifier que Loki répond
curl http://localhost:3100/loki/api/v1/labels

# 3. Redémarrer les services
docker-compose restart
```

Pour plus de solutions, voir [TROUBLESHOOTING_AVANCE.md](TROUBLESHOOTING_AVANCE.md)

---

## 📖 Approfondir

- 📋 **Configuration** : [RAPPORT_HONEYPOT.md](RAPPORT_HONEYPOT.md)
- 🏗️ **Architecture** : [ARCHITECTURE_DETAILLEE.md](ARCHITECTURE_DETAILLEE.md)
- 🔧 **Commandes** : [COMMANDES_ET_CONFIG.md](COMMANDES_ET_CONFIG.md)
- 📊 **Dashboards** : [DASHBOARDS_ET_ALERTES.md](DASHBOARDS_ET_ALERTES.md)

---

## 🔗 Ressources

- 🔗 [Documentation Cowrie](https://cowrie.readthedocs.io/)
- 🔗 [Documentation Loki](https://grafana.com/docs/loki/)
- 🔗 [Documentation Grafana](https://grafana.com/docs/grafana/)
- 🔗 [GitHub Cowrie](https://github.com/cowrie/cowrie)

---

## 📞 Support

Pour toute question ou problème :
1. Consulter [INDEX.md](INDEX.md)
2. Voir [TROUBLESHOOTING_AVANCE.md](TROUBLESHOOTING_AVANCE.md)
3. Lire [RAPPORT_HONEYPOT.md](RAPPORT_HONEYPOT.md)

---

## 📄 Licence

Ce projet est fourni à titre éducatif et de sécurité informatique. Utilisez-le uniquement dans un environnement de test ou de recherche approprié.

---

**👉 [Commencez maintenant](DEMARRAGE_RAPIDE.md)**

```bash
sudo bash install-honeypot.sh
```

---

*Honeypot Kali Linux - Cowrie + Loki + Grafana*  
*Documentation complète | Installation facile | Monitoring en temps réel*
