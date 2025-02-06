#!/bin/bash

CONFIG_FILE="/etc/dvd-ripper/dvd-ripper.conf"
SCRIPT_DIR="/etc/dvd-ripper"
LOG_FILE="/var/log/dvd-ripper-setup.log"
SERVICE_DIR="/etc/systemd/system"
ZIP_FILE="scripts.zip"

echo "Creating neccessary directories"
sudo mkdir $SCRIPT_DIR
sudo cp ./dvd-ripper.conf $CONFIG_FILE

# Load configuration from dvd-ripper.conf
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Exiting..."
    exit 1
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting DVD Ripper setup..."

# Step 1: Install Required Packages
log "Installing required packages..."
sudo apt update
sudo apt install -y handbrake-cli inotify-tools cifs-utils eject unzip smbclient

# Step 2: Extract Scripts
log "Extracting scripts..."
sudo mkdir -p "$SCRIPT_DIR"
sudo unzip -o "$ZIP_FILE" -d "$SCRIPT_DIR"
sudo chmod +x "$SCRIPT_DIR"/*.sh

# Step 3: Create Systemd Service for Auto Rip DVD
log "Creating systemd service file for auto-rip-dvd..."
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

# Step 4: Enable and Start Services
log "Enabling and starting auto-rip-dvd service..."
sudo systemctl daemon-reload
sudo systemctl enable --now auto-rip-dvd


# Step 5: Setup Windows Share Mount
log "Setting up Windows share mount..."

echo -e "username=$SHARE_USER\npassword=$SHARE_PASS" | sudo tee /etc/.smbcredentials > /dev/null
sudo chmod 600 /etc/.smbcredentials
sudo chown root:root /etc/.smbcredentials

echo "$SHARE_PATH $WINDOWS_MOUNT cifs credentials=/etc/.smbcredentials,iocharset=utf8,sec=ntlm,vers=3.0,file_mode=0777,dir_mode=0777 0 0" | sudo tee -a /etc/fstab
sudo mkdir -p "$WINDOWS_MOUNT"

log "Testing Windows share mount..."
sudo mount -t cifs $SHARE_PATH $WINDOWS_MOUNT -o credentials=/etc/.smbcredentials

if mountpoint -q "$WINDOWS_MOUNT"; then
    log "Windows share mounted successfully!"
else
    log "Error mounting Windows share. Please check credentials and network settings."
fi
sudo systemctl status auto-rip-dvd
