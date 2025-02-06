#!/bin/bash

# Load configuration from dvd-ripper.conf
CONFIG_FILE="/etc/dvd-ripper/dvd-ripper.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Exiting..."
    exit 1
fi

LOG_FILE="/var/log/dvd-rip.log"
mkdir -p "$OUTPUT_DIR" "$TEMP_OUTPUT_DIR"
touch "$LOG_FILE"

log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message" | tee -a "$LOG_FILE"
    echo "$message" > /dev/tty1
}

rip_dvd() {
    sudo mount "$WATCH_DEVICE" "$MOUNT_POINT" 2>/dev/null
    sleep 2  # Give it time to mount

    if mountpoint -q "$MOUNT_POINT"; then
        TITLE=$(lsdvd "$WATCH_DEVICE" | grep "Disc Title" | awk -F ': ' '{print $2}')
        if [[ -z "$TITLE" ]]; then
            TITLE="dvd_$(date +%F_%H-%M-%S)"
        fi

        OUTPUT_FILE="$TEMP_OUTPUT_DIR/$TITLE.mp4"

        log "Starting rip: $TITLE..."
        HandBrakeCLI -i "$MOUNT_POINT" -o "$OUTPUT_FILE" --preset="Fast 1080p30" 2>&1 | while IFS= read -r line
        do
            log "HandBrake: $line"
        done

        if [[ -f "$OUTPUT_FILE" ]]; then
            log "Rip complete: $OUTPUT_FILE"
            sudo umount "$WATCH_DEVICE"
            log "Ejecting DVD..."
            eject "$WATCH_DEVICE"
            
            log "Moving $OUTPUT_FILE to final directory: $OUTPUT_DIR"
            mv "$OUTPUT_FILE" "$OUTPUT_DIR"

            if [[ $? -eq 0 ]]; then
                log "File moved successfully!"
            else
                log "Error moving file!"
            fi
        else
            log "Rip failed! No output file found."
        fi
    fi
}

log "Starting DVD watch script..."

while true; do
    if [ -b "$WATCH_DEVICE" ] && ! mountpoint -q "$MOUNT_POINT"; then
        rip_dvd
    fi
    sleep 10
done
