#!/bin/bash

dialog --title "INSTALLATION VM ISIL" --msgbox "Le programme va maintenant vous demander les informations de configuration réseau." 7 60

function networkconfig {
	interface="eno1"
	ipaddress="192.168.1.100"
	gatewayaddress="192.168.1.1"
	masklength="24"
	exec 3>&1
	ipcfg=$(dialog --ok-label "Continuer" \
			--title "CONFIGURATION RESEAU" \
			--form "Entrez la configuration réseau de la VM ISIL :" \
	15 80 0 \
			"Adresse IPv4 serveur :"   					1 1	"$ipaddress"  		1 40 20 0 \
			"Passerelle par défaut IPv4 :"   			2 1	"$gatewayaddress"  	2 40 20 0 \
			"Longueur Masque (1-32) :"					3 1	"$masklength" 		3 40 20 0 \
	2>&1 1>&3)
	exec 3>&-
	IFS=$'\n'; ipcfgarray=($ipcfg); unset IFS;

	dialog --title "CONFIGURATION RESEAU"  --yesno "Cette configuration est-elle correcte ?\n \nAdresse IPv4 serveur : ${ipcfgarray[0]}\nPasserelle par défaut IPv4 : ${ipcfgarray[1]}\nLongueur Masque (1-32) : ${ipcfgarray[2]}" 10 60
	status=$?

	ipaddress=${ipcfgarray[0]}
	gatewayaddress=${ipcfgarray[1]}
	masklength=${ipcfgarray[2]}
}
networkconfig
if [ $status -eq 1 ] ; then
	networkconfig
fi
if [ $status -eq 255 ] ; then
	exit 255
fi

function vmhardcconfig {
	passwd=""
	guestsize=200
	guestram=4096
	guestlocation="/var/lib/libvirt/images"
	exec 3>&1
	vmcfg=$(dialog --ok-label "Continuer" \
			--title "CONFIGURATION DE LINUX" \
			--form "Entrez la configuration réseau de la VM ISIL :" \
	15 100 0 \
			"Taille de la VM ISIL en Go :"	1 1	"$guestsize" 		1 45 50 0 \
			"Taille de la mémoire de la VM ISIL en Mo :"   					2 1	"$guestram"  		2 45 50 0 \
			"Mot de passe root de la machine virtuelle :"   			3 1	"$psswd"  	3 45 50 0 \
			"Emplacement de la VM ISIL :"   			4 1	"$guestlocation"  	4 45 50 0 \
	2>&1 1>&3)
	exec 3>&-
	IFS=$'\n'; vmcfgarray=($vmcfg); unset IFS;
	guestsize=${vmcfgarray[0]}
	guestram=${vmcfgarray[1]}
	guestpwd=${vmcfgarray[2]}
	guestlocation=${vmcfgarray[3]}
	dialog --title "CONFIGURATION RESEAU"  --yesno "Cette configuration est-elle correcte ?\n \nTaille de la VM ISIL en Go : ${vmcfgarray[0]}\nTaille de la mémoire de la VM ISIL en Mo : ${vmcfgarray[1]}\nMot de passe root de la machine virtuelle : ${vmcfgarray[2]}\nEmplacement de la VM ISIL : ${vmcfgarray[3]}" 10 60
	status=$?
}

vmhardcconfig
if [ $status -eq 1 ] ; then
	vmhardcconfig
fi
if [ $status -eq 255 ] ; then
	exit 255
fi
echo $guestlocation >> /srv/iff/bin/backup/scripts/vmsources
guestlocation=${guestlocation//\//\\/}
echo "CONFIGURATION RESEAU INVITE EN COURS..."
sed -i 's/pool_dir: "\/var\/lib\/libvirt\/images"/pool_dir: "'$guestlocation'"/g' /srv/iff/bin/isil/p1/kvm_provision.yaml
sed -i 's/ram_mb: 2048/ram_mb: '$guestram'/g' /srv/iff/bin/isil/p1/kvm_provision.yaml
echo 'echo "CONFIGURATION RESEAU EN COURS..."' > /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "# This is an automatically generated network config file by the IFF project." > /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "network:" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo " ethernets:" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "  enp1s0:" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "   dhcp4: no" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "   addresses: ['$ipaddress'/'$masklength']" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "   gateway4: '$gatewayaddress'" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "   nameservers:" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "    addresses:" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "    - 8.8.8.8" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "    - 1.1.1.1" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo "    - '$gatewayaddress'" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'echo " version: 2" >> /etc/netplan/00-installer-config.yaml' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'netplan apply' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'ssh-keygen -A' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'rm /etc/ssh/sshd_config.d/60-cloudimg-settings.conf' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'adduser isil' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'adduser isil sudo' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo 'shutdown -r' >> /srv/iff/bin/isil/p1/setupnetwork.sh
echo "---" > /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "# defaults file for kvm_provision" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "base_image_name: jammy-server-cloudimg-amd64.img" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "base_image_url: https://cloud-images.ubuntu.com/jammy/current/{{ base_image_name }}" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "base_image_sha: 0ba0fd632a90d981625d842abf18453d5bf3fd7bb64e6dd61809794c6749e18b" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo 'libvirt_pool_dir: "'$guestlocation'"' >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "vm_name: VMISIL" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "vm_vcpus: 2" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "vm_ram_mb: $guestram" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "vm_net: default" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "vm_size: "$guestsize"G" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "vm_root_pass: $guestpwd" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "cleanup_tmp: no" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "ssh_key: /root/.ssh/id_rsa.pub" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "# defaults file for kvm_provision" >> /srv/iff/bin/isil/p1/roles/kvm_provision/defaults/main.yml
echo "[myhosts]" > /srv/iff/bin/isil/p2/inventory.ini
echo "$ipaddress" >> /srv/iff/bin/isil/p2/inventory.ini
echo "[all:vars]" >> /srv/iff/bin/isil/p2/inventory.ini
echo "ansible_user=root" >> /srv/iff/bin/isil/p2/inventory.ini
echo "ansible_pass=$guestpwd" >> /srv/iff/bin/isil/p2/inventory.ini
echo "ansible_ssh_private_key_file =/home/isc/.ssh/id_rsa" >> /srv/iff/bin/isil/p2/inventory.ini
echo 'ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"' >> /srv/iff/bin/isil/p2/inventory.ini
echo "======================"
dialog --title "INSTALLATION VM ISIL" --msgbox "Le programme va maintenant creer la machine virtuelle." 7 60
echo "EXECUTION PHASE 1"
ansible-playbook /srv/iff/bin/isil/p1/kvm_provision.yaml
dialog --infobox "Merci de patienter le temps du redémarrage de la VM." 5 60 ; sleep 120
echo "EXECUTION PHASE 2"
ansible-playbook /srv/iff/bin/isil/p2/setupisil.yaml -i /srv/iff/bin/isil/p2/inventory.ini
