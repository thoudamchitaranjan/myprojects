#!/bin/sh

# This script will recompile the ALSA drivers for Ubuntu
# This procedure was gotten from
# https://help.ubuntu.com/community/HdaIntelSoundHowto
#
# Authored by Bob Nelson  admin@stchman.com
#
# This script updated 9/6/2007


script_name="alsa_setup.sh"

# Script must run as root 
if [ $USER != "root" ]; then
	echo "You need to run this script as root."
	echo "Use 'sudo ./$script_name' then enter your password when prompted."
	exit 1
fi

# Install the required tools
sudo apt-get -y install build-essential ncurses-dev gettext

# Install your kernel headers
sudo apt-get -y install linux-headers-`uname -r`

# Change to users home folder
cd ~

# Get the files from www.stchman.com
wget http://www.stchman.com/tools/alsa/alsa-driver-1.0.16.tar.bz2
wget http://www.stchman.com/tools/alsa/alsa-lib-1.0.16.tar.bz2
wget http://www.stchman.com/tools/alsa/alsa-utils-1.0.16.tar.bz2

# make a new folder 
sudo mkdir -p /usr/src/alsa

# Change to that folder
cd /usr/src/alsa

# Copy the downloaded files to the newly made folder
sudo cp ~/alsa* .

# Unpack the tar archive files
sudo tar xjf alsa-driver*
sudo tar xjf alsa-lib*
sudo tar xjf alsa-utils*

#Compile and install alsa-driver
cd alsa-driver*
sudo ./configure --with-cards=hda-intel --with-kernel=/usr/src/linux-headers-$(uname -r)
sudo make
sudo make install

# Compile and install alsa-lib
cd ../alsa-lib*
sudo ./configure
sudo make
sudo make install

# Compile and install alsa-utils
cd ../alsa-utils*
sudo ./configure
sudo make
sudo make install

# Remove the archives as they are no longer needed
rm -f ~/alsa-driver*
rm -f ~/alsa-lib*
rm -f ~/alsa-utils*

# Add the following line to the file, replacing '3stack' with your model
sudo echo -e '\n' >> /etc/modprobe.d/alsa-base
sudo echo "options snd-hda-intel model=3stack" >> /etc/modprobe.d/alsa-base

# Reboot the computer
sudo reboot
