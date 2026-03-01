#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# record_stream.sh — Record live RTMP stream to local file
# Global Video Telemetry System
#
# Usage:
#   ./record_stream.sh
#   ./record_stream.sh --ip 18.60.110.180 --key stream --output ./recordings
#   ./record_stream.sh --duration 60        (record for 60 seconds then stop)
# ─────────────────────────────────────────────────────────────────────────────

AWS_IP="YOUR_AWS_IP"    # Replace with your EC2 public IP
STREAM_KEY="stream"
OUTPUT_DIR="./recordings"
DURATION=""             # Leave empty to record until Ctrl+C

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip)       AWS_IP="$2";       shift 2 ;;
    --key)      STREAM_KEY="$2";   shift 2 ;;
    --output)   OUTPUT_DIR="$2";   shift 2 ;;
    --duration) DURATION="$2";     shift 2 ;;
    *) echo "Unknown option: $1";  shift ;;
  esac
done

if [[ "$AWS_IP" == "YOUR_AWS_IP" ]]; then
  echo "[ERROR] AWS IP not set. Edit AWS_IP in this script or pass --ip <address>"
  exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg &>/dev/null; then
  echo "[ERROR] ffmpeg not found. Install FFmpeg first."
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

RTMP_URL="rtmp://${AWS_IP}:443/live/${STREAM_KEY}"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_FILE="${OUTPUT_DIR}/recording_${STREAM_KEY}_${TIMESTAMP}.mp4"

echo "=============================================="
echo "  Ground Station — Stream Recorder"
echo "=============================================="
echo "  Source : $RTMP_URL"
echo "  Output : $OUTPUT_FILE"
[[ -n "$DURATION" ]] && echo "  Duration: ${DURATION}s" || echo "  Duration: until Ctrl+C"
echo "=============================================="
echo ""
echo "  Press Ctrl+C to stop recording"
echo ""

# Build FFmpeg command
FFMPEG_OPTS=(
  -i "$RTMP_URL"
  -c:v copy          # No re-encode — copy H.264 stream directly
  -c:a copy
  -movflags +faststart
)

# Add duration limit if specified
if [[ -n "$DURATION" ]]; then
  FFMPEG_OPTS=(-t "$DURATION" "${FFMPEG_OPTS[@]}")
fi

FFMPEG_OPTS+=("$OUTPUT_FILE")

# Record
ffmpeg -fflags nobuffer "${FFMPEG_OPTS[@]}"

echo ""
echo "[INFO] Recording saved to: $OUTPUT_FILE"
echo "[INFO] File size: $(du -sh "$OUTPUT_FILE" 2>/dev/null | cut -f1)"