#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# install.sh — Raspberry Pi setup automation
# Global Video Telemetry System
#
# Run as a regular user (not root). Uses sudo internally where needed.
# Usage: bash install.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✘]${NC} $1"; exit 1; }
header() { echo -e "\n${YELLOW}━━━ $1 ━━━${NC}"; }

echo ""
echo "=============================================="
echo "  Global Video Telemetry — Pi Installer"
echo "=============================================="
echo ""

# ─── 1. System Update ─────────────────────────────────────────────────────────
header "Updating system packages"
sudo apt update -y && sudo apt upgrade -y
log "System updated"

# ─── 2. Install Core Dependencies ─────────────────────────────────────────────
header "Installing dependencies"
sudo apt install -y \
  ffmpeg \
  rpicam-apps \
  python3-pip \
  git \
  screen \
  htop \
  net-tools \
  minicom \
  libqmi-utils \
  udhcpc

log "Core packages installed"

# ─── 3. Verify Camera ─────────────────────────────────────────────────────────
header "Verifying camera"
if rpicam-hello --list-cameras 2>&1 | grep -q "imx\|ov\|Available"; then
  log "Camera detected"
else
  warn "No camera detected. Make sure the CSI cable is connected and camera is enabled."
  warn "Run: sudo raspi-config → Interface Options → Camera → Enable → Reboot"
fi

# ─── 4. Verify FFmpeg ─────────────────────────────────────────────────────────
header "Verifying FFmpeg"
FFMPEG_VERSION=$(ffmpeg -version 2>&1 | head -n1)
log "FFmpeg: $FFMPEG_VERSION"

# ─── 5. EC25 4G Module ────────────────────────────────────────────────────────
header "Checking EC25 4G module"
if lsusb | grep -qi "quectel"; then
  log "Quectel EC25 module detected via USB"
  ls /dev/ttyUSB* 2>/dev/null && log "Serial ports found" || warn "No ttyUSB ports yet (try rebooting)"
  ls /dev/cdc-wdm* 2>/dev/null && log "QMI interface found" || warn "No cdc-wdm interface (check USB connection)"
else
  warn "EC25 module not detected. Connect via USB and re-run this script."
fi

# ─── 6. Dialout Group ─────────────────────────────────────────────────────────
header "Setting serial port permissions"
if groups "$USER" | grep -q "dialout"; then
  log "User '$USER' already in dialout group"
else
  sudo usermod -a -G dialout "$USER"
  log "Added '$USER' to dialout group (re-login required to take effect)"
fi

# ─── 7. Copy Scripts ──────────────────────────────────────────────────────────
header "Installing scripts to ~/telemetry"
mkdir -p ~/telemetry
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/stream.py"            ~/telemetry/
cp "$SCRIPT_DIR/stream_reconnect.sh"  ~/telemetry/
chmod +x ~/telemetry/stream.py
chmod +x ~/telemetry/stream_reconnect.sh

log "Scripts copied to ~/telemetry"

# ─── 8. Create LTE Connect Script ────────────────────────────────────────────
header "Creating LTE connect helper"
cat > ~/telemetry/connect_lte.sh << 'EOF'
#!/bin/bash
# connect_lte.sh — Connect EC25 module to internet
# Edit APN below to match your carrier

APN="airtelgprs.com"
# India APNs: Airtel=airtelgprs.com | Jio=jionet | Vodafone=www | BSNL=bsnlnet

echo "[INFO] Connecting with APN: $APN"
sudo qmicli -d /dev/cdc-wdm0 \
  --wds-start-network="apn='$APN',ip-type=4" --client-no-release-cid

sleep 2
echo "[INFO] Requesting IP via DHCP..."
sudo udhcpc -i wwan0

echo ""
echo "[INFO] Interface status:"
ifconfig wwan0 2>/dev/null || echo "wwan0 not found"
echo ""
echo "[INFO] Testing connectivity..."
ping -c 4 -I wwan0 8.8.8.8
EOF
chmod +x ~/telemetry/connect_lte.sh
log "LTE connect script created at ~/telemetry/connect_lte.sh"

# ─── 9. Systemd Service ───────────────────────────────────────────────────────
header "Systemd service"
SYSTEMD_SRC="$(dirname "$SCRIPT_DIR")/../../systemd/video-telemetry.service"
if [[ -f "$SYSTEMD_SRC" ]]; then
  sudo cp "$SYSTEMD_SRC" /etc/systemd/system/video-telemetry.service
  sudo systemctl daemon-reload
  log "Systemd service installed (not enabled — run 'sudo systemctl enable video-telemetry' to auto-start)"
else
  warn "video-telemetry.service not found at expected path. Install manually from systemd/ folder."
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo "  Installation complete!"
echo "=============================================="
echo ""
echo "  Next steps:"
echo "  1. Edit ~/telemetry/stream.py      → set DEFAULT_AWS_IP"
echo "  2. Edit ~/telemetry/connect_lte.sh → set correct APN"
echo "  3. Run: ~/telemetry/connect_lte.sh"
echo "  4. Run: python3 ~/telemetry/stream.py --ip <YOUR_EC2_IP>"
echo ""