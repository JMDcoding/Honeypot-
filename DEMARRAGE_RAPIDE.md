# Démarrage Rapide - Honeypot Kali Linux

## 🚀 En 5 minutes

### Étape 1 : Préparation (2 minutes)

```bash
# Se connecter en SSH à Kali Linux
ssh user@kali-ip

# Cloner/télécharger ce dossier
git clone <repo-url> ~/honeypot
cd ~/honeypot

# Procurer les droits d'exécution au script
chmod +x install-honeypot.sh
```

### Étape 2 : Installation automatisée (2 minutes)

```bash
# Lancer l'installation automatisée
sudo bash install-honeypot.sh

# Attendre la fin (affichera un résumé)
```

### Étape 3 : Démarrer Cowrie (1 minute)

```bash
cd ~/honeypot/cowrie

# Activer l'environnement virtuel
source cowrie-venv/bin/activate

# Lancer Cowrie
bin/cowrie start

# Vérifier le démarrage
bin/cowrie status

# Voir les logs
tail -f var/log/cowrie/cowrie.json | jq
```

---

## ✅ Vérifier que tout fonctionne

### Accéder à Grafana

```
http://localhost:3000
Utilisateur: admin
Mot de passe: admin123
```

### Accéder à Loki

```
http://localhost:3100/loki/api/v1/labels
```

### Tester SSH

```bash
# Depuis la même machine
ssh -p 2222 testuser@localhost
# Mot de passe : n'importe lequel

# Depuis une autre machine
ssh -p 22 testuser@<IP_KALI>
```

### Voir les logs capturés

```bash
# Requête directe à Loki
curl http://localhost:3100/loki/api/v1/query?query={job=\"cowrie\"}

# Ou dans Grafana : Explore → selecteur Loki
```

---

## 📋 Checklist de Configuration

- [ ] Docker et Docker Compose installés
- [ ] Loki en cours d'exécution (port 3100)
- [ ] Grafana en cours d'exécution (port 3000)
- [ ] Cowrie en cours d'exécution (port 2222)
- [ ] Ports SSH redirects (port 22 → 2222)
- [ ] Passwordégé Grafana changé
- [ ] Datasource Loki ajoutée dans Grafana
- [ ] Dashboard créé dans Grafana

---

## 🔑 Identifiants par défaut

| Service | URL | Utilisateur | Mot de passe |
|---------|-----|-------------|-------------|
| **Grafana** | http://localhost:3000 | admin | admin123 |
| **Loki API** | http://localhost:3100 | - | - |
| **Cowrie SSH** | Port 2222 | test | n'importe quel |

**⚠️ IMPORTANT** : Changer les mots de passe par défaut !

---

## 📁 Structure des fichiers

```
~/honeypot/
├── cowrie/                      # Dossier Cowrie
│   ├── bin/cowrie               # Exécutable
│   ├── etc/cowrie.conf          # Configuration
│   ├── var/log/cowrie/          # Logs JSON et texte
│   └── cowrie-venv/             # Environnement Python
│
├── loki-config/
│   └── loki-config.yml          # Configuration Loki
│
├── docker-compose.yml           # Services Loki + Grafana
├── install-honeypot.sh          # Script d'installation
├── RAPPORT_HONEYPOT.md          # Rapport complet
├── COMMANDES_ET_CONFIG.md       # Commandes utiles
└── DASHBOARDS_ET_ALERTES.md     # Dashboards Grafana
```

---

## 🔧 Commandes essentielles

```bash
# Voir les logs en temps réel
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json | jq

# Redémarrer tous les services
docker-compose restart

# Arrêter tous les services
docker-compose down

# Voir l'état des conteneurs
docker ps

# Vérifier les ressources utilisées
docker stats

# Redémarrer Cowrie
cd cowrie && source cowrie-venv/bin/activate && bin/cowrie restart
```

---

## 🐛 Dépannage rapide

### Problème: Pas de logs dans Grafana

```bash
# 1. Vérifier Cowrie
cd ~/honeypot/cowrie && bin/cowrie status

# 2. Vérifier Loki
curl http://localhost:3100/loki/api/v1/labels

# 3. Redémarrer
docker-compose restart
```

### Problème: Port déjà utilisé

```bash
# Identifier le processus
lsof -i :3000  # Grafana
lsof -i :3100  # Loki
lsof -i :2222  # Cowrie

# Terminer le processus
kill -9 <PID>
```

### Problème: Docker permission denied

```bash
# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker
```

---

## 📊 Premières étapes dans Grafana

### 1. Ajouter Loki comme datasource

- Configuration → Data Sources → Add data source
- Type: Loki
- URL: `http://loki:3100`
- Save & Test

### 2. Créer un simple dashboard

- Bouton "+" → Dashboard → New Panel
- Requête LogQL: `{job="cowrie"}`
- Exécuter (play button)
- Save

### 3. Créer une première alerte

- Panel → Alert tab → Create alert
- Si plus de 10 tentatives SSH/5min → Envoyer email

---

## 📈 Indicateurs à surveiller

| Métrique | Valeur normale | Alerte |
|----------|---|---|
| Tentatives de connexion échouées | < 50 /jour | > 1000 /jour |
| Adresses IP uniques | < 10 /jour | > 100 /jour |
| Connexions réussies | 0 | > 0 |
| Fichiers téléchargés | 0 | > 0 |

---

## 🛡️ Recommandations de sécurité

1. **Isoler le honeypot** en réseau si possible
2. **Changer les mots de passe** (Grafana, etc.)
3. **Utiliser un firewall** pour restreindre l'accès
4. **Mettre à jour régulièrement** Docker images
5. **Surveiller les ressources** (disk, RAM)
6. **Faire des backups** des dashboards et configs

---

## 📞 Support et ressources

- **Documentation Cowrie** : https://cowrie.readthedocs.io/
- **Documentation Loki** : https://grafana.com/docs/loki/
- **Documentation Grafana** : https://grafana.com/docs/grafana/
- **GitHub Cowrie** : https://github.com/cowrie/cowrie

---

## ❓ FAQ

**Q: Puis-je accéder à Grafana depuis l'extérieur ?**
R: Oui, mais protégez-le avec un reverse proxy (nginx) et SSL/TLS.

**Q: Qu'advient-il des données capturées ?**
R: Elles sont stockées dans Loki et indexées pour l'analyse dans Grafana.

**Q: Combien d'espace disque est nécessaire ?**
R: Dépend du volume d'attaques. Comptez 10-20 GB pour 1 mois de données.

**Q: Peut-on déplacer le honeypot sur une autre machine ?**
R: Oui, simplement copier le dossier `~/honeypot` et exécuter `install-honeypot.sh`.

---

## 🎓 Prochaines étapes

1. ✅ **Démarrage** : Suivre ce guide
2. 📖 **Approfondir** : Lire le rapport complet (`RAPPORT_HONEYPOT.md`)
3. 🛠️ **Configurer** : Utiliser les commandes dans `COMMANDES_ET_CONFIG.md`
4. 📊 **Analyser** : Créer des dashboards avec `DASHBOARDS_ET_ALERTES.md`
5. 🔐 **Sécuriser** : Applauir les recommandations de sécurité

---

**Prêt à commencer ?** 🚀

```bash
chmod +x install-honeypot.sh
sudo bash install-honeypot.sh
```
