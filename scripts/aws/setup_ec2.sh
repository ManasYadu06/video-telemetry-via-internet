#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# setup_ec2.sh — One-shot AWS EC2 server setup script
# Global Video Telemetry System
#
# Run on a fresh Ubuntu 22.04 LTS EC2 instance:
#   bash setup_ec2.sh
#
# Pre-requisite: Security Group must allow TCP 443 and TCP 80 inbound.
# ─────────────────────────────────────────────────────────────────────────────

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✘]${NC} $1"; exit 1; }
header() { echo -e "\n${YELLOW}━━━ $1 ━━━${NC}"; }

echo ""
echo "=============================================="
echo "  Global Video Telemetry — EC2 Server Setup"
echo "=============================================="
echo ""

# ─── 1. System Update ─────────────────────────────────────────────────────────
header "Updating system"
sudo apt update -y && sudo apt upgrade -y
log "System updated"

# ─── 2. Install Nginx + RTMP Module ───────────────────────────────────────────
header "Installing Nginx and RTMP module"
sudo apt install -y nginx libnginx-mod-rtmp
log "Nginx installed: $(nginx -v 2>&1)"

# ─── 3. Deploy nginx.conf ─────────────────────────────────────────────────────
header "Deploying Nginx RTMP configuration"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/nginx.conf" ]]; then
  sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
  sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf
  log "nginx.conf deployed (backup saved to nginx.conf.backup)"
else
  warn "nginx.conf not found in $SCRIPT_DIR — skipping. Deploy manually."
fi

# ─── 4. Test Config ────────────────────────────────────────────────────────────
header "Testing Nginx configuration"
sudo nginx -t && log "Configuration syntax OK" || error "nginx.conf has errors — check above"

# ─── 5. Create HLS and Recordings Directories ────────────────────────────────
header "Creating directories"
sudo mkdir -p /tmp/hls
sudo mkdir -p /var/recordings
sudo chown -R www-data:www-data /tmp/hls /var/recordings
log "Directories created: /tmp/hls  /var/recordings"

# ─── 6. Deploy Web Player ────────────────────────────────────────────────────
header "Deploying HLS web player"
WEB_SRC="$(dirname "$SCRIPT_DIR")/../web/index.html"
if [[ -f "$WEB_SRC" ]]; then
  sudo cp "$WEB_SRC" /var/www/html/index.html
  log "Web player deployed to /var/www/html/index.html"
else
  warn "web/index.html not found — web player not deployed"
fi

# ─── 7. Configure UFW Firewall ────────────────────────────────────────────────
header "Configuring firewall"
if command -v ufw &>/dev/null; then
  sudo ufw allow OpenSSH
  sudo ufw allow 443/tcp comment "RTMP video stream"
  sudo ufw allow 80/tcp  comment "HTTP / HLS player"
  sudo ufw --force enable
  log "UFW rules set (SSH, 443, 80)"
else
  warn "UFW not found — skipping firewall config"
fi

# ─── 8. Start & Enable Nginx ──────────────────────────────────────────────────
header "Starting Nginx"
sudo systemctl restart nginx
sudo systemctl enable nginx
log "Nginx started and enabled on boot"

# ─── 9. Verify Port 443 Listening ─────────────────────────────────────────────
header "Verifying port 443"
sleep 1
if sudo ss -tulnp | grep -q ":443"; then
  log "Port 443 is listening ✔"
else
  error "Port 443 is NOT listening — check nginx.conf and restart nginx"
fi

# ─── 10. Print Summary ────────────────────────────────────────────────────────
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<your-ec2-ip>")

echo ""
echo "=============================================="
echo "  EC2 Setup Complete!"
echo "=============================================="
echo ""
echo "  Public IP   : $PUBLIC_IP"
echo ""
echo "  RTMP Stream URL:"
echo "    rtmp://$PUBLIC_IP:443/live/stream"
echo ""
echo "  HLS Web Player:"
echo "    http://$PUBLIC_IP/"
echo ""
echo "  To view logs:"
echo "    sudo tail -f /var/log/nginx/error.log"
echo ""
echo "  Recordings saved to: /var/recordings"
echo "    (stream to rtmp://$PUBLIC_IP:443/record/stream)"
echo ""