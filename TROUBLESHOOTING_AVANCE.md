# Troubleshooting Avancé et Solutions

## 🔍 Diagnostique Système

### État du système
```bash
# Vérifier la charge système
uptime
free -h
df -h

# Vérifier Docker
docker ps -a
docker stats

# Vérifier les images
docker images

# Vérifier les volumes
docker volume ls
```

---

## 🚨 Problèmes Courants et Solutions

### Problème 1: Cowrie ne démarre pas

**Symptômes**: `bin/cowrie start` reste suspendu ou retourne une erreur

**Diagnostic**:
```bash
cd ~/honeypot/cowrie

# Vérifier les logs
cat var/log/cowrie/cowrie.log

# Vérifier le PID
cat var/run/cowrie.pid

# Vérifier les ports
sudo lsof -i :2222
sudo netstat -tulpn | grep 2222
```

**Solutions**:
```bash
# 1. Vérifier le port 2222 est libreactif
sudo lsof -i :2222 | awk 'NR>1 {print $2}' | xargs kill -9

# 2. Vérifier la configuration
nano etc/cowrie.conf
# S'assurer que [ssh] section a : port = 2222

# 3. Réinitialiser Cowrie
bin/cowrie stop
rm -rf var/run/
bin/cowrie start

# 4. Vérifier les droits
ls -la ~/.ssh
```

---

### Problème 2: Aucun log n'apparaît dans Loki/Grafana

**Symptômes**: 
- Aucun résultat quand on fait une requête `{job="cowrie"}`
- Grafana vierge même après 1 heure

**Diagnostic**:
```bash
# 1. Vérifier que Cowrie génère des logs
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json | head -3

# Si vide:
# Essayer une connexion SSH
ssh -p 2222 test@localhost
# pwd: abcd

# 2. Vérifier que Loki reçoit les données
curl -s http://localhost:3100/loki/api/v1/labels | jq

# 3. Vérifier la connectivité Docker
docker exec loki-honeypot curl -s http://localhost:3100/loki/api/v1/query?query={job=\"cowrie\"}

# 4. Vérifier les logs Docker
docker logs loki-honeypot
docker logs grafana-honeypot
```

**Solutions**:
```bash
# 1. Redémarrer les services complètement
docker-compose down
docker-compose up -d

# Attendre 30 secondes que les services démarrent

# 2. Vérifier la connexion réseau Docker
docker inspect honeypot_honeypot-network

# 3. Permuter la source de données Loki dans Grafana (re-test)

# 4. Vérifier les permissions de fichier
chmod 644 ~/honeypot/cowrie/var/log/cowrie/cowrie.json
```

---

### Problème 3: Erreur "Port already in use"

**Symptômes**: 
```
Error: address already in use
ERROR: for grafana-honeypot cannot assign requested address
```

**Diagnostic**:
```bash
# Vérifier quel processus utilise le port
sudo lsof -i :3000
sudo lsof -i :3100
sudo lsof -i :2222

# Avec netstat
sudo netstat -tulpn | grep LISTEN
```

**Solutions**:
```bash
# Option 1: Tuer le processus conflictuel
sudo kill -9 <PID>

# Option 2: Changer le port dans docker-compose.yml
# Remplacer "3000:3000" par "3001:3000"

# Option 3: Libérer manuellement le port
# Redémarrer le service conflictuel ou reboot

# Option 4: Vérifier les conteneurs zombies
docker container prune
docker volume prune
```

---

### Problème 4: Ressources insuffisantes (Loki/Grafana lents)

**Symptômes**:
- Grafana répond très lentement
- Timeouts lors des queries
- CPU/RAM à 100%

**Diagnostic**:
```bash
# Vérifier l'utilisation réelle
docker stats
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Vérifier l'espace disque
df -h
du -sh /var/lib/docker/volumes/*/

# Vérifier les logs d'erreur
docker logs loki-honeypot | tail -50
docker logs grafana-honeypot | tail -50
```

**Solutions**:
```bash
# 1. Augmenter les limites dans docker-compose.yml
services:
  loki:
    mem_limit: 4g
    cpus: "2.0"
  grafana:
    mem_limit: 2g
    cpus: "1.0"

# 2. Ajouter du swap si nécessaire
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 3. Nettoyer les anciens logs
find ~/honeypot/cowrie/var/log -type f -mtime +30 -delete

# 4. Réduire la rétention Loki
# Dans loki-config.yml: retention_period: 14d (au lieu de 30d)
```

---

### Problème 5: Grafana ne se connecte pas à Loki

**Symptômes**:
- Datasource Loki: "HTTP Error Bad Gateway"
- Erreur: "Cannot reach http://loki:3100"

**Diagnostic**:
```bash
# 1. Vérifier que Loki est en cours d'exécution
docker ps | grep loki

# 2. Vérifier la santé de Loki
curl -s http://localhost:3100/loki/api/v1/status/ready

# 3. Vérifier le réseau Docker
docker exec grafana-honeypot nslookup loki
docker exec grafana-honeypot curl http://loki:3100/loki/api/v1/labels

# 4. Vérifier les logs
docker logs loki-honeypot | grep -i error
docker logs grafana-honeypot | grep -i loki
```

**Solutions**:
```bash
# 1. Vérifier la configuration du datasource
curl -s http://localhost:3000/api/datasources | jq

# 2. Recréer le datasource:
# Grafana UI → Configuration → Data Sources → Add Loki

# 3. Redémarrer les deux services
docker-compose restart loki grafana

# 4. Vérifier le nom du réseau
docker inspect loki-honeypot | grep NetworkMode
```

---

### Problème 6: SSH n'est pas redirigé vers Cowrie

**Symptômes**:
- `ssh -p 22 localhost` ouvre une vraie session SSH
- Les logs Cowrie ne capturent rien

**Diagnostic**:
```bash
# Vérifier les règles iptables
sudo iptables -t nat -L -n

# Vérifier que Cowrie écoute sur 2222
sudo netstat -tulpn | grep 2222
sudo lsof -i :2222

# Essayer une connexion directe
ssh -v -p 2222 test@localhost
```

**Solutions**:
```bash
# 1. Appliquer la redirection iptables
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222

# 2. Rendre les règles permanentes
sudo apt install -y iptables-persistent
sudo netfilter-persistent save

# 3. Vérifier avec UFW
sudo ufw allow 2222/tcp
sudo ufw allow 22/tcp

# 4. Si SSH standard est en conflit, le désactiver
sudo systemctl stop ssh
sudo systemctl disable ssh

# 5. Vérifier que Cowrie est bien démarré
cd ~/honeypot/cowrie && bin/cowrie status

# 6. Tester la redirection
ssh -p 22 test@localhost -o ConnectTimeout=5
```

---

### Problème 7: Docker-compose ne démarre pas

**Symptômes**:
```
ERROR: Cannot connect to Docker daemon
ERROR: Couldn't connect to Docker socket at...
```

**Diagnostic**:
```bash
# Vérifier que Docker est en cours d'exécution
sudo systemctl status docker
docker ps

# Vérifier les logs Docker
sudo journalctl -u docker -n 50

# Vérifier les permissions
groups $USER
ls -la /var/run/docker.sock
```

**Solutions**:
```bash
# 1. Redémarrer Docker
sudo systemctl restart docker

# 2. Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker
logout
login

# 3. Vérifier le docker-compose.yml
docker-compose config

# 4. Recucbler l'installation Docker
docker system prune
docker-compose build --no-cache

# 5. Voir les détails d'erreur
docker-compose logs
```

---

### Problème 8: Diskspace rempli par les logs

**Symptômes**:
- `df -h` montre 100% utilisé
- Les services ne peuvent plus écrire

**Diagnostic**:
```bash
# Trouver les gros fichiers
du -sh /* | sort -rh | head -10

# Vérifier la taille des logs Cowrie
du -sh ~/honeypot/cowrie/var/log/

# Vérifier la taille des volumes Docker
du -sh /var/lib/docker/volumes/*/

# Vérifier les gros fichiers individuels
find ~/honeypot -type f -size +100M
```

**Solutions**:
```bash
# 1. Compresser et archiver les vieux logs
tar -czf ~/honeypot/logs-archive-$(date +%Y%m%d).tar.gz ~/honeypot/cowrie/var/log/cowrie/*.json.*

# 2. Supprimer les logs de plus de 7 jours
find ~/honeypot/cowrie/var/log -type f -mtime +7 -delete

# 3. Nettoyer les conteneurs/volumes inutilisés
docker container prune
docker volume prune
docker system prune

# 4. Augmenter l'espace disque (si possible)
# Ajouter un disque supplémentaire à la VM

# 5. Réduire la rétention Loki
# Éditer loki-config.yml et réduire retention_period
```

---

## 🔧 Commandes de Diagnostic Avancées

### Inspection Loki
```bash
# Vérifier la santé de Loki
curl -v http://localhost:3100/loki/api/v1/status/ready

# Voir les jobs disponibles
curl -s http://localhost:3100/loki/api/v1/label/job/values | jq

# Voir les labels disponibles
curl -s http://localhost:3100/loki/api/v1/labels | jq

# Compter les entrées
curl -s 'http://localhost:3100/loki/api/v1/query?query=count({job="cowrie"})' | jq

# Voir la taille du stockage Loki
du -sh /var/lib/docker/volumes/*loki*/
```

### Inspection Grafana
```bash
# Lister les datasources
curl -s -H "Authorization: Bearer $(grabtoken)" http://localhost:3000/api/datasources | jq

# Lister les dashboards
curl -s http://localhost:3000/api/search | jq

# Exporter un dashboard
curl -s http://localhost:3000/api/dashboards/db/<slug> | jq > dashboard.json

# Health check
curl -s http://localhost:3000/api/health | jq
```

### Inspection Cowrie
```bash
# Voir les statistiques de session
jq '.session' ~/honeypot/cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | tail -20

# Voir les adresses IP actives
jq '.src_ip' ~/honeypot/cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | sort -rn | head -20

# Voir les commandes dangereuses exécutées
jq 'select(.eventid == "cowrie.command.input" and (.input | contains("rm ") or contains("dd ") or contains("> "))) | .input' ~/honeypot/cowrie/var/log/cowrie/cowrie.json
```

---

## 📊 Configuration d'Alertes Avancées

### Alerte: Croissance d'activité suspecte
```yaml
Alert Rule: suspicious_growth
Condition: rate({job="cowrie"}[1h]) > rate({job="cowrie"}[24h:1h]) * 5
Meaning: Si le taux d'activité dernière 1h dépasse 5x la normale
```

### Alerte: Pattern d'attaque connu
```yaml
Alert Rule: known_pattern
Condition: {job="cowrie"} | json | username="admin" | password="admin"
Meaning: L'une des tentatives les plus faciles
```

### Alerte: Activité en dehors des heures
```yaml
Alert Rule: off_hours_activity
Condition: (hour(timestamp) > 22 OR hour(timestamp) < 6) AND count({job="cowrie"}) > 5
Meaning: Attaques entre 22h et 6h du matin
```

---

## 🔐 Sécurité du Honeypot

### Points de sécurité critiques
```bash
# 1. Changer le mot de passe Grafana
docker exec grafana-honeypot grafana-cli admin reset-admin-password NewSecurePassword

# 2. Activer HTTPS sur Grafana
# Éditer docker-compose.yml et ajouter les certificates

# 3. Restreindre l'accès à Grafana
# Utiliser un reverse proxy (nginx) avec authentification

# 4. Monitorer les accès Grafana
docker logs grafana-honeypot | grep LOGIN

# 5. Archiver et protéger les données
tar -czf backup-sensitive.tar.gz ~/honeypot/
chmod 600 backup-sensitive.tar.gz
```

---

## 🎯 Performance Tuning

### Loki
```yaml
# Augmenter la performance des reads
cache_config:
  enable_fifo_cache: true
  max_cache_freshness_per_query: 60m

# Augmenter la performance des writes
ingester:
  num_worker_threads: 8
  max_chunk_age: 2h
```

### Grafana
```yaml
# Augmenter les limites
GF_SERVER_MAX_RENDER_ON_THE_FLY_RENDER_TO_DISK_CONCURRENT_LIMIT: 100
GF_PATH_TEMP_PLUGIN_LOG_DIRECTORY: /var/lib/grafana/plugin-logs
```

---

**FIN du troubleshooting avancé.**
