# DVD Auto Ripper & File Mover

This project automates **ripping DVDs** to MP4 format using `HandBrakeCLI` and **transfers** the ripped files to a Windows share drive. It runs as background services on an **Ubuntu Server**.

## **Features**
✅ Automatically detects and rips DVDs using `HandBrakeCLI`  
✅ Moves ripped files to a **Windows share** after completion  
✅ Runs as a **systemd service** for continuous operation  
✅ Supports **custom configuration** via `/etc/dvd-ripper.conf`  
✅ Logs all activities for easy monitoring  

---

## **Setup Instructions**

### **Step 1: Prepare Your Server**
Ensure your **Ubuntu Server** is up-to-date:
```bash
sudo apt update && sudo apt upgrade -y
```

### **Step 2: Copy Files**
Ensure your `setup.sh` script and `scripts.zip` archive are available. Then, follow these steps:

1. Clone this repo:
    git clone https://github.com/AyresJeremiah/Auto-Dvd-Ripper.git
2. Edit the dvd-ripper.conf to you liking.
    Note if you chage the dir from "/etc/dvd-ripper/" you will need to edit the service script.
3. Make the script executable and run it.
    chmod +x setup.sh
    sudo ./setup.sh

This will:
- Install required packages (`HandBrakeCLI`, `inotify-tools`, `cifs-utils`, etc.)
- Extract scripts to `/opt/dvd-ripper/`
- Set up configuration at `/etc/dvd-ripper.conf`
- Create and enable systemd services
- Configure Windows share mounting

---

## **Configuration**
Edit `/etc/dvd-ripper/dvd-ripper.conf` to customize settings:
```bash
sudo nano /etc/dvd-ripper.conf
```

### **Configuration File Example**
```ini
# DVD Ripper Configuration File

# Windows Share Settings
SHARE_PATH="//192.168.1.100/SharedFolder"
SHARE_USER="your_user"
SHARE_PASS="your_password"

# Local Mount Points
WATCH_DEVICE="/dev/sr0"
MOUNT_POINT="/mnt/dvd"
OUTPUT_DIR="/mnt/windows-share"
TEMP_OUTPUT_DIR="/home/user/dvd-rips-temp"
WINDOWS_MOUNT="/mnt/windows-share"
```

After changes, restart services:
```bash
sudo systemctl restart auto-rip-dvd watch-and-move
```

---

## **Usage**
### **Check Service Status**
```bash
sudo systemctl status auto-rip-dvd
sudo systemctl status watch-and-move
```

### **View Logs**
```bash
tail -f /var/log/dvd-rip.log
tail -f /var/log/dvd-transfer.log
```

### **Manually Start/Stop Services**
```bash
sudo systemctl start auto-rip-dvd watch-and-move
sudo systemctl stop auto-rip-dvd watch-and-move
```

---

## **File Descriptions**
| File                  | Description |
|----------------------|------------------------------------------------|
| `setup.sh`           | Installs required packages and configures the system |
| `auto-rip-dvd.sh`    | Monitors for DVDs, rips them, and ejects when done |
| `watch-and-move.sh`  | Moves ripped files to a Windows share drive |
| `getStatus.sh`       | Displays the status of all services |
| `showLog.sh`         | Shows recent log entries |
| `restartServices.sh` | Restarts all related services |
| `startServices.sh`   | Starts all services manually |
| `stopServices.sh`    | Stops all services manually |
| `/etc/dvd-ripper.conf` | Configuration file for customization |

---

## **Uninstall**
To completely remove the DVD Ripper setup:
```bash
sudo systemctl disable auto-rip-dvd watch-and-move
sudo systemctl stop auto-rip-dvd watch-and-move
sudo rm -rf /opt/dvd-ripper /etc/systemd/system/auto-rip-dvd.service /etc/systemd/system/watch-and-move.service /etc/dvd-ripper.conf /var/log/dvd-rip.log /var/log/dvd-transfer.log
```

---

## **Troubleshooting**
### **DVD Not Detected?**
```bash
lsblk
```
Ensure `/dev/sr0` appears. If not, reinsert the DVD.

### **Rip Fails with Permission Error?**
Try running manually:
```bash
sudo HandBrakeCLI -i /mnt/dvd -o test.mp4 --preset="Fast 1080p30"
```
Ensure `HandBrakeCLI` can read the DVD.

### **Files Not Moving to Windows Share?**
Verify the share is mounted:
```bash
df -h | grep "/mnt/windows-share"
```
If it's not mounted, try:
```bash
sudo mount -a
```

---

## **License**
This project is open-source and can be modified as needed.

---

### 🚀 Now your Ubuntu Server will **automatically rip DVDs** and **transfer them to your Windows share**!


