#!/bin/bash

# Define constants
CONFIG_FILE="/etc/dvd-ripper.conf"
SCRIPT_DIR="/opt/dvd-ripper"
SERVICE_DIR="/etc/systemd/system"
ZIP_FILE="scripts.zip"
LOG_FILE="/var/log/dvd-ripper-setup.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting DVD Ripper setup..."

# Step 1: Install Required Packages
log "Installing required packages..."
sudo apt update
sudo apt install -y handbrake-cli inotify-tools cifs-utils eject unzip

# Step 2: Extract Scripts
log "Extracting scripts..."
sudo mkdir -p "$SCRIPT_DIR"
sudo unzip -o "$ZIP_FILE" -d "$SCRIPT_DIR"
sudo chmod +x "$SCRIPT_DIR"/*.sh

# Step 3: Create Configuration File
if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating configuration file..."
    sudo tee "$CONFIG_FILE" > /dev/null <<EOL
# DVD Ripper Configuration File

# Windows Share Settings
SHARE_PATH="//192.168.1.100/SharedFolder"
SHARE_USER="your_user"
SHARE_PASS="your_password"

# Local Mount Points
WATCH_DEVICE="/dev/sr0"
MOUNT_POINT="/mnt/dvd"
OUTPUT_DIR="/home/jeremiah/dvd-rips"
TEMP_OUTPUT_DIR="/home/jeremiah/dvd-rips-temp"
WINDOWS_MOUNT="/mnt/windows-share"
EOL
fi

# Step 4: Create Systemd Services
log "Creating systemd service files..."

# Auto Rip DVD Service
sudo tee "$SERVICE_DIR/auto-rip-dvd.service" > /dev/null <<EOL
[Unit]
Description=Auto DVD Ripping Service
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/auto-rip-dvd.sh
Restart=always
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOL

# Watch and Move Service
sudo tee "$SERVICE_DIR/watch-and-move.service" > /dev/null <<EOL
[Unit]
Description=Watch and Move DVD Files to Share
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/watch-and-move.sh
Restart=always
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOL

# Step 5: Enable and Start Services
log "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable --now auto-rip-dvd watch-and-move

# Step 6: Setup Windows Share Mount
log "Setting up Windows share mount..."
source "$CONFIG_FILE"
echo "$SHARE_USER=$SHARE_PASS" | sudo tee /etc/.smbcredentials > /dev/null
sudo chmod 600 /etc/.smbcredentials

echo "$SHARE_PATH $WINDOWS_MOUNT cifs credentials=/etc/.smbcredentials,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0" | sudo tee -a /etc/fstab
sudo mkdir -p "$WINDOWS_MOUNT"
sudo mount -a

log "Setup complete! Services are now running."

