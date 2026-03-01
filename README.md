# 🚁 video-telemetry-via-internet

# 🌍 Raspberry Pi → AWS → Ground Station Video Telemetry System

A global, firewall-safe live video transmission system built using:

- Raspberry Pi Camera (IMX708)
- FFmpeg
- AWS EC2 Cloud Server
- Nginx + RTMP Module
- RTMP over Port 443 (HTTPS-safe)

Designed for drone telemetry and remote surveillance over GSM / LTE networks.

---

## 🚀 Project Overview

This project demonstrates a complete **cloud-based video telemetry pipeline** where:

1. Raspberry Pi captures camera feed
2. Video is encoded as H.264
3. Stream is transmitted via RTMP (TCP)
4. AWS relays the stream
5. Ground Station receives live video

The system works globally and bypasses ISP port restrictions by using **RTMP over Port 443**.

---

## 🏗 System Architecture

```
Raspberry Pi Camera (Drone)
        │
        │  H.264 Stream (rpicam-vid)
        ▼
FFmpeg Encoder
        │
        │  RTMP (TCP - Port 443)
        ▼
AWS EC2 (Nginx + RTMP Module)
        │
        ▼
Ground Station (FFplay / VLC)
```

---

## 🔥 Why Port 443?

Default RTMP uses port 1935.

However:
- Many ISPs block 1935
- College WiFi blocks streaming ports
- GSM networks restrict uncommon ports

Solution:
✔ Use RTMP over port **443**
✔ Firewall-safe
✔ GSM/LTE safe
✔ Industry-standard workaround

---

## ✅ Key Features

- Global cloud-based streaming
- Works over GSM / LTE SIM modules
- Firewall-safe configuration
- Stable TCP transport
- HD 640x480 @ 25fps
- ~5 second latency
- Competition-ready architecture

---

## 📦 Requirements

### 🟢 Raspberry Pi

- Raspberry Pi OS / Debian
- Raspberry Pi Camera (IMX708)
- rpicam-vid
- FFmpeg

Install FFmpeg:

```bash
sudo apt update
sudo apt install -y ffmpeg
```

---

### 🟢 AWS Server

- Ubuntu EC2 instance
- Nginx
- RTMP module

Install:

```bash
sudo apt update
sudo apt install -y nginx libnginx-mod-rtmp
```

---

## ⚙ AWS RTMP Configuration

Edit:

```bash
sudo nano /etc/nginx/nginx.conf
```

Add:

```nginx
rtmp {
    server {
        listen 443;
        chunk_size 4096;

        application live {
            live on;
            record off;
        }
    }
}
```

Restart:

```bash
sudo systemctl restart nginx
```

Verify:

```bash
sudo ss -tulnp | grep 443
```

---

## 🔐 AWS Security Group

Inbound Rules:

| Type | Protocol | Port | Source |
|------|----------|------|--------|
Custom TCP | TCP | 443 | 0.0.0.0/0 |

---

## 📡 Raspberry Pi Streaming Command

```bash
rpicam-vid -t 0 --inline -n -o - | \
ffmpeg -re -fflags nobuffer -flags low_delay \
-i - -c:v copy -f flv \
rtmp://<AWS_PUBLIC_IP>:443/live/stream
```

Example:

```bash
rtmp://18.60.110.180:443/live/stream
```

---

## 🖥 Ground Station Viewing

Using FFplay:

```bash
ffplay rtmp://18.60.110.180:443/live/stream
```

Using VLC:

Media → Open Network Stream  
```
rtmp://18.60.110.180:443/live/stream
```

---

## 📊 Performance Observations

| Parameter | Value |
|-----------|--------|
Resolution | 640x480 |
FPS | 25 |
Bitrate | ~1.2 Mbps |
Latency | ~5 seconds |
Transport | TCP (RTMP) |

Latency caused by:
- GSM jitter
- Cloud buffering
- TCP reliability mechanisms

---

## 🛠 Troubleshooting

### ❌ Connection Timed Out

Test port:

```bash
nc -zv <AWS_IP> 443
```

If failed:
- Check Security Group
- Check Nginx running
- Check ISP restrictions

---

## 🎯 Applications

- Drone live feed transmission
- Remote robotics
- Cloud video telemetry
- Disaster monitoring
- GSM-based surveillance

---

## 🚀 Future Improvements

- Adaptive bitrate streaming
- Hardware H.264 encoding
- WebRTC ultra-low latency mode
- Object detection overlay
- GPS telemetry sync
- Recording & cloud storage

---

## 👨‍💻 Author

Built as a real-world drone telemetry system prototype.