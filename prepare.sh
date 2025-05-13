#!/bin/sh
BASE_DIR=$(dirname "$(readlink -f "$0")")

log() {
  echo
  echo "🔧 [$(date +%H:%M:%S)] $1"
  echo
}

# Clearing downloads and exports folder
log "Clearing downloads and exports folder"
rm -r $BASE_DIR/exports/*
rm -r $BASE_DIR/downloads/*

# Backup Chezmoi configurations
cd ~/.local/share/chezmoi
log "Re-adding files to Chezmoi"
chezmoi re-add
log "Committing changes to Git"
chezmoi git add .
git commit -m "Backup $(date)"
log "Pushing changes to Git repository"
git push -u origin main

# Backup non-home files
log "Exporting sddm theme and configuration"
cp -r /usr/share/sddm/themes/where_is_my_sddm_theme $BASE_DIR/exports/where_is_my_sddm_theme

log "Exporting dnf config"
cp /etc/dnf/dnf.conf $BASE_DIR/exports/dnf.conf

log "Exporting grub config file"
cp /etc/default/grub $BASE_DIR/exports/grub


log "Backup completed successfully!"
