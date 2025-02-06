#!/bin/bash

# Load configuration from dvd-ripper.conf
CONFIG_FILE="/etc/dvd-ripper.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Exiting..."
    exit 1
fi

LOG_FILE="/var/log/dvd-ripper-setup.log"
SCRIPT_DIR="/opt/dvd-ripper"
SERVICE_DIR="/etc/systemd/system"
ZIP_FILE="scripts.zip"

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
echo "$SHARE_USER=$SHARE_PASS" | sudo tee /etc/.smbcredentials > /dev/null
sudo chmod 600 /etc/.smbcredentials

echo "$SHARE_PATH $WINDOWS_MOUNT cifs credentials=/etc/.smbcredentials,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0" | sudo tee -a /etc/fstab
sudo mkdir -p "$WINDOWS_MOUNT"
sudo mount -a

log "Setup complete! Auto-rip service is now running."

