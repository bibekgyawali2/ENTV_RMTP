# 📱 Testing on Phone - Local Network Setup

## Your Computer Details
- **Local IP Address:** `192.168.1.100`
- **RTMP Server Status:** ✅ Running on port 1935

---

## Step 1: Ensure Phone is on Same WiFi Network
Make sure your phone is connected to the **same WiFi network** as your computer.

---

## Step 2: Use These Settings in Your Flutter App

### RTMP Configuration:
```
RTMP URL:   rtmp://192.168.1.100:1935/live
Stream Key: mystream
Full URL:   rtmp://192.168.1.100:1935/live/mystream
```

> **Note:** Replace `192.168.1.100` with the IP from your computer if different

---

## Step 3: Test Connection First
1. Open the Flutter app on your phone
2. Enter the configuration above in the RTMP Setup page
3. Click **"LAUNCH CAMERA PREVIEW"**
4. Wait for connection test result
   - ✅ **Success:** "Connection successful!" → Go to Step 4
   - ❌ **Failed:** See Troubleshooting section below

---

## Step 4: Start Streaming
If connection test succeeds:
1. Click **"CONNECT & STREAM"**
2. You should see "LIVE · RTMP" status
3. Your phone's camera is now streaming!

---

## Troubleshooting

### Issue: "Connection failed: Timeout after 60 seconds"

**Check 1: Verify same WiFi network**
```bash
# On phone, check WiFi name and IP
# iPhone: Settings → WiFi
# Android: Settings → WiFi → Long press network → View Network
```

**Check 2: Verify computer IP is correct**
```bash
# On computer, check actual IP:
hostname -I

# Use this IP in the app
```

**Check 3: Check firewall is allowing port 1935**
```bash
# On computer:
sudo ufw status
sudo ufw allow 1935
sudo ufw reload

# Then test again on phone
```

**Check 4: Verify server is still running**
```bash
# On computer:
ps aux | grep mediamtx | grep -v grep

# If not running, restart:
/tmp/mediamtx > /tmp/mediamtx.log 2>&1 &
```

### Issue: "Network unreachable"
- Phone might be on different WiFi network
- Try pinging the computer IP from phone's terminal/app
- Make sure both are on same WiFi (not 2.4GHz vs 5GHz confusion)

### Issue: Server appears down
```bash
# Check server logs:
tail -f /tmp/mediamtx.log

# Restart server:
pkill -f mediamtx
sleep 1
/tmp/mediamtx > /tmp/mediamtx.log 2>&1 &

# Verify it's running:
ps aux | grep mediamtx | grep -v grep
```

---

## Quick Reference

| Item | Value |
|------|-------|
| Computer IP | 192.168.1.100 |
| RTMP Port | 1935 |
| RTMP URL | rtmp://192.168.1.100:1935/live |
| Stream Key | mystream |
| Server Type | MediaMTX v1.3.0 |
| Server Status | ✅ Running |

---

## If IP Changed
If your computer IP is different, update the app with:
```
rtmp://[YOUR_NEW_IP]:1935/live
```

Get your IP anytime with:
```bash
hostname -I | awk '{print $1}'
```

---

## Streaming Indicators

**While streaming, look for:**
- ✅ Green "LIVE · RTMP" badge at top
- ✅ Camera preview visible
- ✅ Volume indicator visible (top-left)
- ✅ Pause/Resume button available (bottom)

**If something's wrong:**
- ❌ Red "DISCONNECTED · RTMP" badge → Server connection lost
- ❌ Orange "RETRYING · RTMP" → Server rejected connection
- ❌ Loading spinner → Still connecting

---

**Last Updated:** March 1, 2026
**Ready to test on your phone! 📱**
