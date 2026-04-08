# Rapport : Mise en place d'un Piège à Intrusion avec Cowrie, Loki et Grafana

**Date:** Avril 2026  
**OS:** Kali Linux  
**Objectif:** Installation et configuration d'une architecture de honeypot pour la détection et l'analyse des menaces réseau

---

## Table des matières

1. [Introduction](#introduction)
2. [Architecture du système](#architecture-du-système)
3. [Prérequis](#prérequis)
4. [Installation de Cowrie](#installation-de-cowrie)
5. [Configuration de Loki](#configuration-de-loki)
6. [Configuration de Grafana](#configuration-de-grafana)
7. [Intégration et monitoring](#intégration-et-monitoring)
8. [Tests et validation](#tests-et-validation)
9. [Maintenance et sécurité](#maintenance-et-sécurité)

---

## Introduction

### Objectif du honeypot

Un **piège à intrusion (honeypot)** est un système informatique intentionnellement vulnérable conçu pour :
- Tromper les attaquants et les faire croire qu'il s'agit d'un système réel
- Capturer et analyser les tentatives d'intrusion
- Collecter des données sur les méthodes d'attaque
- Renforcer la détection de menaces

### Composants utilisés

- **Cowrie** : Honeypot SSH/Telnet qui enregistre les interactions
- **Loki** : Agrégateur de logs décentralisé pour collecter les données
- **Grafana** : Plateforme de visualisation et d'alertes

---

## Architecture du système

```
┌─────────────────────────────────────────────┐
│         Attaquants externes                  │
└───────────────────┬─────────────────────────┘
                    │
        ┌───────────▼──────────┐
        │   Cowrie Honeypot    │
        │  (SSH/Telnet 22/23)  │
        └───────────┬──────────┘
                    │
        ┌───────────▼──────────────┐
        │   Loki (Log Aggregator)  │
        │   Port 3100               │
        └───────────┬──────────────┘
                    │
        ┌───────────▼──────────────┐
        │   Grafana Dashboard     │
        │   Port 3000              │
        └──────────────────────────┘
```

### Flux de données

1. **Cowrie** : Capture les tentatives d'accès SSH/Telnet
2. **Logs JSON** : Génère des logs structurés
3. **Loki** : Agrège et indexe les logs
4. **Grafana** : Visualise et alerte sur les incidents

---

## Prérequis

### Configuration système minimale

```
- OS : Kali Linux (version récente)
- RAM : 4 Go minimum (8 Go recommandé)
- Disque : 20 Go libre
- Réseau : Accès internet et connectivité réseau locale
```

### Paquets requis

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Paquets système
sudo apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  git \
  wget \
  curl \
  build-essential \
  libssl-dev \
  libffi-dev \
  docker.io \
  docker-compose
```

### Démarrage des services

```bash
# Activer Docker
sudo systemctl enable docker
sudo systemctl start docker

# Vérifier Docker
docker --version
docker ps
```

---

## Installation de Cowrie

### Étape 1 : Cloner le dépôt Cowrie

```bash
# Créer un répertoire dédié
mkdir -p ~/honeypot
cd ~/honeypot

# Cloner le dépôt Cowrie
git clone https://github.com/cowrie/cowrie.git
cd cowrie
```

### Étape 2 : Setup environnement Python

```bash
# Créer un environnement virtuel
python3 -m venv cowrie-venv

# Activer l'environnement
source cowrie-venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt
```

### Étape 3 : Configuration de Cowrie

**Fichier : `cowrie/etc/cowrie.conf`**

```ini
[honeypot]
hostname = linux-server
# Interface à surveiller
listen_addresses = 0.0.0.0
listen_port = 2222

[ssh]
version = OpenSSH_7.4
port = 2222
# Permet les connexions même avec les mauvaises identifiants
# (simulation d'un serveur compromis)

[telnet]
enabled = false

[output_cowrie]
enabled = true

# Configuration du logging JSON pour Loki
[output_jsonlog]
enabled = true
logfile = var/log/cowrie/cowrie.json

# Autre sortie importante
[output_textlog]
enabled = true
```

### Étape 4 : Redirection des ports

```bash
# Rediriger le port 22 (SSH) vers le port 2222 (Cowrie)
# Option 1 : Utiliser iptables
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222

# Option 2 : Utiliser ufw
sudo ufw allow 2222/tcp
sudo ufw allow 22/tcp
```

### Étape 5 : Lancer Cowrie

```bash
# Depuis le répertoire cowrie avec environnement virtuel activé
bin/cowrie start

# Vérifier l'état
bin/cowrie status

# Voir les logs
tail -f var/log/cowrie/cowrie.log
tail -f var/log/cowrie/cowrie.json
```

---

## Configuration de Loki

### Étape 1 : Installation de Loki avec Docker

```bash
# Créer un répertoire pour Loki
mkdir -p ~/honeypot/loki-config
cd ~/honeypot/loki-config

# Créer le fichier de configuration
nano loki-config.yml
```

**Fichier : `loki-config.yml`**

```yaml
auth_enabled: false

ingester:
  chunk_idle_period: 3m
  chunk_retain_period: 1m
  max_chunk_age: 1h
  chunk_encoding: gzip

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

schema_config:
  configs:
  - from: 2020-10-24
    store: boltdb-shipper
    object_store: filesystem
    schema:
      version: v11
      index:
        prefix: index_
        period: 24h
    row_shards: 16

server:
  http_listen_port: 3100
  log_level: info

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
```

### Étape 2 : Lancer Loki avec Docker Compose

**Fichier : `docker-compose.yml`** (dans le répertoire honeypot)

```yaml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config/loki-config.yml:/etc/loki/local-config.yaml
      - loki-storage:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - honeypot-network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_SECURITY_ADMIN_USER=admin
    volumes:
      - grafana-storage:/var/lib/grafana
    depends_on:
      - loki
    networks:
      - honeypot-network

volumes:
  loki-storage:
  grafana-storage:

networks:
  honeypot-network:
    driver: bridge
```

### Étape 3 : Démarrer les conteneurs

```bash
cd ~/honeypot

# Lancer les services
docker-compose up -d

# Vérifier les logs
docker-compose logs -f

# Vérifier les services
docker ps
```

---

## Configuration de Grafana

### Étape 1 : Accès initial

```
URL : http://localhost:3000
Utilisateur par défaut : admin
Mot de passe par défaut : admin (devrait être changé)
```

### Étape 2 : Ajouter Loki comme source de données

1. **Aller dans** : Configuration → Data Sources
2. **Cliquer** : Add data source
3. **Sélectionner** : Loki
4. **Configurer** :
   - Name : `Loki-Honeypot`
   - URL : `http://loki:3100`
   - Cliquer : Save & Test

### Étape 3 : Créer des dashboards

**Dashboard 1 : Vue d'ensemble**

```
Nom : Honeypot Overview
Requête Loki :
  {job="cowrie"}
  
Panneaux à ajouter :
- Nombre total de tentatives de connexion
- Adresses IP uniques des attaquants
- Noms d'utilisateur utilisés
- Mots de passe testés
- Timeline des attaques
```

**Exemple de requête Loki :**

```logql
# Tentatives de connexion réussies
{job="cowrie"} | json | eventid="cowrie.client.login.success"

# Tentatives échouées
{job="cowrie"} | json | eventid="cowrie.client.login.failed"

# Commandes exécutées
{job="cowrie"} | json | eventid="cowrie.command.input"

# Transferts de fichiers
{job="cowrie"} | json | eventid="cowrie.session.file_download"
```

### Étape 4 : Configurer des alertes

1. **Créer une alerte** si plus de 10 tentatives de connexion échouées en 5 minutes
2. **Notification** : Email ou webhook
3. **Détecte** les patterns d'attaque

---

## Intégration et monitoring

### Configuration du Promtail (optionnel - pour la collecte directe)

**Fichier : `promtail-config.yml`**

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: cowrie
    static_configs:
      - targets:
          - localhost
        labels:
          job: cowrie
          __path__: /home/*/honeypot/cowrie/var/log/cowrie/cowrie.json
    json:
      timestamp:
        parse_from: timestamp
        location: UTC
      output_format: json
```

### Vérification des logs

```bash
# Vérifier les logs Cowrie
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json

# Requête directe à Loki
curl -s "http://localhost:3100/loki/api/v1/query?query={job=\"cowrie\"}" | jq

# Vérifier Grafana
curl -s http://localhost:3000/api/health
```

---

## Tests et validation

### Test 1 : Tentative SSH

```bash
# Depuis une autre machine
ssh -p 22 ubuntu@<IP_HONEYPOT>

# Depuis la machine locale (si accès)
ssh -p 2222 test@localhost
```

### Test 2 : Vérifier la capture

```bash
# Vérifier la capture dans Cowrie
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json | jq

# Vérifier dans Grafana
# Aller sur : http://localhost:3000/dashboard
# Chercher d'explorer Loki
```

### Test 3 : Simulation d'attaques

```bash
# Script de test (avec precaution)
for i in {1..10}; do
  ssh -p 22 user$i@localhost "echo test" 2>&1 &
done

# Vérifier les logs générés
tail -f ~/honeypot/cowrie/var/log/cowrie/cowrie.json
```

---

## Maintenance et sécurité

### Recommandations de sécurité

1. **Isoler le honeypot** en réseau si possible
2. **Changer les identifiants par défaut** (Grafana, etc.)
3. **Utiliser des certificats SSL/TLS** pour Grafana et Loki
4. **Mettre en place un firewall** pour restreindre l'accès
5. **Mettre à jour régulièrement** tous les composants
6. **Monitorer les ressources** (CPU, mémoire, disque)

### Maintenance régulière

```bash
# Mettre à jour Docker images
docker pull grafana/loki:latest
docker pull grafana/grafana:latest
docker-compose up -d

# Nettoyer les vieux logs
find ~/honeypot/cowrie/var/log -type f -mtime +30 -delete

# Backup des données Grafana
docker cp honeypot_grafana_1:/var/lib/grafana ~/honeypot/grafana-backup
```

### Rotation des logs

```bash
# Ajouter à crontab
crontab -e

# Ajouter cette ligne pour archiver les logs mensuels
0 0 1 * * tar -czf ~/honeypot/logs/cowrie-$(date +\%Y-\%m).tar.gz ~/honeypot/cowrie/var/log/cowrie/
```

---

## Statistiques et métriques clés à surveiller

| Métrique | Description | Seuil d'alerte |
|----------|-------------|-----------------|
| Tentatives SSH échouées | Nombre de connexions SSH rejetées | > 50/heure |
| Adresses IP uniques | Nombre d'attaquants différents | > 20/jour |
| Utilisateurs testés | Noms d'utilisateur utilisés | Tous les logs |
| Commandes exécutées | Interactions post-compromission | Tous les logs |
| Transferts de fichiers | Fichiers téléchargés par attaquants | Tous les logs |
| Latence Loki | Délai d'ingestion des logs | < 1s |

---

## Troubleshooting

### Problème : Pas de logs dans Loki

```bash
# Vérifier l'état de Cowrie
~/honeypot/cowrie/bin/cowrie status

# Vérifier la connectivité Loki
curl -s http://localhost:3100/loki/api/v1/labels

# Vérifier les logs Docker
docker-compose logs loki
```

### Problème : Grafana ne se connecte pas à Loki

```bash
# Vérifier les logs Grafana
docker-compose logs grafana

# Vérifier la liaison réseau
docker network inspect honeypot_honeypot-network

# Redémarrer les services
docker-compose restart
```

### Problème : Utilisation excessive de ressources

```bash
# Vérifier l'utilisation Docker
docker stats

# Limiter les ressources dans docker-compose
# Ajouter : mem_limit: 2g, cpus: "1.0"
```

---

## Conclusion

Cette architecture offre une solution complète de détection d'intrusions basée sur un honeypot SSH/Telnet, avec agrégation des logs et visualisation en temps réel. Elle permet de :

✅ Capturer les attaques automatisées  
✅ Analyser les patterns d'attaque  
✅ Générer des alertes en temps réel  
✅ Maintenir un historique d'incidents  
✅ Renforcer la posture de sécurité réseau  

---

**Auteur :** Rapport technique sécurité  
**Date :** Avril 2026  
**Version :** 1.0
