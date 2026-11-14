
#!/bin/bash

# ==================================================
# PROJET : MINI SOC
# Deploiement de Suricata et EveBox
# Systeme : Ubuntu Server
# ==================================================

set -e

# 1. Mise a jour du serveur
apt-get update
apt-get upgrade -y

# 2. Installation des composants du SOC
apt-get install -y suricata curl ca-certificates gnupg

# 3. Mise a jour des regles de detection
suricata-update

# 4. Configuration du depot EveBox
install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://evebox.org/files/evebox.asc \
    -o /etc/apt/keyrings/evebox.asc

echo "deb [signed-by=/etc/apt/keyrings/evebox.asc] https://evebox.org/files/debian stable main" \
    > /etc/apt/sources.list.d/evebox.list

apt-get update

# 5. Installation d'EveBox
apt-get install -y evebox

# 6. Configuration de la collecte des evenements
mkdir -p /var/log/suricata

usermod -aG suricata evebox

cat > /etc/default/evebox <<'EOF'
EVEBOX_OPTS="--database sqlite /var/log/suricata/eve.json"
EOF

# 7. Activation des services
systemctl enable suricata
systemctl enable evebox

systemctl restart evebox

# 8. Verification de la configuration Suricata
suricata -T -c /etc/suricata/suricata.yaml

# 9. Redemarrage du moteur de detection
systemctl restart suricata
