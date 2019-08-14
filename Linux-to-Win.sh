#!/bin/bash
#
#Vars
echo "[Install Win for Linux edit by Haku]"
mounted=0
GREEN='\033[1;32m';GREEN_D='\033[0;32m';RED='\033[0;31m';YELLOW='\033[0;33m';BLUE='\033[0;34m';NC='\033[0m'
# Virtualization checking..
virtu=$(egrep -i '^flags.*(vmx|svm)' /proc/cpuinfo | wc -l)
if [ $virtu = 0 ] ; then echo -e "[Error] ${RED}Virtualization/KVM in your Server/VPS is OFF\nExiting...${NC}";
else
#
# Deleting Previous Windows Installation by the Script
#umount -l /mnt /media/script /media/sw
#rm -rf /mediabots /floppy /virtio /media/* /tmp/*
#rm -f /sw.iso /disk.img 
# installing required Ubuntu packages
dist=$(hostnamectl | egrep "Operating System" | cut -f2 -d":" | cut -f2 -d " ")
if [ $dist = "CentOS" ] ; then
	printf "Y\n" | yum install sudo -y
	sudo yum install wget vim curl genisoimage -y
	# Downloading Portable QEMU-KVM
	echo "Downloading QEMU"
	sudo yum update -y
	sudo yum install -y qemu-kvm
elif [ $dist = "Ubuntu" -o $dist = "Debian" ] ; then
	printf "Y\n" | apt-get install sudo -y
	sudo apt-get install vim curl genisoimage -y
	# Downloading Portable QEMU-KVM
	echo "Downloading QEMU"
	sudo apt-get update
	sudo apt-get install -y qemu-kvm
fi
sudo ln -s /usr/bin/genisoimage /usr/bin/mkisofs
# Downloading resources
sudo mkdir /mediabots /floppy /virtio
link1_status=$(curl -Is http://51.15.226.83/WS2012R2.ISO | grep HTTP | cut -f2 -d" ")
link2_status=$(curl -Is https://51.15.226.83/WS2012R2.ISO | grep HTTP | cut -f2 -d" ")
#sudo wget -P /mediabots https://archive.org/download/WS2012R2/WS2012R2.ISO # Windows Server 2012 R2 
if [ $link1_status = "200" ] ; then 
	sudo wget -P /mnt http://hakuit.com/WS2012R2.ISO
elif [ $link2_status = "200" -o $link2_status = "301" ] ; then 
	sudo wget -P /mnt https://ia601506.us.archive.org/4/items/WS2012R2/WS2012R2.ISO
else
	echo -e "${RED}[Error]${NC} ${YELLOW}Sorry! None of Windows OS image urls are available , please report about this issue on Github page : ${NC}https://github.com/mediabots/Linux-to-Windows-with-QEMU"
	echo "Exiting.."
	sleep 30
	exit 1
fi
sudo wget -P /floppy https://ftp.mozilla.org/pub/firefox/releases/64.0/win32/en-US/Firefox%20Setup%2064.0.exe
sudo mv /floppy/'Firefox Setup 64.0.exe' /floppy/Firefox.exe
sudo wget -P /floppy https://downloadmirror.intel.com/23073/eng/PROWinx64.exe # Intel Network Adapter for Windows Server 2012 R2 
# Blood.exe
sudo wget -p /floopy http://bit.ly/31v2cnp
# ConfigVps.exe
sudo wget -p /floopy http://bit.ly/2Kyih64
sudo wget -p /floppy https://github.com/haku1806/Auto-Blood/raw/master/autoBloodConfig-9-2Beta.exe
sudo wget -p /floppy wget https://raw.githubusercontent.com/haku1806/Auto-Blood/master/config.txt
# Powershell script to auto enable remote desktop for administrator
sudo touch /floppy/EnableRDP.ps1
sudo echo -e "Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -Name \"fDenyTSConnections\" -Value 0" >> /floppy/EnableRDP.ps1
sudo echo -e "Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -Name \"UserAuthentication\" -Value 1" >> /floppy/EnableRDP.ps1
sudo echo -e "Enable-NetFirewallRule -DisplayGroup \"Remote Desktop\"" >> /floppy/EnableRDP.ps1
# Downloading Virtio Drivers
sudo wget -P /virtio https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
# creating .iso for Windows tools & drivers
sudo mkisofs -o /sw.iso /floppy
#
#Enabling KSM
sudo echo 1 > /sys/kernel/mm/ksm/run
#Free memories
sync; sudo echo 3 > /proc/sys/vm/drop_caches
