# RTMP Server Setup & Testing Guide

## Option 1: Using Docker (Recommended)
If Docker daemon is not running, start it first:

**For Docker Desktop (GUI):**
- Open Docker Desktop application
- Wait for it to fully start

**For systemd (Linux):**
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

**Then run MediaMTX RTMP server:**
```bash
docker run --rm -it -p 1935:1935 -p 8554:8554 bluenviron/mediamtx
```

**App Configuration:**
- RTMP URL: `rtmp://127.0.0.1:1935/live`
- Stream Key: `mystream` (or any name)
- Full URL: `rtmp://127.0.0.1:1935/live/mystream`

---

## Option 2: Using nginx-rtmp (Local Installation)

**1. Install nginx with RTMP module:**
```bash
sudo apt-get update
sudo apt-get install nginx-full
```

**2. Create RTMP configuration file:**
```bash
sudo nano /etc/nginx/modules-enabled/rtmp.conf
```

**3. Add this configuration:**
```nginx
rtmp {
    server {
        listen 1935;
        
        application live {
            live on;
            record off;
            allow publish all;
            allow play all;
        }
    }
}
```

**4. Verify and start nginx:**
```bash
sudo nginx -t
sudo systemctl restart nginx
```

**App Configuration:**
- RTMP URL: `rtmp://127.0.0.1:1935/live`
- Stream Key: `mystream`
- Full URL: `rtmp://127.0.0.1:1935/live/mystream`

---

## Option 3: Using MediaMTX Locally (No Docker)

**1. Download MediaMTX:**
```bash
# For Linux x86_64
wget https://github.com/bluenviron/mediamtx/releases/download/v1.3.0/mediamtx_v1.3.0_linux_amd64.tar.gz
tar xzf mediamtx_v1.3.0_linux_amd64.tar.gz
```

**2. Run it:**
```bash
./mediamtx
```

The server will start on port 1935 (RTMP) and 8554 (RTSP).

**App Configuration:**
- RTMP URL: `rtmp://127.0.0.1:1935/live`
- Stream Key: `mystream`
- Full URL: `rtmp://127.0.0.1:1935/live/mystream`

---

## Testing the App

### Step 1: Ensure Server is Running
Before starting the app, verify your RTMP server is listening on port 1935:
```bash
netstat -an | grep 1935
# or
lsof -i :1935
```

### Step 2: Configure App
1. Launch the Flutter app
2. In the RTMP Setup page, enter:
   - **RTMP URL:** `rtmp://127.0.0.1:1935/live`
   - **Stream Key:** `mystream`

### Step 3: Test Connection
1. Click **"LAUNCH CAMERA PREVIEW"** first (test mode)
   - This will try to connect without starting a full stream
   - Should see "Connection successful! ✓" if server is working
   
2. If test succeeds, click **"CONNECT & STREAM"**
   - This starts actual streaming
   - You'll see "LIVE · RTMP" status badge

### Step 4: Verify Stream (Optional)
**Using ffprobe to check stream:**
```bash
ffprobe rtmp://127.0.0.1:1935/live/mystream
```

**Using VLC Player:**
1. Open VLC
2. Media → Open Network Stream
3. Enter: `rtmp://127.0.0.1:1935/live/mystream`
4. Click Play

---

## Troubleshooting

### Issue: "Connection failed: Timeout after 60 seconds"
**Causes:**
- RTMP server not running
- Port 1935 blocked by firewall
- Wrong URL or stream key

**Solutions:**
1. Check if server is running:
   ```bash
   netstat -an | grep 1935
   ```
2. Check firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 1935
   ```
3. Verify the exact URL matches your server

### Issue: "No response from server"
- Server process crashed, restart it
- Check server logs for errors
- Try the test connection first

### Issue: App works but can't view stream elsewhere
- Make sure your streaming machine IP matches (127.0.0.1 for local)
- If accessing from another machine, use the server's actual IP
- Ensure firewall allows port 1935

---

## Network Testing (For Remote Devices)

If testing from an Android phone on the same network:

1. Find your computer's IP:
   ```bash
   hostname -I
   # or
   ifconfig | grep "inet "
   ```

2. Use that IP in the app:
   - RTMP URL: `rtmp://YOUR_COMPUTER_IP:1935/live`
   - Stream Key: `mystream`

Example:
- Computer IP: `192.168.1.100`
- Phone connects to: `rtmp://192.168.1.100:1935/live/mystream`

---

## Quick Start Summary

**Fastest way to test:**

### With Docker:
```bash
docker run --rm -it -p 1935:1935 -p 8554:8554 bluenviron/mediamtx
```

### Without Docker:
```bash
# Download and extract
wget https://github.com/bluenviron/mediamtx/releases/download/v1.3.0/mediamtx_v1.3.0_linux_amd64.tar.gz
tar xzf mediamtx_v1.3.0_linux_amd64.tar.gz

# Run
./mediamtx
```

Then in the app use:
- RTMP URL: `rtmp://127.0.0.1:1935/live`
- Stream Key: `mystream`

---

**Last Updated:** March 1, 2026
