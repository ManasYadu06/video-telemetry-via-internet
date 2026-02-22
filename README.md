# video-telemetry-via-internert
# 🌍 Raspberry Pi → AWS → Ground Station Live Video Streaming

Low-latency global video streaming system using:

- **Raspberry Pi Camera**
- **FFmpeg**
- **AWS Cloud Server**
- **Nginx RTMP**
- **RTMP over Port 443 (Firewall Safe)**

---

## 🚀 Project Overview

This project demonstrates a **global live video streaming pipeline** where a Raspberry Pi camera stream is transmitted to an AWS cloud server and viewed remotely on a Ground Station.

The system is designed for:

✔ Drone video transmission  
✔ GSM / LTE networks  
✔ Firewall-restricted environments  
✔ Stable & reliable streaming  

---

## 🏗 System Architecture
Raspberry Pi Camera
│
│ H.264 Stream
▼
FFmpeg
│
│ RTMP (TCP)
▼
AWS Nginx RTMP Server (Port 443)
│
▼
Ground Station Viewer (FFplay / VLC)




---

## ✅ Key Features

- Global video streaming
- Works over GSM / LTE
- Firewall-safe (Port 443)
- Stable TCP transport
- HD video quality
- ~5 second latency

---

## 📦 Requirements

### Raspberry Pi

- Raspberry Pi OS / Debian
- Raspberry Pi Camera
- `rpicam-vid`
- FFmpeg

Install dependencies:

```bash
sudo apt update
sudo apt install -y ffmpeg
