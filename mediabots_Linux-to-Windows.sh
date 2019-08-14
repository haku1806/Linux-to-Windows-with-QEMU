#!/bin/bash
#
#Vars
echo "[Install Win for Linux edit by Haku"
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
# Gathering System information
idx=0
fs=($(df | awk '{print $1}'))
for j in $(df | awk '{print $6}');do if [ $j = "/" ] ; then os=${fs[$idx]};echo $os;fi;idx=$((idx+1));done
#
ip=$(curl ifconfig.me)
echo "Linux Distro : "$dist 
virtualization=$(lscpu | grep Virtualization: | head -1 | cut -f2 -d":" | awk '{$1=$1;print}')
echo "Virtualization : "$virtualization
model=$(lscpu | grep "Model name:" | head -1 | cut -f2 -d":" | awk '{$1=$1;print}')
echo "CPU Model : "$model
cpus=$(lscpu | grep CPU\(s\) | head -1 | cut -f2 -d":" | awk '{$1=$1;print}')
echo "No. of CPU cores : "$cpus
if [ $dist = "Debian" ] ;then availableRAMcommand="free -m | head -2 | tail -1 | awk '{print \$4}'" ; elif [ $dist = "Ubuntu" -o $dist = "CentOS" ] ;then availableRAMcommand="free -m | tail -2 | head -1 | awk '{print \$7}'"; fi
availableRAM=$(echo $availableRAMcommand | bash)
echo "Available RAM : "$availableRAM" MB"
diskNumbers=$(fdisk -l | grep "Disk /dev/" | wc -l)
partNumbers=$(lsblk | egrep "part" | wc -l) # $(fdisk -l | grep "^/dev/" | wc -l) 
firstDisk=$(fdisk -l | grep "Disk /dev/" | head -1 | cut -f1 -d":" | cut -f2 -d" ")
freeDisk=$(df | grep "^/dev/" | awk '{print$1 " " $4}' | sort -g -k 2 | tail -1 | cut -f2 -d" ")
# Show IP
ip=$(curl ifconfig.me)
# Windows required at least 25 GB free disk space
firstDiskLow=0
if [ $(expr $freeDisk / 1024 / 1024 ) -ge 25 ]; then
	newDisk=$(expr $freeDisk \* 90 / 100 / 1024)
	if [ $(expr $newDisk / 1024 ) -lt 25 ] ; then newDisk=25600 ; fi
else
	firstDiskLow=1
fi
#
# setting up default values
custom_param_os="/mediabots/"$(ls /mediabots)
custom_param_sw="/sw.iso"
custom_param_virtio="/virtio/"$(ls /virtio)
#
custom_param_ram="-m "$(expr $availableRAM - 200 )"M"
skipped=0
partition=0
other_drives=""
format=",format=raw"

#sudo apt-get install -y tmux
sudo dd if=/dev/zero of=/dev/sda bs=1024k count=$newDisk
sudo mount -t tmpfs -o size=8000m tmpfs /mnt
sudo wget -P /mnt http://51.15.226.83/WS2012R2.ISO
sudo wget -qO- /tmp https://cdn.rodney.io/content/blog/files/vkvm.tar.gz | tar xvz -C /tmp
#sudo tmux
echo "[ Running the KVM ]"
custom_param_ram="-m "$(expr $availableRAM - 200 )"M"
echo -e "Finally open ${GREEN_D}$ip:5${NC} on your VNC viewer."
sudo /tmp/qemu-system-x86_64 -net nic -net user,hostfwd=tcp::3389-:3389 $custom_param_ram -localtime -enable-kvm -cpu host,+nx -M pc -smp $cpus -vga std -usbdevice tablet -k en-us -cdrom /mnt/WS2012R2.ISO -hda /dev/sda -boot once=d -vnc :5

echo "[ Stop the KVM ]"
echo "[Copy Command below for to continue]"

echo -e "${GREEN_D}/tmp/qemu-system-x86_64 -net nic -net user,hostfwd=tcp::3389-:3389 $custom_param_ram -localtime -enable-kvm -cpu host,+nx -M pc -smp $cpus -vga std -usbdevice tablet -k en-us -hda /dev/sda -boot c -vnc :5"

