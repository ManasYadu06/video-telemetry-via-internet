#!/usr/bin/env python3
"""
stream.py — Basic streaming script for Raspberry Pi
Global Video Telemetry System
"""

import subprocess
import sys
import signal
import time
import argparse

# ─── Configuration ────────────────────────────────────────────────────────────
DEFAULT_AWS_IP    = "YOUR_AWS_IP"   # Replace with your EC2 public IP
DEFAULT_STREAM_KEY = "stream"
DEFAULT_WIDTH     = 1280
DEFAULT_HEIGHT    = 720
DEFAULT_FPS       = 30
DEFAULT_BITRATE   = "2M"
# ──────────────────────────────────────────────────────────────────────────────

camera_proc = None
ffmpeg_proc = None


def signal_handler(sig, frame):
    print("\n[INFO] Stopping stream...")
    if ffmpeg_proc:
        ffmpeg_proc.terminate()
    if camera_proc:
        camera_proc.terminate()
    sys.exit(0)


def start_stream(aws_ip, stream_key, width, height, fps, bitrate):
    global camera_proc, ffmpeg_proc

    rtmp_url = f"rtmp://{aws_ip}:443/live/{stream_key}"

    camera_cmd = [
        "rpicam-vid",
        "-t", "0",
        "--width", str(width),
        "--height", str(height),
        "--framerate", str(fps),
        "--bitrate", bitrate,
        "--inline",
        "-n",
        "-o", "-"
    ]

    ffmpeg_cmd = [
        "ffmpeg",
        "-re",
        "-fflags", "nobuffer",
        "-flags", "low_delay",
        "-i", "-",
        "-c:v", "copy",
        "-f", "flv",
        rtmp_url
    ]

    print("=" * 50)
    print("  Global Video Telemetry — Stream Starting")
    print("=" * 50)
    print(f"  Destination : {rtmp_url}")
    print(f"  Resolution  : {width}x{height} @ {fps}fps")
    print(f"  Bitrate     : {bitrate}")
    print("=" * 50)
    print("  Press Ctrl+C to stop\n")

    try:
        camera_proc = subprocess.Popen(camera_cmd, stdout=subprocess.PIPE)
        ffmpeg_proc = subprocess.Popen(ffmpeg_cmd, stdin=camera_proc.stdout)
        ffmpeg_proc.wait()

    except FileNotFoundError as e:
        print(f"[ERROR] Command not found: {e}")
        print("[HINT] Run: sudo apt install -y ffmpeg rpicam-apps")
        sys.exit(1)

    except Exception as e:
        print(f"[ERROR] {e}")
        sys.exit(1)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Stream Raspberry Pi camera to AWS EC2 via RTMP/443"
    )
    parser.add_argument("--ip",      default=DEFAULT_AWS_IP,     help="AWS EC2 public IP")
    parser.add_argument("--key",     default=DEFAULT_STREAM_KEY, help="Stream key (default: stream)")
    parser.add_argument("--width",   default=DEFAULT_WIDTH,  type=int, help="Video width  (default: 1280)")
    parser.add_argument("--height",  default=DEFAULT_HEIGHT, type=int, help="Video height (default: 720)")
    parser.add_argument("--fps",     default=DEFAULT_FPS,    type=int, help="Framerate (default: 30)")
    parser.add_argument("--bitrate", default=DEFAULT_BITRATE,    help="Bitrate e.g. 2M, 800k (default: 2M)")
    return parser.parse_args()


if __name__ == "__main__":
    signal.signal(signal.SIGINT,  signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    args = parse_args()

    if args.ip == "YOUR_AWS_IP":
        print("[WARNING] AWS IP not set. Edit DEFAULT_AWS_IP in stream.py or pass --ip <address>")
        sys.exit(1)

    start_stream(
        aws_ip=args.ip,
        stream_key=args.key,
        width=args.width,
        height=args.height,
        fps=args.fps,
        bitrate=args.bitrate
    )