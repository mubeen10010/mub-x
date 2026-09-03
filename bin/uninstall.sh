#!/bin/bash
read -p "Type DELETE to remove MUB-X: " c
[ "$c" = "DELETE" ] || exit 0
systemctl disable --now nginx haproxy xray dropbear squid 2>/dev/null || true
rm -rf /usr/local/bin/{menu,link-gen,add-user,mubx-probe,set-domain,mubx-cron,generate-secrets,uninstall.sh}
rm -rf /usr/local/etc/xray /etc/hysteria /etc/dnstt /root/mub-x /etc/telecom-engine.env
echo "[*] Removed"
