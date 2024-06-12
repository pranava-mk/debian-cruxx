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

# Interactive Prompt
prompt_user() {
  read -p "$1 (Press Enter to continue...)"
}

# Install Terminus Fonts
prompt_user "Ready to install Terminus Fonts?"
apt-get install -y fonts-terminus

# Set the font to Terminus Fonts
prompt_user "Setting Terminus Font..."
setfont /usr/share/consolefonts/Uni3-TerminusBold28x14.psf.gz
clear

# Install Firefox-ESR
prompt_user "Ready to install Firefox-ESR?"
apt-get update
apt-get install -y firefox-esr

# Update packages list and update system
prompt_user "Updating package list and system..."
apt-get update
apt-get upgrade -y

# Install nala
prompt_user "Installing nala..."
apt-get install -y nala

# Making .config and Moving config files and wallpapers to Pictures
prompt_user "Setting up directories and moving configuration files..."
cd $builddir
mkdir -p /home/$username/.config /home/$username/.fonts /home/$username/.icons /home/$username/.themes /home/$username/Pictures/wallpapers
cp -R dotconfig/* /home/$username/.config/
cp -R doticons/* /home/$username/.icons/
cp -R dotthemes/* /home/$username/.themes/
cp -R wallpapers/* /home/$username/Pictures/wallpapers/
chown -R $username:$username /home/$username

# Installing essential programs
prompt_user "Installing essential programs..."
nala install -y i3 i3blocks feh terminator rofi picom thunar lightdm lxpolkit x11-xserver-utils unzip wget curl pipewire pavucontrol build-essential libx11-dev libxft-dev libxinerama-dev libx11-xcb-dev libxcb-res0-dev zoxide xdg-utils network-manager network-manager-gnome bluetooth bluez brightnessctl

# Installing other programs
prompt_user "Installing additional programs..."
nala install -y flameshot neofetch lxappearance fonts-noto-color-emoji stow

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

# Install Nordzy cursor
prompt_user "Installing Nordzy cursor..."
git clone https://github.com/alvatip/Nordzy-cursors
cd Nordzy-cursors
./install.sh
cd $builddir
rm -rf Nordzy-cursors

# Enable graphical login and change target from CLI to GUI
prompt_user "Enabling graphical login and setting default target to GUI..."
systemctl enable lightdm
systemctl set-default graphical.target

# Dotfiles configuration
prompt_user "Moving your dotfiles into this system..."
cd /home/$username
rm -f ~/.bashrc
git clone https://github.com/pranava-mk/dotfiles.git
cd dotfiles
stow bash i3 i3blocks rofi scripts
cd /home/$username

# Use nala
prompt_user "Running nala script..."
bash scripts/usenala

# Installing Starship
prompt_user "Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh

echo "Installation and configuration completed successfully!"
