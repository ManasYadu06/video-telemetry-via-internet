#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# view_stream.sh — Stream viewer for ground station
# Global Video Telemetry System
#
# Usage:
#   ./view_stream.sh
#   ./view_stream.sh --ip 18.60.110.180 --key stream --fullscreen
# ─────────────────────────────────────────────────────────────────────────────

AWS_IP="YOUR_AWS_IP"    # Replace with your EC2 public IP
STREAM_KEY="stream"
FULLSCREEN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip)         AWS_IP="$2";      shift 2 ;;
    --key)        STREAM_KEY="$2";  shift 2 ;;
    --fullscreen) FULLSCREEN=true;  shift ;;
    *) echo "Unknown option: $1"; shift ;;
  esac
done

if [[ "$AWS_IP" == "YOUR_AWS_IP" ]]; then
  echo "[ERROR] AWS IP not set. Edit AWS_IP in this script or pass --ip <address>"
  exit 1
fi

RTMP_URL="rtmp://${AWS_IP}:443/live/${STREAM_KEY}"

echo "=============================================="
echo "  Ground Station — Stream Viewer"
echo "=============================================="
echo "  URL: $RTMP_URL"
echo "=============================================="
echo ""
echo "  Keyboard shortcuts:"
echo "    F         — Toggle fullscreen"
echo "    Space / P — Pause / Resume"
echo "    Q / ESC   — Quit"
echo ""

# Base FFplay options for low latency
FFPLAY_OPTS=(
  -fflags nobuffer
  -flags low_delay
  -framedrop
  -sync ext
  -window_title "Video Telemetry — $STREAM_KEY"
)

# Add fullscreen flag if requested
if [[ "$FULLSCREEN" == true ]]; then
  FFPLAY_OPTS+=(-fs)
fi

# Check if ffplay is available
if ! command -v ffplay &>/dev/null; then
  echo "[ERROR] ffplay not found."
  echo "[HINT] Install FFmpeg:"
  echo "  Ubuntu/Debian : sudo apt install ffmpeg"
  echo "  macOS         : brew install ffmpeg"
  echo "  Windows       : https://ffmpeg.org/download.html"
  exit 1
fi

# Start viewer
ffplay "${FFPLAY_OPTS[@]}" "$RTMP_URL"