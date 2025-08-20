#!/bin/sh
set -e
BASE_DIR=$(dirname "$(readlink -f "$0")")

# Logging function
log() {
  echo
  echo "🔧 [$(date +%H:%M:%S)] $1"
  echo
}

log "It is recommended to fully upgrade and reboot the system before initializing the install script."
printf 'Would you like to upgrade the system and reboot? (y/n) '
read answer

if [ "$answer" != "${answer#[Yy]}" ]; then 
    log "Upgrading the system..."
    sudo dnf upgrade -y --refresh

    log "Rebooting the system..."
    systemctl reboot
else
    log "Skipping upgrade. Continuing setup..."
fi

log "Clearing out downloads folder"
rm -rf $BASE_DIR/downloads/*

log "Installing needed libraries"
sudo dnf install python3-pip git -y

log "Importing dnf config for faster downloads"
sudo cp -rf $BASE_DIR/exports/dnf.conf /etc/dnf/dnf.conf

log "Installing JetBrains Mono Nerd Font..."
wget -O $BASE_DIR/downloads/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

DIRECTORY=/usr/local/share/fonts/JetBrainsMonoNerdFont
if [ ! -d "$DIRECTORY" ]; then
  sudo mkdir -p $DIRECTORY
  sudo unzip downloads/JetBrainsMono.zip -d $DIRECTORY
fi

sudo chown -R root: $DIRECTORY
sudo chmod 644 $DIRECTORY/*
sudo restorecon -vFr $DIRECTORY
sudo fc-cache -v

log "Installing Catppuccin cursors..."
wget -O ./downloads/catppuccin-mocha-dark-cursors.zip https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-dark-cursors.zip
unzip ./downloads/catppuccin-mocha-dark-cursors.zip -d ./downloads/catppuccin-mocha-dark-cursors

DIRECTORY=/usr/share/icons/catppuccin-mocha-dark-cursors
if [ ! -d "$DIRECTORY" ]; then
  sudo cp -rf ./downloads/catppuccin-mocha-dark-cursors/catppuccin-mocha-dark-cursors /usr/share/icons/
fi

log "Installing Catppuccin Plymouth theme..."
git clone https://github.com/catppuccin/plymouth.git $BASE_DIR/downloads/catppuccin-plymouth

DIRECTORY=/usr/share/plymouth/themes/catppuccin-mocha
if [ ! -d "$DIRECTORY" ]; then
  sudo cp -rf $BASE_DIR/downloads/catppuccin-plymouth/themes/catppuccin-mocha /usr/share/plymouth/themes/catppuccin-mocha
  sudo plymouth-set-default-theme -R catppuccin-mocha
fi

log "Creating home directories..."
DIRECTORY=~/OneDrive
if [ ! -d "$DIRECTORY" ]; then
  mkdir $DIRECTORY
fi

DIRECTORY=~/Applications
if [ ! -d "$DIRECTORY" ]; then
  mkdir $DIRECTORY
fi

DIRECTORY=~/.cache/games/ow2
if [ ! -d "$DIRECTORY" ]; then
  mkdir -p $DIRECTORY
fi

log "Setting up VSCode and RPM Fusion repositories..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

log "Installing NVIDIA drivers and multimedia codecs..."
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install -y akmod-nvidia
sudo dnf mark user akmod-nvidia
sudo dnf install -y xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs xorg-x11-drv-nvidia-power vulkan nvidia-vaapi-driver libva-utils vdpauinfo
sudo systemctl enable nvidia-{suspend,resume,hibernate}
echo 'options nvidia NVreg_TemporaryFilePath=/var/tmp' | sudo tee /etc/modprobe.d/nvidia.conf

# # Comment out the following lines if you do not want to set up Secure Boot keys for NVIDIA modules
# log "Setting up Secure Boot keys for NVIDIA modules..."
# sudo dnf install kmodtool akmods mokutil openssl
# sudo kmodgenca -a
# sudo mokutil --import /etc/pki/akmods/certs/public_key.der

log "Installing base packages..."
sudo dnf clean all
sudo dnf install -y nodejs yarnpkg code bat zsh btop fzf fastfetch timeshift wine steam onedrive papirus-icon-theme
sudo dnf clean all

log "Removing unused KDE applications..."
sudo dnf remove -y plasma-discover kmailtransport kmail elisa-player korganizer kcalc dragon neochat firefox

log "Installing ChezMoi and r2modman RPMs..."
wget -O $BASE_DIR/downloads/chezmoi-2.62.5-x86_64.rpm https://github.com/twpayne/chezmoi/releases/download/2.62.5/chezmoi-2.62.5-x86_64.rpm
wget -O $BASE_DIR/downloads/r2modman-3.2.0.x86_64.rpm https://github.com/ebkr/r2modmanPlus/releases/download/v3.2.0/r2modman-3.2.0.x86_64.rpm
sudo dnf install -y $BASE_DIR/downloads/chezmoi-2.62.5-x86_64.rpm $BASE_DIR/downloads/r2modman-3.2.0.x86_64.rpm
sudo dnf clean all

log "Installing Eza binary..."
wget -O $BASE_DIR/downloads/eza_x86_64-unknown-linux-gnu.zip https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.zip
FILE=/usr/local/bin/eza
if [ ! -f "$FILE" ]; then
  sudo unzip $BASE_DIR/downloads/eza_x86_64-unknown-linux-gnu.zip -d /usr/local/bin
fi

log "Installing OneDriveGUI AppImage..."
wget -O $BASE_DIR/downloads/OneDriveGUI-1.1.1-x86_64.AppImage https://github.com/bpozdena/OneDriveGUI/releases/download/v1.1.1a/OneDriveGUI-1.1.1-x86_64.AppImage
cp -f $BASE_DIR/downloads/OneDriveGUI-1.1.1-x86_64.AppImage ~/Applications
chmod +x ~/Applications/OneDriveGUI-1.1.1-x86_64.AppImage

log "Adding Flathub repository..."
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

log "Removing fedora flatpak remote..."
flatpak remote-delete fedora

log "Installing Flatpak applications..."
flatpaks=(
  com.bitwarden.desktop
  com.getpostman.Postman
  com.github.IsmaelMartinez.teams_for_linux
  com.lunarclient.LunarClient
  com.obsproject.Studio
  com.spotify.Client
  com.vivaldi.Vivaldi
  dev.vencord.Vesktop
  io.github.shiftey.Desktop
  net.lutris.Lutris
  org.blender.Blender
  org.fedoraproject.MediaWriter
  org.gnome.Boxes
  org.gnome.Calculator
  org.kde.krita
  org.kde.kronometer
  org.localsend.localsend_app
  org.qbittorrent.qBittorrent
  org.videolan.VLC
  org.vinegarhq.Sober
  org.vinegarhq.Vinegar
  xyz.xclicker.xclicker
)

for flatpak in ${flatpaks[@]}; do
  flatpak install -y flathub $flatpak
done

mkdir -p ~/.config/user-tmpfiles.d
echo 'L %t/discord-ipc-0 - - - - .flatpak/dev.vencord.Vesktop/xdg-run/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
systemctl --user enable --now systemd-tmpfiles-setup.service

log "Importing sddm theme and configuration"
sudo cp -rf $BASE_DIR/exports/where_is_my_sddm_theme /usr/share/sddm/themes/where_is_my_sddm_theme 

log "Installing Catppuccin GRUB theme..."
git clone https://github.com/catppuccin/grub.git $BASE_DIR/downloads/catppuccin-grub

DIRECTORY=/usr/share/grub/themes/catppuccin-mocha-grub-theme
if [ ! -d "$DIRECTORY" ]; then
  sudo mkdir -p $DIRECTORY
  sudo cp -rf $BASE_DIR/downloads/catppuccin-grub/src/catppuccin-mocha-grub-theme /usr/share/grub/themes/
fi

log "Configuring GRUB with custom options..."
# UUID=$(sudo blkid | awk '/swap/ && !/zram/ { match($0, /UUID="([^"]+)"/, a); print a[1] }')
# sed -i "s/\(resume=UUID=\)[^[:space:]\"]*/\1$UUID/" exports/grub
sudo cp -f $BASE_DIR/exports/grub /etc/default/grub

log "Change hostname"
sudo hostnamectl set-hostname the-yp-machine

log "Build bat cache"
bat cache --build

log "Updating GRUB and regenerating initramfs..."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo dracut --regenerate-all --force

log "Installing oh-my-zsh and plugins"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/catppuccin/zsh-syntax-highlighting.git
cd zsh-syntax-highlighting/themes/
cp -f catppuccin_mocha-zsh-syntax-highlighting.zsh ~/.oh-my-zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh
chsh -s $(which zsh)

log "Installing starship"
curl -sS https://starship.rs/install.sh | sh

chezmoi init git@github.com:YP501/kde-dotfiles.git
chezmoi apply -v

log "🎉 Setup complete! It is recommended to reboot the system now."
read -p "Would you like to reboot? (y/n): " reboot_answer
if [ "$reboot_answer" != "${reboot_answer#[Yy]}" ]; then
    sudo reboot
fi
