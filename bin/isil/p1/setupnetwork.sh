echo "CONFIGURATION RESEAU EN COURS..."
echo "# This is an automatically generated network config file by the IFF project." > /etc/netplan/00-installer-config.yaml
echo "network:" >> /etc/netplan/00-installer-config.yaml
echo " ethernets:" >> /etc/netplan/00-installer-config.yaml
echo "  enp1s0:" >> /etc/netplan/00-installer-config.yaml
echo "   dhcp4: no" >> /etc/netplan/00-installer-config.yaml
echo "   addresses: [ip/mask]" >> /etc/netplan/00-installer-config.yaml
echo "   gateway4: ip" >> /etc/netplan/00-installer-config.yaml
echo "   nameservers:" >> /etc/netplan/00-installer-config.yaml
echo "    addresses:" >> /etc/netplan/00-installer-config.yaml
echo "    - 8.8.8.8" >> /etc/netplan/00-installer-config.yaml
echo "    - 1.1.1.1" >> /etc/netplan/00-installer-config.yaml
echo "    - ip" >> /etc/netplan/00-installer-config.yaml
echo " version: 2" >> /etc/netplan/00-installer-config.yaml
#echo " renderer: NetworkManager" >> /etc/netplan/00-installer-config.yaml
netplan apply
ssh-keygen -A
sytemctl restart ssh
