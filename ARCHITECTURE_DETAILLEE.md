# Architecture Détaillée du Honeypot

## 🏗️ Diagramme d'Architecture Complète

```
┌────────────────────────────────────────────────────────────────────┐
│                    RÉSEAU EXTERNE (Internet)                        │
│                                                                     │
│  [Attaquant 1]  [Attaquant 2]  [Attaquant 3] ... [Attaquant N]     │
└────────────────────────────────────┬────────────────────────────────┘
                                     │
                                     │ SSH Connexion
                                     │ Port 22 (public)
                                     ▼
┌────────────────────────────────────────────────────────────────────┐
│                    KALI LINUX SERVER (Honeypot)                     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Network Layer                                                │  │
│  │                                                              │  │
│  │  Port 22 (SSH)   ──────────┐                               │  │
│  │  Port 2222       ────────┐  │  [iptables/ufw]              │  │
│  │  Port 3000       ┐       │  │                              │  │
│  │  Port 3100       │       │  │                              │  │
│  └──────────────────┼───────┼──┼──────────────────────────────┘  │
│                     │       │  │                                  │
│  ┌──────────────────▼───────▼──▼──────────────────────────────┐  │
│  │ Cowrie Honeypot (Application)                             │  │
│  │                                                            │  │
│  │  Protocol Handler:                                        │  │
│  │  ┌────────────────────────────────────────────────┐      │  │
│  │  │ SSH Server (Port 2222)                        │      │  │
│  │  │ - Capturer les tentatives de connexion       │      │  │
│  │  │ - Faux système(interactive)                  │      │  │
│  │  │ - Enregistrer les commandes                  │      │  │
│  │  └────────────────────────────────────────────────┘      │  │
│  │                      ▼                                    │  │
│  │  Event Generator:                                        │  │
│  │  - cowrie.client.login.{success,failed,attempt}         │  │
│  │  - cowrie.command.input/output                          │  │
│  │  - cowrie.session.{connect,login,closed}               │  │
│  │  - cowrie.session.file_download                         │  │
│  │                      ▼                                    │  │
│  │  Log Output:                                             │  │
│  │  ┌────────────────────────────────────────────────┐      │  │
│  │  │ Fichiers de log                               │      │  │
│  │  │ - cowrie.json (format JSON structuré)       │      │  │
│  │  │ - cowrie.log (format texte)                 │      │  │
│  │  └────────────────────────────────────────────────┘      │  │
│  └───────────────┬──────────────────────────────────────────┘  │
│                  │                                             │
│  ┌───────────────▼──────────────────────────────────────────┐  │
│  │ Log Aggregation (Loki)                                  │  │
│  │                                                          │  │
│  │ Ingester Component:                                     │  │
│  │ ┌──────────────────────────────────────────────────┐   │  │
│  │ │ JSON Parser                                      │   │  │
│  │ │ - Lecture des logs JSON                         │   │  │
│  │ │ - Extraction des labels (timestamp, eventid, ..)│   │  │
│  │ │ - Indexation des métadonnées                    │   │  │
│  │ └──────────────────────────────────────────────────┘   │  │
│  │                      ▼                                  │  │
│  │ Chunk Manager:                                         │  │
│  │ - Compression GZIP des données                        │  │
│  │ - Stockage en chunks (max 256MB /défaut)             │  │
│  │ - TTL des logs (configurable)                        │  │
│  │                      ▼                                  │  │
│  │ Storage Backend:                                       │  │
│  │ ┌──────────────────────────────────────────────────┐   │  │
│  │ │ BoltDB Shipper                                   │   │  │
│  │ │ - Index actifs: /loki/boltdb-shipper-active    │   │  │
│  │ │ - Cache: /loki/boltdb-shipper-cache            │   │  │
│  │ │ - Chunks: /loki/chunks                         │   │  │
│  │ └──────────────────────────────────────────────────┘   │  │
│  │                      ▼                                  │  │
│  │ HTTP API (Port 3100):                                 │  │
│  │ - /loki/api/v1/query (queries instantanées)          │  │
│  │ - /loki/api/v1/query_range (range queries)          │  │
│  │ - /loki/api/v1/push (ingest logs)                    │  │
│  │ - /loki/api/v1/labels (labels discovery)            │  │
│  └───────────────┬──────────────────────────────────────┘  │
│                  │                                          │
│  ┌───────────────▼──────────────────────────────────────┐   │
│  │ Grafana - Visualization & Alerting                  │   │
│  │                                                      │   │
│  │ Frontend (Port 3000):                              │   │
│  │ ┌────────────────────────────────────────────────┐  │   │
│  │ │ Web Interface (HTTP)                           │  │   │
│  │ │ - Dashboard Builder                            │  │   │
│  │ │ - Query Editor (LogQL)                         │  │   │
│  │ │ - Data Source Management                       │  │   │
│  │ │ - Alert Rules Configuration                    │  │   │
│  │ └────────────────────────────────────────────────┘  │   │
│  │                       ▼                             │   │
│  │ Plugin System:                                     │   │
│  │ - grafana-piechart-panel (for distributions)       │   │
│  │ - grafana-worldmap-panel (for GeoIP mapping)       │   │
│  │ - Autres plugins optionnels                        │   │
│  │                       ▼                             │   │
│  │ Data Processing Layer:                            │   │
│  │ ┌────────────────────────────────────────────────┐  │   │
│  │ │ Query Executor                                 │  │   │
│  │ │ - LogQL Parser                                │  │   │
│  │ │ - Filter Expressions                          │  │   │
│  │ │ - Aggregations                                │  │   │
│  │ │ - Time-series calculations                    │  │   │
│  │ └────────────────────────────────────────────────┘  │   │
│  │                       ▼                             │   │
│  │ Alert Evaluation Engine:                          │   │
│  │ - Condition Checker (every 60s par défaut)        │   │
│  │ - Notification Manager                            │   │
│  │ - State Manager (Alerting/OK/Paused)              │   │
│  │   └─→ Email Notifier                              │   │
│  │   └─→ Webhook Notifier                            │   │
│  │   └─→ Slack/Discord/Teams                         │   │
│  │   └─→ SMS/PagerDuty                               │   │
│  └───────────────┬──────────────────────────────────┘   │
│                  │                                       │
│                  │ User Access                          │
│                  ▼                                       │
└────────────────────────────────────────────────────────────┘
                    │
                    │ HTTPS/HTTP
                    ▼
            ┌───────────────────┐
            │  Web Browser      │
            │  (Utilisateur)    │
            └───────────────────┘
```

---

## 📊 Flux de Données Détaillé

### 1. Phase d'Attaque
```
Attaquant SSH → Port 22 (Kali)
              ↓ (iptables redirect)
Port 2222 (Cowrie)
              ↓ (SSH handshake simulation)
Login attempt captured
              ↓ (JSON event generation)
```

### 2. Phase de Capture
```
Cowrie Event (JSON)
              ↓ (in real-time)
/var/log/cowrie/cowrie.json
              ↓ (Loki ingester monitoring)
Timestamp     + Labels extraction
              ↓ (chunking & compression)
```

### 3. Phase de Stockage
```
Raw Log Entry
              ↓ (BoltDB Shipper)
Index Database (/loki/boltdb-shipper-active)
              ↓
Chunks Store (/loki/chunks)
              ↓ (compression)
Compressed binary format [GZIP]
              ↓ (TTL based cleanup)
Archive/Deletion (30+ days)
```

### 4. Phase de Requête
```
User Query (Grafana)
              ↓ (LogQL)
Loki Query Engine
              ↓ (index search)
Chunks retrieval
              ↓ (decompression)
Results aggregation
              ↓ (JSON response)
Grafana visualization
```

---

## 🔄 Flux d'Événements Cowrie

### Session Lifecycle

```
┌─ cowrie.session.connect ──────┐
│   src_ip: "192.168.1.100"     │
│   session: "session_uuid"     │
│   timestamp: 1234567890        │
└───────────────┬────────────────┘
                ▼
        ┌───────────────────────────────────┐
        │ SSH Handshake & Auth              │
        └───────────────┬───────────────────┘
                        ▼
                ┌─────────────────┐
                │ Authentication  │
                │   Attempt       │
                └────┬────────┬───┘
                     │        │
        ┌────────────┴─┐  ┌──┴──────────..
        ▼              ▼
    SUCCESS        FAILED
        │              │
    cowrie.      cowrie.
    client.      client.
    login.       login.
    success      failed
        │              │
        └──────┬───────┘
               ▼
    ┌─ cowrie.command.input ──┐
    │   command: "ls -la"     │
    │   timestamp: ...        │
    └─────────────┬───────────┘
                  ▼
        ┌─ cowrie.command.output ──┐
        │   output: "total 32..."  │
        └──────────┬────────────────┘
                   ▼
       ┌─ cowrie.session.file_download ──┐
       │   filename: "malware.sh"        │
       │   filesize: 2048                │
       └───────────────┬──────────────────┘
                       ▼
        ┌─ cowrie.session.closed ──┐
        │   duration: 345 seconds  │
        │   size: 5120 bytes       │
        └──────────────────────────┘
```

---

## 🏭 Composants Docker

### Configuration Service Loki

```dockerfile
Image: grafana/loki:latest

Volumes:
├── ./loki-config/loki-config.yml → /etc/loki/local-config.yaml
└── loki-storage → /loki/
    ├── boltdb-shipper-active/ (index actif)
    ├── boltdb-shipper-cache/  (cache)
    └── chunks/                (données compressées)

Ports:
└── 3100/tcp → /loki/api/v1/*

Network:
└── honeypot-network (bridge)

Health Check:
└── curl -f http://localhost:3100/loki/api/v1/status/ready
```

### Configuration Service Grafana

```dockerfile
Image: grafana/grafana:latest

Volumes:
├── grafana-storage → /var/lib/grafana/
│   ├── dashboards/
│   ├── datasources/
│   ├── alerting/
│   └── plugins/
└── ./grafana-provisioning/

Ports:
└── 3000/tcp → Frontend HTTP

Environment:
├── GF_SECURITY_ADMIN_PASSWORD
├── GF_INSTALL_PLUGINS
└── GF_USERS_ALLOW_SIGN_UP=false

Dependencies:
└── loki (service_healthy condition)

Network:
└── honeypot-network (bridge)
```

---

## 📈 Métriques et Performances

### Capacité de Stockage

| Tentative SSH | Taille log JSON | TTL | Stockage total |
|---|---|---|---|
| 1 000/jour | ~2 KB | 30 jours | ~60 MB |
| 10 000/jour | ~20 KB | 30 jours | ~600 MB |
| 100 000/jour | ~200 KB | 30 jours | ~6 GB |

### Performance Loki

| Opération | Temps | Conditions |
|---|---|---|
| Ingest | < 50ms | Par 1000 events |
| Query | < 1s | 24h range |
| Scan | < 5s | Full index scan |
| Compression | 70-80% | GZIP ratio |

### Ressources Recommandées

```
Loki Container:
├── RAM: 2 GB (min 1 GB)
├── CPU: 1 vCPU
└── Disk: 20-50 GB (dépend de la rétention)

Grafana Container:
├── RAM: 1 GB
├── CPU: 0.5 vCPU
└── Disk: 5 GB

Cowrie Process:
├── RAM: 200 MB
├── CPU: 0.2 vCPU (variable selon attaques)
└── Disk: 1-10 GB (logs)
```

---

## 🔐 Chaîne de Sécurité

```
┌────────────────────────────────────────┐
│ Attacker → Network Firewall            │ 1. Filtrage initial (ufw/iptables)
│            ↓ (allowed ports)           │
├────────────────────────────────────────┤
│ SSH Connection → Cowrie Honeypot       │ 2. Honeypot redirection (port 22→2222)
│            ↓ (fake SSH server)         │
├────────────────────────────────────────┤
│ Session Capture → JSON Event Logger    │ 3. Événements JSON structurés
│            ↓ (sanitized logs)          │
├────────────────────────────────────────┤
│ Loki Aggregation → Data Sanitization   │ 4. Labelisation sécurisée
│            ↓ (indexed)                 │
├────────────────────────────────────────┤
│ Grafana Dashboard → HTTPS + Auth       │ 5. Access control & encryption
│            ↓ (role-based)              │
├────────────────────────────────────────┤
│ Security Analyst → Analysis            │ 6. Isolation de l'analyste
└────────────────────────────────────────┘
```

---

## 🔄 Cycle de Rétention des Données

```
Temps (jours)
│
│  New Events
├─────────────────────────── 0 (Ingestion)
│  ↓ Chunking
│
├─────────────────────────── 1 (Compression)
│  ↓ BoltDB Indexing
│
├─────────────────────────── 7 (Active Index)
│  ↓ Archive to Cold Storage
│
├─────────────────────────── 30 (Retention Policy)
│  ↓ Cleanup
│
└─────────────────────────── 35+ (Deleted)
```

---

## 🎯 Schéma d'Indexation LogQL

```
Raw Event:
{
  "timestamp": 1234567890,
  "src_ip": "192.168.1.100",
  "username": "admin",
  "password": "password123",
  "eventid": "cowrie.client.login.failed",
  "session": "uuid123"
}

↓ Labeling Process

Indexed Query:
{job="cowrie"} 
| src_ip="192.168.1.100"      ← Label 1
| username="admin"             ← Label 2
| eventid="cowrie.client.login.failed"  ← Label 3
| password="password123"       ← Extracted field (not indexed)
```

---

## 🚀 Optimizations Avancées

### 1. Caching Strategy
- Query cache: 1 minute
- Index cache: 30 minutes
- Frontend cache: 5 minutes

### 2. Compression
- Default: GZIP
- Ratio: 70-80%
- Block size: 256 MB (configurable)

### 3. Retention Policy
```yaml
- Keep 30 days of hot data
- Archive older data to cold storage
- Delete after 365 days
- Configurable TTL per stream
```

---

## 📞 Troubleshooting Architecture

### Issue: Log lag

```
Solution: Augmenter les CPU/RAM pour Loki
Diagnostic: docker stats | grep loki
```

### Issue: High disk usage

```
Solution: Réduire la retention period
Diagnostic: du -sh /loki/chunks
```

### Issue: Queries slow

```
Solution: Ajouter du cache & index optimization
Diagnostic: loki logs show query_duration
```

---

Fin de l'architecture détaillée.
