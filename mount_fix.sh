sudo apt-get install nfs-common cifs-utils
sudo fdisk -l
read -p "Enter the disk name (e.g., /dev/sdb3): " diskname
sudo ntfsfix -d "$diskname"
