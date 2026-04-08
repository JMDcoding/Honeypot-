# Dashboards et Requêtes Grafana Recommandés

## Dashboard 1 : Vue d'ensemble du Honeypot

### Panel 1.1 : Nombre total de tentatives de connexion

**Titre** : Total des tentatives SSH

**Requête Loki**:
```logql
count(count_over_time({job="cowrie"} | json | eventid=~"cowrie.client.login" [5m])) by()
```

**Visualisation** : Stat (Nombre)

---

### Panel 1.2 : Adresses IP uniques des attaquants

**Titre** : Adresses IP attaquants (dernières 24h)

**Requête Loki**:
```logql
count(count_over_time({job="cowrie"} | json | src_ip != "" [1h])) by(src_ip)
```

**Visualisation** : Table ou Gauge

---

### Panel 1.3 : Timeline des attaques

**Titre** : Tentatives d'accès par heure

**Requête Loki**:
```logql
sum(count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.failed" [1h])) by(bin(1h))
```

**Visualisation** : Graph / Timeseries

---

### Panel 1.4 : Top 10 des usernames testés

**Titre** : Noms d'utilisateur les plus fréquents

**Requête Loki**:
```logql
topk(10, count_over_time({job="cowrie"} | json | username != "" [24h])) by(username)
```

**Visualisation** : Bar chart

---

### Panel 1.5 : Top 10 des mots de passe testés

**Titre** : Mots de passe les plus fréquents

**Requête Loki**:
```logql
topk(10, count_over_time({job="cowrie"} | json | password != "" [24h])) by(password)
```

**Visualisation** : Bar chart

---

## Dashboard 2 : Détails des Connexions

### Panel 2.1 : Connexions réussies

**Titre** : Entrées réussies

**Requête Loki**:
```logql
{job="cowrie"} | json | eventid="cowrie.client.login.success"
| line_format "{{.src_ip}} | {{.username}} | {{.password}} | {{.timestamp}}"
```

**Visualisation** : Logs

---

### Panel 2.2 : Connexions échouées (dernière heure)

**Titre** : Tentatives échouées (dernière heure)

**Requête Loki**:
```logql
{job="cowrie"} | json 
| eventid="cowrie.client.login.failed"
| stats count() as failed_attempts by src_ip
| sort() desc
```

**Visualisation** : Gauge / Stat

---

### Panel 2.3 : Taux de succès vs. Échecs

**Titre** : Ratio Succès/Échecs

**Requête Loki (Success)**:
```logql
sum(count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.success" [24h])) by()
```

**Requête Loki (Failed)**:
```logql
sum(count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.failed" [24h])) by()
```

**Visualisation** : Pie chart

---

## Dashboard 3 : Analyse des Commandes

### Panel 3.1 : Commandes exécutées

**Titre** : Commandes lancées après connexion

**Requête Loki**:
```logql
{job="cowrie"} | json | eventid="cowrie.command.input"
| line_format "{{.src_ip}} | {{.command}} | {{.timestamp}}"
```

**Visualisation** : Logs

---

### Panel 3.2 : Top 15 des commandes

**Titre** : Commandes les plus utilisées

**Requête Loki**:
```logql
topk(15, count_over_time({job="cowrie"} | json | eventid="cowrie.command.input" | command != "" [24h])) by(command)
```

**Visualisation** : Bar chart horizontal

---

### Panel 3.3 : Analyse des sessions

**Titre** : Durée des sessions

**Requête Loki**:
```logql
{job="cowrie"} | json | eventid="cowrie.session.closed"
| duration > 0
| stats avg(duration), min(duration), max(duration) by()
```

**Visualisation** : Stat

---

## Dashboard 4 : Sécurité et Alertes

### Panel 4.1 : Attaques par pays (optionnel - avec GeoIP)

**Titre** : Géolocalisation des attaques

**Requête Loki**:
```logql
{job="cowrie"} | json | src_ip != ""
| stats count() by src_ip
```

**Visualisation** : Worldmap plugin

---

### Panel 4.2 : Indicateur d'alerte : Entrées réussies

**Titre** : ⚠️ Connexions réussies (ALERTE)

**Requête Loki**:
```logql
count(count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.success" [5m])) by()
```

**Visualisation** : Gauge (avec seuil d'alerte > 0)

**Alerte** : "Connexion réussie détectée !"

---

### Panel 4.3 : Activité suspecte (brute force)

**Titre** : Détection du Brute Force

**Requête Loki**:
```logql
sum(count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.failed" [1m])) by(src_ip)
| > 10
```

**Visualisation** : Stat/Alert

**Alerte** : Si plus de 10 tentatives échouées/min depuis la même IP

---

## Dashboard 5 : Analyse des Transferts de Fichiers

### Panel 5.1 : Fichiers téléchargés

**Titre** : Fichiers téléchargés par attaquants

**Requête Loki**:
```logql
{job="cowrie"} | json | eventid="cowrie.session.file_download"
| line_format "{{.src_ip}} | {{.filename}} | {{.filesize}} bytes | {{.timestamp}}"
```

**Visualisation** : Logs

---

### Panel 5.2 : Types de fichiers les plus courants

**Titre** : Extensions de fichiers impliqués

**Requête Loki**:
```logql
{job="cowrie"} | json | eventid="cowrie.session.file_download" | filename != ""
| stats count() by filename
```

**Visualisation** : Pie chart

---

## Configuration des Alertes Grafana

### Alerte 1 : Brute Force Détecté

```yaml
Nom: SSH Brute Force Attack
Condition: Compte: count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.failed" [1m]) > 15
Notification: Email
Message: 🚨 Brute force SSH détecté ! Plus de 15 tentatives échouées en 1 minute
```

### Alerte 2 : Connexion Réussie

```yaml
Nom: Successful SSH Login
Condition: count_over_time({job="cowrie"} | json | eventid="cowrie.client.login.success" [5m]) > 0
Notification: Email + Webhook
Message: 🚨 ALERTE CRITIQUE : Connexion SSH réussie détectée !
Severity: Critical
```

### Alerte 3 : Téléchargement de fichier suspect

```yaml
Nom: File Download Detected
Condition: count_over_time({job="cowrie"} | json | eventid="cowrie.session.file_download" [5m]) > 0
Notification: Email
Message: ⚠️ Téléchargement de fichier détecté sur le honeypot
```

### Alerte 4 : Trop d'erreurs système

```yaml
Nom: High Error Rate
Condition: count_over_time({job="cowrie"} | json | eventid=~"error" [10m]) > 50
Notification: Email
Message: Taux d'erreur élevé détecté
```

---

## Requêtes LogQL Avancées

### Analyse de patterns - Attaques coordonnées

```logql
# Même username/password testé depuis plusieurs IPs
{job="cowrie"} | json 
| username != "" and password != ""
| stats count() as attempts by username, password, src_ip
| > 1
```

### Détection d'attaques automatisées

```logql
# Identifier les attaques à rythme constant
{job="cowrie"} | json 
| eventid="cowrie.client.login"
| stats count() as rate by bin(30s), src_ip
| > 5
```

### Sessions actives en ce moment

```logql
{job="cowrie"} | json 
| eventid=~"cowrie.session.(connect|login|closed)"
| stats count(eventid="cowrie.session.connect") - count(eventid="cowrie.session.closed") as active_sessions by()
```

### Distribution temporelle des attaques

```logql
{job="cowrie"} | json | eventid="cowrie.client.login.failed"
| stats count() by bin(1d), hour(timestamp)
```

### Top attaquants persistants

```logql
{job="cowrie"} | json 
| stats count() as total_attempts, count(eventid="cowrie.client.login.success") as success by src_ip
| total_attempts > 100
```

---

## Tips pour optimiser les Dashboards

1. **Utiliser les variables de Grafana** :
   ```
   $timeRange : Plage de temps sélectionnée
   $interval : Intervalle calculé automatiquement
   ```

2. **Ajouter des filtres dynamiques** :
   ```yaml
   Variables:
     - src_ip : Adresse IP source
     - username : Nom d'utilisateur
     - eventid : Type d'événement
   ```

3. **Exporter/Importer les dashboards JSON** :
   ```bash
   # URL d'export : http://localhost:3000/api/dashboards/uid/<uid>
   curl -s http://localhost:3000/api/dashboards/uid/honeypot | jq > honeypot-dashboard.json
   ```

4. **Ajouter la notation de la date** :
   ```logql
   # Format personnalisé
   | line_format "[{{.timestamp}}] {{.src_ip}} - {{.username}}"
   ```

---

## Resources pour les dashboards

- **Galerie officielle** : https://grafana.com/grafana/dashboards
- **Plugins Grafana** : https://grafana.com/plugins
- **Documentation Loki** : https://grafana.com/docs/loki/latest/
- **LogQL** : https://grafana.com/docs/loki/latest/logql/
