#!/bin/bash

# Script d'installation automatisée du Honeypot Cowrie + Loki + Grafana
# Usage: sudo bash install-honeypot.sh

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Installation Honeypot Cowrie + Loki + Grafana ===${NC}"

# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté en tant que root (sudo)${NC}"
   exit 1
fi

# Créer le répertoire de base
HONEYPOT_DIR="$HOME/honeypot"
echo -e "${YELLOW}Création du répertoire: $HONEYPOT_DIR${NC}"
mkdir -p "$HONEYPOT_DIR"
cd "$HONEYPOT_DIR"

# 1. Mettre à jour le système
echo -e "${YELLOW}[1/8] Mise à jour du système...${NC}"
apt update && apt upgrade -y

# 2. Installer les dépendances système
echo -e "${YELLOW}[2/8] Installation des dépendances système...${NC}"
apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  git \
  wget \
  curl \
  build-essential \
  libssl-dev \
  libffi-dev \
  openssh-server \
  fail2ban

# 3. Installer Docker
echo -e "${YELLOW}[3/8] Installation de Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    bash get-docker.sh
    rm get-docker.sh
fi

# Installer Docker Compose
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 4. Cloner et installer Cowrie
echo -e "${YELLOW}[4/8] Installation de Cowrie...${NC}"
git clone https://github.com/cowrie/cowrie.git || cd cowrie && git pull
cd cowrie

# Créer l'environnement virtuel Python
python3 -m venv cowrie-venv
source cowrie-venv/bin/activate

# Installer les dépendances Python
pip install -r requirements.txt

# Configurer Cowrie
cp etc/cowrie.conf.dist etc/cowrie.conf

# Modifier les paramètres importants
sed -i 's/^#listen_port = 2222/listen_port = 2222/' etc/cowrie.conf
sed -i 's/enabled = false$/enabled = true/' etc/cowrie.conf

echo -e "${GREEN}✓ Cowrie installé${NC}"

# 5. Créer la configuration Loki
echo -e "${YELLOW}[5/8] Configuration de Loki...${NC}"
cd "$HONEYPOT_DIR"
mkdir -p loki-config

cat > loki-config/loki-config.yml << 'EOF'
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
EOF

echo -e "${GREEN}✓ Loki configuré${NC}"

# 6. Créer le fichier docker-compose
echo -e "${YELLOW}[6/8] Création du docker-compose...${NC}"

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config/loki-config.yml:/etc/loki/local-config.yaml
      - loki-storage:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - honeypot-network
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SECURITY_ADMIN_USER=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana-storage:/var/lib/grafana
    depends_on:
      - loki
    networks:
      - honeypot-network
    restart: unless-stopped

volumes:
  loki-storage:
  grafana-storage:

networks:
  honeypot-network:
    driver: bridge
EOF

echo -e "${GREEN}✓ Docker-compose créé${NC}"

# 7. Démarrer les services Docker
echo -e "${YELLOW}[7/8] Démarrage des services Docker...${NC}"
docker-compose up -d

# Attendre que les services soient démarrés
sleep 10

# Vérifier que les services sont en cours d'exécution
if docker ps | grep -q loki; then
    echo -e "${GREEN}✓ Loki est en cours d'exécution${NC}"
else
    echo -e "${RED}✗ Erreur : Loki n'a pas pu démarrer${NC}"
fi

if docker ps | grep -q grafana; then
    echo -e "${GREEN}✓ Grafana est en cours d'exécution${NC}"
else
    echo -e "${RED}✗ Erreur : Grafana n'a pas pu démarrer${NC}"
fi

# 8. Configuration de redirection de ports
echo -e "${YELLOW}[8/8] Configuration de la redirection SSH...${NC}"

# Vérifier et configurer ufw si disponible
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 2222/tcp
    ufw allow 3000/tcp
    ufw allow 3100/tcp
    echo -e "${GREEN}✓ Firewall configuré${NC}"
fi

# Configuration iptables pour redirection SSH
if command -v iptables &> /dev/null; then
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
    # Sauvegarder les règles iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    echo -e "${GREEN}✓ Redirection SSH configurée${NC}"
fi

# Afficher le résumé final
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Installation terminée avec succès !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Accédez aux services via :"
echo -e "  ${YELLOW}Grafana${NC}     : http://localhost:3000"
echo -e "  ${YELLOW}Loki API${NC}   : http://localhost:3100"
echo ""
echo "Identifiants Grafana :"
echo "  Utilisateur : admin"
echo "  Mot de passe : admin123 (à changer !)"
echo ""
echo "Démarrer Cowrie :"
echo "  cd $HONEYPOT_DIR/cowrie"
echo "  source cowrie-venv/bin/activate"
echo "  bin/cowrie start"
echo ""
echo "Vérifier l'état de Cowrie :"
echo "  cd $HONEYPOT_DIR/cowrie"
echo "  source cowrie-venv/bin/activate"
echo "  bin/cowrie status"
echo ""
echo "Voir les logs Cowrie :"
echo "  tail -f $HONEYPOT_DIR/cowrie/var/log/cowrie/cowrie.json | jq"
echo ""
