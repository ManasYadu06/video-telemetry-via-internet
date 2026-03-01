#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# stream_reconnect.sh — Auto-reconnect streaming script
# Global Video Telemetry System
#
# Usage:
#   ./stream_reconnect.sh
#   ./stream_reconnect.sh --ip 18.60.110.180 --res 720 --bitrate 2000000
# ─────────────────────────────────────────────────────────────────────────────

# ─── Default Configuration ───────────────────────────────────────────────────
AWS_IP="YOUR_AWS_IP"       # Replace with your EC2 public IP
STREAM_KEY="stream"
WIDTH=1280
HEIGHT=720
FPS=30
BITRATE=2000000            # bits per second
RECONNECT_DELAY=5          # seconds to wait before reconnecting
LOG_FILE="/tmp/telemetry-stream.log"
# ─────────────────────────────────────────────────────────────────────────────

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip)       AWS_IP="$2";      shift 2 ;;
    --key)      STREAM_KEY="$2";  shift 2 ;;
    --res)
      case "$2" in
        480)  WIDTH=640;  HEIGHT=480;  FPS=25; BITRATE=800000  ;;
        720)  WIDTH=1280; HEIGHT=720;  FPS=30; BITRATE=2000000 ;;
        1080) WIDTH=1920; HEIGHT=1080; FPS=30; BITRATE=4000000 ;;
        *)    echo "[WARN] Unknown resolution $2, using 720p"; ;;
      esac
      shift 2 ;;
    --bitrate)  BITRATE="$2";    shift 2 ;;
    *) echo "Unknown option: $1"; shift ;;
  esac
done

# Validate IP
if [[ "$AWS_IP" == "YOUR_AWS_IP" ]]; then
  echo "[ERROR] AWS IP not configured. Edit AWS_IP in this script or pass --ip <address>"
  exit 1
fi

RTMP_URL="rtmp://${AWS_IP}:443/live/${STREAM_KEY}"
ATTEMPT=0

echo "=============================================="
echo "  Global Video Telemetry — Auto-Reconnect"
echo "=============================================="
echo "  Destination : $RTMP_URL"
echo "  Resolution  : ${WIDTH}x${HEIGHT} @ ${FPS}fps"
echo "  Bitrate     : ${BITRATE} bps"
echo "  Log file    : $LOG_FILE"
echo "=============================================="
echo "  Press Ctrl+C to stop"
echo ""

# Trap Ctrl+C
cleanup() {
  echo ""
  echo "[INFO] Stream stopped by user."
  exit 0
}
trap cleanup SIGINT SIGTERM

# ─── Main Loop ───────────────────────────────────────────────────────────────
while true; do
  ATTEMPT=$((ATTEMPT + 1))
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$TIMESTAMP] Attempt #${ATTEMPT} — Starting stream..."
  echo "[$TIMESTAMP] Attempt #${ATTEMPT}" >> "$LOG_FILE"

  rpicam-vid \
    -t 0 \
    --width "$WIDTH" \
    --height "$HEIGHT" \
    --framerate "$FPS" \
    --bitrate "$BITRATE" \
    --inline \
    -n \
    -o - 2>>"$LOG_FILE" | \
  ffmpeg \
    -re \
    -fflags nobuffer \
    -flags low_delay \
    -i - \
    -c:v copy \
    -f flv \
    "$RTMP_URL" 2>>"$LOG_FILE"

  EXIT_CODE=$?
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[$TIMESTAMP] Stream ended cleanly."
  else
    echo "[$TIMESTAMP] Stream dropped (exit code: $EXIT_CODE). Reconnecting in ${RECONNECT_DELAY}s..."
  fi

  sleep "$RECONNECT_DELAY"
done