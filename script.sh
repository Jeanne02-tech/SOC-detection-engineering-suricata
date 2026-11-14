
#!/bin/bash

# ==========================================
# MINI SOC LAB
# Installation de Suricata et EveBox
# Systeme : Ubuntu Server
# ==========================================

set -e

echo "=========================================="
echo "       INSTALLATION MINI SOC LAB"
echo "=========================================="

# Verification des privileges administrateur
if [ "$EUID" -ne 0 ]; then
    echo "Erreur : execute ce script avec sudo."
    exit 1
fi

# Verification du systeme
if [ ! -f /etc/os-release ]; then
    echo "Erreur : systeme Linux non reconnu."
    exit 1
fi

. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "Erreur : ce script est prevu pour Ubuntu."
    exit 1
fi

# 1. Mise a jour du systeme
echo "[1/7] Mise a jour du systeme..."

apt-get update
apt-get upgrade -y

# 2. Installation des dependances
echo "[2/7] Installation des dependances..."

apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    suricata

# 3. Installation des regles Suricata
echo "[3/7] Mise a jour des regles Suricata..."

if command -v suricata-update >/dev/null 2>&1; then
    suricata-update
else
    echo "Attention : suricata-update est indisponible."
fi

# 4. Ajout du depot officiel EveBox
echo "[4/7] Configuration du depot EveBox..."

install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://evebox.org/files/evebox.asc \
    -o /etc/apt/keyrings/evebox.asc

echo "deb [signed-by=/etc/apt/keyrings/evebox.asc] https://evebox.org/files/debian stable main" \
    > /etc/apt/sources.list.d/evebox.list

apt-get update

# 5. Installation d'EveBox
echo "[5/7] Installation d'EveBox..."

apt-get install -y evebox

# 6. Configuration d'EveBox
echo "[6/7] Configuration de la lecture des evenements..."

if getent group suricata >/dev/null; then
    usermod -aG suricata evebox
else
    echo "Attention : groupe suricata introuvable."
fi

cat > /etc/default/evebox <<'EOF'
EVEBOX_OPTS="--database sqlite /var/log/suricata/eve.json"
EOF

# 7. Activation des services
echo "[7/7] Activation des services..."

systemctl enable suricata
systemctl enable evebox

systemctl restart evebox

echo ""
echo "=========================================="
echo "       INSTALLATION TERMINEE"
echo "=========================================="

echo ""
echo "Suricata :"
suricata --build-info

echo ""
echo "Etat du service Suricata :"
systemctl status suricata --no-pager || true

echo ""
echo "Etat du service EveBox :"
systemctl status evebox --no-pager || true

echo ""
echo "Interfaces reseau disponibles :"
ip -br link

echo ""
echo "IMPORTANT :"
echo "1. Identifier l'interface Host-Only."
echo "2. Configurer Suricata pour surveiller cette interface."
echo "3. Verifier la configuration avec :"
echo "   sudo suricata -T -c /etc/suricata/suricata.yaml"
echo "4. Redemarrer Suricata apres configuration :"
echo "   sudo systemctl restart suricata"
echo "5. Acceder a EveBox depuis Windows 10 :"
echo "   http://ADRESSE_IP_HOST_ONLY:5636"

echo ""
echo "Installation terminee."
