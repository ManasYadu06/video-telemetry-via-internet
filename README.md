# 🚁 Global Video Telemetry System via Internet

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)
[![Cloud](https://img.shields.io/badge/Cloud-AWS%20EC2-orange.svg)](https://aws.amazon.com/ec2/)
[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)]()

### 📡 Stream Live HD Video Globally Over GSM/LTE Networks

*A production-ready, firewall-safe live video transmission system for drone telemetry, remote surveillance, and IoT applications using RTMP over port 443.*

</div>

---

## 🌟 Overview

Traditional RTMP streaming uses **port 1935**, which is commonly blocked by ISPs, cellular networks, corporate firewalls, and CGNAT. This project solves that by streaming **RTMP over Port 443** — the same port used for HTTPS — making it virtually impossible to block without breaking the internet.

---

## ✨ Key Features

- 🌍 **Global Reach** — Stream from anywhere over GSM/LTE/WiFi
- 🔒 **Firewall-Safe** — Port 443 bypass, no VPN required
- 🎥 **HD Video** — Up to 1080p @ 30fps with H.264 hardware encoding
- ⚡ **Low Latency** — ~5 second end-to-end delay
- ☁️ **AWS EC2 Relay** — Scalable, globally accessible cloud infrastructure
- 🔁 **Auto-Reconnect** — Handles network drops gracefully
- 🛠️ **Open Source** — MIT licensed, Python automation included

---

## 🏗 System Architecture

```
┌──────────────────────────────────────────────────────┐
│                  DRONE / REMOTE SITE                 │
│                                                      │
│   [RPi Camera] ──CSI──► [Raspberry Pi 4/5]          │
│                               │                      │
│                    [rpicam-vid + FFmpeg]              │
│                         H.264 Encoder                │
│                               │                      │
│                          [EC25 4G LTE]               │
└───────────────────────────────┼──────────────────────┘
                                │
                   RTMP over Port 443 (TCP)
                                │
┌───────────────────────────────▼──────────────────────┐
│                  INTERNET / CELLULAR                 │
│          GSM / LTE / 4G / 5G / WiFi / ISP           │
└───────────────────────────────┬──────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────┐
│               AWS EC2 CLOUD SERVER                   │
│                                                      │
│   [Port 443] ──► [Nginx RTMP] ──► [Distribution]    │
│                                        │    │        │
└────────────────────────────────────────┼────┼────────┘
                                         │    │
                              ┌──────────┘    └──────────┐
                              ▼                          ▼
                   [Ground Station 1]         [Ground Station N]
                    FFplay / VLC               FFplay / VLC
                    Web Browser (HLS)          Web Browser (HLS)
```

### Latency Breakdown

| Step | Component | Latency |
|------|-----------|---------|
| 1 | Camera capture (25–30 FPS) | ~33 ms |
| 2 | H.264 hardware encoding | 40–80 ms |
| 3 | FFmpeg RTMP packaging | 20–50 ms |
| 4 | 4G LTE transmission | 100–500 ms |
| 5 | AWS routing + Nginx relay | 50–300 ms |
| 6 | Ground station decode | 1–3 s |
| | **Total end-to-end** | **~5 seconds** |

---

## 📦 Prerequisites

### Hardware
- **Raspberry Pi 4/5** (4GB+ RAM recommended)
- **Camera Module** — IMX708 or HQ Camera (CSI connector)
- **Quectel EC25 4G LTE Module** (USB interface, 2× LTE antennas)
- **Active SIM Card** with data plan (min. 5 GB/month)
- **MicroSD Card** — 32 GB+, Class 10
- **Power Supply** — 5V/3A USB-C

### Software
| Platform | Required |
|----------|----------|
| Raspberry Pi OS (Bullseye+) | `ffmpeg`, `rpicam-apps`, `python3` |
| AWS EC2 (Ubuntu 22.04 LTS) | `nginx`, `libnginx-mod-rtmp` |
| Ground Station (Win/Mac/Linux) | `ffmpeg` / VLC 3.0+ |

---

## ⚡ Quick Start

### 1. AWS EC2 — Install & Configure Nginx

```bash
sudo apt update && sudo apt install -y nginx libnginx-mod-rtmp
sudo nano /etc/nginx/nginx.conf
```

Add at the **end** of the file (after the `http {}` block):

```nginx
rtmp {
    server {
        listen 443;
        chunk_size 4096;
        application live {
            live on;
            record off;
            allow publish all;
            allow play all;
        }
    }
}
```

```bash
sudo nginx -t && sudo systemctl restart nginx
```

> **Security Group:** Open port `443/TCP` to `0.0.0.0/0` in your EC2 inbound rules.

---

### 2. Raspberry Pi — Start Streaming

```bash
sudo apt update && sudo apt install -y ffmpeg rpicam-apps

rpicam-vid -t 0 --inline -n -o - | \
ffmpeg -re -fflags nobuffer -flags low_delay \
  -i - -c:v copy -f flv \
  rtmp://YOUR_AWS_IP:443/live/stream
```

---

### 3. Ground Station — View Stream

**FFplay (lowest latency):**
```bash
ffplay -fflags nobuffer -flags low_delay -framedrop \
  rtmp://YOUR_AWS_IP:443/live/stream
```

**VLC:** Media → Open Network Stream → `rtmp://YOUR_AWS_IP:443/live/stream`

---

## 🔧 EC25 4G Module Setup

### Connect & Verify

```bash
# Verify USB detection
lsusb | grep Quectel
ls /dev/ttyUSB*      # Expect ttyUSB0–3
ls /dev/cdc-wdm*     # Expect cdc-wdm0
```

### Configure Internet (QMI)

```bash
sudo apt install -y libqmi-utils udhcpc
```

```bash
#!/bin/bash
# connect_lte.sh — replace APN with your carrier's value
# India: Airtel=airtelgprs.com | Jio=jionet | Vodafone=www | BSNL=bsnlnet

APN="airtelgprs.com"

sudo qmicli -d /dev/cdc-wdm0 \
  --wds-start-network="apn='$APN',ip-type=4" --client-no-release-cid
sleep 2
sudo udhcpc -i wwan0
ping -c 4 -I wwan0 8.8.8.8
```

```bash
chmod +x connect_lte.sh && ./connect_lte.sh
```

---

## 📊 Performance Reference

| Resolution | FPS | Bitrate | Min. Upload Required |
|------------|-----|---------|----------------------|
| 640×480 | 25 | 800 kbps | 1.2 Mbps |
| 1280×720 | 30 | 2 Mbps | 3 Mbps |
| 1920×1080 | 30 | 4 Mbps | 6 Mbps |

**Custom resolution example:**
```bash
rpicam-vid -t 0 --width 1280 --height 720 --framerate 30 \
  --bitrate 2000000 --inline -n -o - | \
  ffmpeg -re -i - -c:v copy -f flv rtmp://YOUR_AWS_IP:443/live/stream
```

---

## 🔍 Troubleshooting

| Problem | Fix |
|---------|-----|
| `Connection refused` on port 443 | Check AWS Security Group; run `sudo systemctl status nginx` |
| No video after connecting | Test camera: `rpicam-vid -t 5000 -o test.h264`; check `sudo nginx -t` |
| High latency (>15s) | Reduce bitrate; add `-framedrop -sync ext` to FFplay |
| Stream keeps disconnecting | Use auto-reconnect loop (see below) |
| `/dev/ttyUSB` permission denied | `sudo usermod -a -G dialout $USER && newgrp dialout` |

**Auto-reconnect loop:**
```bash
while true; do
  rpicam-vid -t 0 --inline -n -o - | \
    ffmpeg -re -i - -c:v copy -f flv rtmp://YOUR_AWS_IP:443/live/stream
  echo "Reconnecting in 5s..."; sleep 5
done
```

---

## ⚙️ Auto-Start on Boot (Systemd)

```bash
sudo nano /etc/systemd/system/video-telemetry.service
```

```ini
[Unit]
Description=Video Telemetry Streaming Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pi
ExecStartPre=/bin/sleep 10
ExecStart=/bin/bash -c 'rpicam-vid -t 0 --inline -n -o - | ffmpeg -re -fflags nobuffer -flags low_delay -i - -c:v copy -f flv rtmp://YOUR_AWS_IP:443/live/stream'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now video-telemetry.service
```

---

## 📁 Project Structure

```
video-telemetry-system/
├── README.md
├── LICENSE
├── scripts/
│   ├── raspberry-pi/
│   │   ├── stream.py             # Basic streaming script
│   │   ├── stream_reconnect.sh   # Auto-reconnect script
│   │   └── install.sh            # Setup automation
│   ├── aws/
│   │   ├── nginx.conf            # Nginx RTMP config
│   │   └── setup_ec2.sh          # EC2 setup script
│   └── ground-station/
│       ├── view_stream.sh        # FFplay viewer
│       └── record_stream.sh      # Recording script
├── systemd/
│   └── video-telemetry.service
└── web/
    └── index.html                # HLS web player
```

---

## 🎯 Use Cases

- 🚁 **Drone FPV / Aerial Inspection** — Live HD feed over cellular
- 🔍 **Search & Rescue** — Real-time situational awareness for command centers
- 🏗️ **Construction Monitoring** — 24/7 remote site oversight
- 🚗 **Fleet Management** — Live vehicle dashcam with cloud backup
- 🌾 **Agricultural Surveys** — Crop health monitoring via drone

---

## 🛣 Roadmap

- [ ] WebRTC integration (sub-second latency)
- [ ] iOS / Android viewer apps
- [ ] Stream authentication & access control
- [ ] AI object detection overlay (YOLO v8)
- [ ] AWS S3 cloud recording

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit and push your changes
4. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

[Raspberry Pi Foundation](https://www.raspberrypi.org/) · [FFmpeg](https://ffmpeg.org/) · [Nginx](https://nginx.org/) · [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module) · [Quectel](https://www.quectel.com/)

---

<div align="center">

**Built with ❤️ for the drone and IoT community**

[⬆ Back to Top](#-global-video-telemetry-system-via-internet)

</div>