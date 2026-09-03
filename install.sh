#!/bin/bash
set -euo pipefail
echo "=== MUB-X V2 CORRECTED ==="
read -p "Domain: " DOMAIN </dev/tty || true
[ -z "$DOMAIN" ] && exit 1
systemctl stop apache2 nginx haproxy xray 2>/dev/null || true
fuser -k 80/tcp 2>/dev/null || true
apt-get update -qq
apt-get install -y -qq curl certbot lsof psmisc git jq uuid-runtime dropbear squid haproxy openvpn wireguard iptables qrencode
cd /root/mub-x
cp bin/* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/*
echo "$DOMAIN" > /usr/local/etc/xray/domain
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>/dev/null || true
bash <(curl -fsSL https://get.hysteria.network/) 2>/dev/null || true
/usr/local/bin/generate-secrets
sed -i "s|__DOMAIN__|$DOMAIN|g" /etc/telecom-engine.env
source /etc/telecom-engine.env
cp configs/*.json /usr/local/etc/xray/
cp configs/haproxy.cfg /etc/haproxy/
cp configs/nginx.conf /etc/nginx/nginx.conf
cp configs/squid.conf /etc/squid/
cp configs/dropbear /etc/default/dropbear
cp systemd/*.service /etc/systemd/system/ 2>/dev/null || true
for f in /usr/local/etc/xray/*.json /etc/nginx/nginx.conf /etc/haproxy/haproxy.cfg /etc/systemd/system/dnstt.service; do
  [ -f "$f" ] || continue
  sed -i "s|__DOMAIN__|$DOMAIN|g; s|__UUID__|$UUID|g; s|__SHORT_ID__|$SHORT_ID|g; s|__REALITY_PRIVKEY__|$REALITY_PRIVKEY|g" "$f"
done
systemctl daemon-reload
for svc in nginx haproxy xray dropbear squid; do
  systemctl enable $svc 2>/dev/null || true
  systemctl restart $svc 2>/dev/null || true
done
echo "[*] Core online. Type 'menu'."
