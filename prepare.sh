#!/bin/sh
BASE_DIR=$(dirname "$(readlink -f "$0")")

log() {
  echo
  echo "🔧 [$(date +%H:%M:%S)] $1"
  echo
}

# Creating downloads and exports folder
mkdir $BASE_DIR/downloads
mkdir $BASE_DIR/exports

# Backup Chezmoi configurations
log "Re-adding files to Chezmoi"
chezmoi re-add
log "Committing changes to Git"
chezmoi git -- add -A
chezmoi git -- commit -m "Backup $(date)" || true
log "Pushing changes to Git repository"
chezmoi git -- push

# Backup non-home files

# Temporary disable these to hopefully fix sddm
# log "Exporting sddm theme and configuration"
# cp -r /usr/share/sddm/themes/where_is_my_sddm_theme $BASE_DIR/exports/where_is_my_sddm_theme

log "Exporting dnf config"
cp /etc/dnf/dnf.conf $BASE_DIR/exports/dnf.conf

log "Exporting grub config file"
cp /etc/default/grub $BASE_DIR/exports/grub


log "Backup completed successfully!"
