#!/bin/bash
set -e

echo "======================================================="
echo " MUB-X V2 PRODUCTION - CORRECTED PIPELINE"
echo "======================================================="

# 1. GET DOMAIN & SECURE SSL FIRST (Before packages hog port 80)
echo "[-] 1/5 Domain & SSL Setup..."
# Ensure tty read doesn't trip set -e if empty
read -p "Enter your MUB-X Domain (e.g., gr.mub.my.id): " DOMAIN </dev/tty || true
if [ -z "$DOMAIN" ]; then 
    echo "[-] Error: Domain cannot be empty."
    exit 1
fi

echo "    -> Preparing Port 80 for Certbot..."
systemctl stop apache2 nginx haproxy xray 2>/dev/null || true
systemctl disable apache2 nginx haproxy xray 2>/dev/null || true
fuser -k 80/tcp 2>/dev/null || true

echo "    -> Installing Certbot & Dependencies for SSL..."
apt-get update -qq
apt-get install -y curl certbot lsof psmisc -qq

echo "    -> Requesting SSL Certificate..."
certbot certonly --standalone -d "$DOMAIN" --agree-tos --register-unsafely-without-email --non-interactive --force-renewal

# 2. INSTALL SYSTEM PACKAGES & PROXIES
echo "[-] 2/5 Installing Full System Dependencies & Daemons..."
apt-get install -y git jq ufw uuid-runtime dropbear squid haproxy openvpn wireguard iptables -qq

# 3. REPOSITORY SYNC & BINARY DEPLOYMENT
echo "[-] 3/5 Pulling MUB-X Architecture..."
if [ ! -d "/root/mub-x" ]; then
    git clone https://github.com/mubeen10010/mub-x.git /root/mub-x
else
    cd /root/mub-x && git pull origin main --rebase
fi

echo "    -> Deploying Binaries and Paths..."
cd /root/mub-x
mkdir -p /usr/local/bin /usr/local/etc/xray /etc/hysteria
cp bin/* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/*
echo "$DOMAIN" > /usr/local/etc/xray/domain

# 4. CORE PROTOCOL ENGINES (XRAY & HYSTERIA)
echo "[-] 4/5 Compiling Custom Protocol Engines..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>/dev/null || true
bash <(curl -fsSL https://get.hysteria.network/) 2>/dev/null || true

# 5. BOOT THE 12-DAEMON CLUSTER
echo "[-] 5/5 Booting & Injecting SSL into Daemons..."
systemctl daemon-reload
for svc in nginx haproxy dropbear squid openvpn xray hysteria-server; do
    systemctl enable $svc 2>/dev/null || true
    systemctl restart $svc 2>/dev/null || true
done

echo "======================================================="
echo "[✓] SYSTEM ONLINE. 12-DAEMON CLUSTER INITIALIZED."
echo "    Type 'menu' to begin generating users."
echo "======================================================="
