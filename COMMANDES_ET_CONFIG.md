# Commandes et Configuration du Honeypot

## Démarrage et Arrêt

### Démarrer les services Docker (Loki + Grafana)
```bash
cd ~/honeypot
docker-compose up -d
docker-compose ps
```

### Arrêter les services
```bash
docker-compose down
```

### Redémarrer les services
```bash
docker-compose restart
```

---

## Gestion de Cowrie

### Démarrer Cowrie
```bash
cd ~/honeypot/cowrie
source cowrie-venv/bin/activate
bin/cowrie start
```

### Arrêter Cowrie
```bash
cd ~/honeypot/cowrie
source cowrie-venv/bin/activate
bin/cowrie stop
```

### Vérifier l'état de Cowrie
```bash
cd ~/honeypot/cowrie
source cowrie-venv/bin/activate
bin/cowrie status
```

### Voir les logs en temps réel
```bash
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json | jq
```

### Voir les logs texte
```bash
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.log
```

---

## Vérification des Services

### Vérifier que Loki répond
```bash
curl -s http://localhost:3100/loki/api/v1/labels
curl -s http://localhost:3100/api/prom/label/job/values | jq
```

### Vérifier que Grafana répond
```bash
curl -s http://localhost:3000/api/health | jq
```

### État des conteneurs Docker
```bash
docker ps
docker-compose ps
docker stats
```

---

## Tests de Connectivité SSH

### Test local SSH vers Cowrie
```bash
# Port 2222
ssh -p 2222 user@localhost
```

### Test distance SSH vers Cowrie (depuis autre machine)
```bash
ssh -p 22 user@<IP_HONEYPOT>
```

### Script de test : générer plusieurs tentatives
```bash
#!/bin/bash
for i in {1..20}; do
  (echo "password$i"; sleep 0.1) | telnet localhost 2222 &
done
wait
```

---

## Gestion des Logs

### Chercher dans les logs Cowrie
```bash
# Chercher les connexions réussies
grep "login.success" ~/honeypot/cowrie/var/log/cowrie/cowrie.json

# Chercher les adresses IP uniques
jq '.src_ip' ~/honeypot/cowrie/var/log/cowrie/cowrie.json | sort | uniq

# Chercher les noms d'utilisateur testés
jq '.username' ~/honeypot/cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | sort -rn

# Chercher les commandes exécutées
jq 'select(.eventid == "cowrie.command.input") | .input' ~/honeypot/cowrie/var/log/cowrie/cowrie.json
```

### Nettoyer les vieux logs
```bash
# Archiver les logs de plus de 7 jours
find ~/honeypot/cowrie/var/log -type f -mtime +7 -exec gzip {} \;

# Supprimer les logs de plus de 30 jours
find ~/honeypot/cowrie/var/log -type f -mtime +30 -delete
```

---

## Requêtes Loki pour Grafana

### Voir toutes les entrées
```logql
{job="cowrie"}
```

### Tentatives de connexion réussies
```logql
{job="cowrie"} | json | eventid="cowrie.client.login.success"
```

### Tentatives de connexion échouées
```logql
{job="cowrie"} | json | eventid="cowrie.client.login.failed"
```

### Commandes exécutées
```logql
{job="cowrie"} | json | eventid="cowrie.command.input" | input !=""
```

### Transferts de fichiers
```logql
{job="cowrie"} | json | eventid="cowrie.session.file_download"
```

### Adresses IP uniques
```logql
{job="cowrie"} | json | src_ip != "" | __line__ != ""
```

### Motifs d'attaques SSH
```logql
{job="cowrie"} | json | username != "" | password != ""
| stats count() as total by username, password
```

### Timeline des attaques
```logql
{job="cowrie"} | json 
| eventid="cowrie.client.login"
| stats count() as attempts by bin(5m)
```

---

## Configuration des Alertes Grafana

### Ajouter une notification par email

1. Aller dans : **Configuration** → **Notification channels**
2. Cliquer : **New channel**
3. Configurer :
   - Type: **Email**
   - Email addresses: votre@email.com
   - Cliquer : **Test** et **Save**

### Créer une alerte : Plus de 10 tentatives échouées/5 min

1. Dans un dashboard, ajouter un panel
2. Écrire la requête :
   ```logql
   {job="cowrie"} | json 
   | eventid="cowrie.client.login.failed"
   | stats count() by bin(5m)
   ```
3. Aller dans : **Alert** tab
4. Configurer :
   - Condition: `WHEN count() > 10 FOR 5m THEN ALERTING`
   - Message: "Attaque SSH détectée sur le honeypot"
   - Send to: votre email

---

## Maintenance

### Changer le mot de passe Grafana
```bash
# Via l'interface web : Configuration → User settings
# Ou via la CLI Docker :
docker exec -it grafana-honeypot grafana-cli admin reset-admin-password new_password
```

### Mise à jour des images Docker
```bash
docker pull grafana/loki:latest
docker pull grafana/grafana:latest
docker-compose up -d
```

### Backup des données Grafana
```bash
# Sauvegarder les dashboards
docker cp grafana-honeypot:/var/lib/grafana ./grafana-backup-$(date +%Y%m%d)
```

### Restaurer les données Grafana
```bash
docker cp ./grafana-backup /grafana-honeypot:/var/lib/grafana
docker-compose restart grafana
```

---

## Troubleshooting

### Aucun log n'apparaît dans Grafana

```bash
# 1. Vérifier que Cowrie fonctionne
cd ~/honeypot/cowrie && bin/cowrie status

# 2. Vérifier que les logs JSON sont générés
ls -la ~/honeypot/cowrie/var/log/cowrie/

# 3. Vérifier la connectivité Loki
docker logs loki-honeypot

# 4. Vérifier les datasources Grafana
curl -s http://localhost:3000/api/datasources | jq

# 5. Redémarrer les services
docker-compose restart
```

### Erreur de permission Docker

```bash
# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Appliquer les changements
newgrp docker

# Vérifier
docker ps
```

### Port déjà utilisé

```bash
# Voir quels ports sont utilisés
netstat -tulpn | grep LISTEN

# Trouver le processus utilisant le port
lsof -i :3000
lsof -i :3100

# Terminer le processus
kill -9 <PID>
```

### Docker Compose ne démarre pas

```bash
# Vérifier les erreurs
docker-compose logs

# Vérifier la syntaxe YAML
docker-compose config

# Reconstruire les images
docker-compose build --no-cache
```

---

## Monitoring Avancé

### Installation de Prometheus (optionnel)

```yaml
# Ajouter à docker-compose.yml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
```

### Installation de Alertmanager (optionnel)

```yaml
# Ajouter à docker-compose.yml
alertmanager:
  image: prom/alertmanager:latest
  ports:
    - "9093:9093"
  volumes:
    - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
```

---

## Performance et Optimisation

### Augmenter les limite de ressources

```bash
# Éditer docker-compose.yml et ajouter :
services:
  loki:
    mem_limit: 2g
    cpus: "1.0"
  grafana:
    mem_limit: 1g
    cpus: "0.5"
```

### Vérifier l'utilisation des ressources

```bash
docker stats

# Format détaillé
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Archivage des logs anciens

```bash
# Créer un script de compression mensuelle
cat > ~/honeypot/archive-logs.sh << 'EOF'
#!/bin/bash
LOGDIR="$HOME/honeypot/cowrie/var/log/cowrie"
ARCHIVEDIR="$HOME/honeypot/cowrie/var/log/archive"
mkdir -p $ARCHIVEDIR

tar -czf $ARCHIVEDIR/cowrie-$(date +\%Y-\%m).tar.gz $LOGDIR/
find $ARCHIVEDIR -name "*.tar.gz" -mtime +365 -delete
EOF

chmod +x ~/honeypot/archive-logs.sh

# Ajouter à crontab (exécuter le 1er de chaque mois à minuit)
# 0 0 1 * * $HOME/honeypot/archive-logs.sh
```

---

## Références Utiles

- Documentation Cowrie : https://cowrie.readthedocs.io/
- Documentation Loki : https://grafana.com/docs/loki/
- Documentation Grafana : https://grafana.com/docs/grafana/
- LogQL Query Language : https://grafana.com/docs/loki/latest/logql/
