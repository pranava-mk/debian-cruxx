#!/bin/bash

# Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run sudo ./install.sh" >&2
  exit 1
fi

# Dynamic username retrieval for the user with UID 1000
username=$(getent passwd 1000 | cut -d: -f1)
builddir=$(pwd)

# Function to handle errors
handle_error() {
  echo "Error on line $1"
  exit 1
}
trap 'handle_error $LINENO' ERR

# Function to show progress bar
show_progress() {
  local duration=$1
  local increment=$(echo "scale=2; 100 / $duration" | bc)
  for ((i = 0; i <= duration; i++)); do
    echo -n "Progress: ["
    for ((j = 0; j < $i; j++)); do echo -n "="; done
    for ((j = $i; j < duration; j++)); do echo -n " "; done
    echo -n "] $(echo "$i * $increment" | bc)%"
    echo -ne "\r"
    sleep 1
  done
  echo
}

# Interactive Prompt
prompt_user() {
  read -p "$1 (Press Enter to continue...)"
}

# Install Terminus Fonts
prompt_user "Ready to install Terminus Fonts?"
apt-get install -y fonts-terminus
show_progress 5

# Set the font to Terminus Fonts
prompt_user "Setting Terminus Font..."
setfont /usr/share/consolefonts/Uni3-TerminusBold28x14.psf.gz
clear
show_progress 5

# Install Firefox-ESR
prompt_user "Ready to install Firefox-ESR?"
apt-get update
apt-get install -y firefox-esr
show_progress 10

# Update packages list and update system
prompt_user "Updating package list and system..."
apt-get update
apt-get upgrade -y
show_progress 15

# Install nala
prompt_user "Installing nala..."
apt-get install -y nala
show_progress 5

# Making .config and Moving config files and wallpapers to Pictures
prompt_user "Setting up directories and moving configuration files..."
cd $builddir
mkdir -p /home/$username/.config /home/$username/.fonts /home/$username/.icons /home/$username/.themes /home/$username/Pictures/wallpapers
cp -R dotconfig/* /home/$username/.config/
cp -R doticons/* /home/$username/.icons/
cp -R dotthemes/* /home/$username/.themes/
cp -R wallpapers/* /home/$username/Pictures/wallpapers/
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username
show_progress 10

# Installing essential programs
prompt_user "Installing essential programs..."
nala install -y i3 i3blocks feh terminator rofi picom thunar lightdm lxpolkit x11-xserver-utils unzip wget curl pipewire wireplumber pavucontrol build-essential libx11-dev libxft-dev libxinerama-dev libx11-xcb-dev libxcb-res0-dev zoxide xdg-utils network-manager network-manager-gnome pavucontrol bluetooth bluez brightnessctl
show_progress 20

# Installing other programs
prompt_user "Installing additional programs..."
nala install -y flameshot neofetch lxappearance fonts-noto-color-emoji stow
show_progress 10

# Installing fonts (also moving fonts from dotfonts to .fonts)
prompt_user "Installing fonts..."
cd $builddir 
nala install -y fonts-font-awesome
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d /home/$username/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip
unzip Meslo.zip -d /home/$username/.fonts
mv dotfonts/* /home/$username/.fonts
chown $username:$username /home/$username/.fonts/*
fc-cache -vf
rm ./FiraCode.zip ./Meslo.zip
show_progress 15

# Install Nordzy cursor
prompt_user "Installing Nordzy cursor..."
git clone https://github.com/alvatip/Nordzy-cursors
cd Nordzy-cursors
./install.sh
cd $builddir
rm -rf Nordzy-cursors
show_progress 10

# Enable graphical login and change target from CLI to GUI
prompt_user "Enabling graphical login and setting default target to GUI..."
systemctl enable lightdm
systemctl set-default graphical.target
show_progress 5

# Enable wireplumber audio service
prompt_user "Enabling wireplumber audio service..."
sudo -u $username systemctl --user enable wireplumber.service
show_progress 5

# Dotfiles configuration
prompt_user "Moving your dotfiles into this system..."
cd /home/$username
rm -f ~/.bashrc
git clone https://github.com/pranava-mk/dotfiles.git
cd dotfiles
stow bash i3 i3blocks rofi scripts
cd /home/$username
show_progress 10

# Use nala
prompt_user "Running nala script..."
bash scripts/usenala
show_progress 10

# Installing Starship
prompt_user "Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh
show_progress 5

echo "Installation and configuration completed successfully!"
