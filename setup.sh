#!/bin/bash
# IFF - Script de configuration hôte
# Todo :
# --Outils pour cas spéciaux (changement IP, configuration sauvegarde)
# --Reassignation VM sur disque différent
# --Maj auto du script de sauvegarde
# --Deploiment VM access
# --
echo "INSTALLATION DE DIALOG"
echo "======================"
apt-get update
apt-get install dialog
mkdir /srv/iff/tmp
dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "\nCe programme permet d'installer les outils de virtualisation pour les déploiments ISIL.\n\nMerci de bien suivre la documentation associée afin de pouvoir completer cette installation avec succès." 11 60
dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "\nLe programme va maintenant installer les prérequis." 7 60
apt-get install ansible cockpit cockpit-pcp qemu qemu-kvm bridge-utils cpu-checker libvirt-clients libvirt-daemon postgresql cockpit-machines cloud-image-utils ssmtp -y
function networkconfig {
	dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "\nLe programme va maintenant afficher les interfaces réseau de votre machine.\nMerci de bien vouloir noter le nom de celle qui doit être utilisée pour le serveur." 10 60
	ip a
	read -n 1 -s -r -p "Appuyez sur n'importe quelle touche pour continuer..."
	interface="eno1"
	ipaddress="192.168.1.100"
	gatewayaddress="192.168.1.1"
	masklength="24"
	exec 3>&1
	ipcfg=$(dialog --ok-label "Continuer" \
			--title "CONFIGURATION RESEAU" \
			--form "Entrez la configuration réseau de l'hôte :" \
	15 80 0 \
			"Nom de l interface ethernet utilisée :"	1 1	"$interface" 		1 40 20 0 \
			"Adresse IPv4 serveur :"   					2 1	"$ipaddress"  		2 40 20 0 \
			"Passerelle par défaut IPv4 :"   			3 1	"$gatewayaddress"  	3 40 20 0 \
			"Longueur Masque (1-32) :"					4 1	"$masklength" 		4 40 20 0 \
	2>&1 1>&3)
	exec 3>&-
	IFS=$'\n'; ipcfgarray=($ipcfg); unset IFS;

	dialog --title "CONFIGURATION RESEAU"  --yesno "Cette configuration est-elle correcte ?\n \nNom de l interface ethernet utilisée : ${ipcfgarray[0]}\nAdresse IPv4 serveur : ${ipcfgarray[1]}\nPasserelle par défaut IPv4 : ${ipcfgarray[2]}\nLongueur Masque (1-32) : ${ipcfgarray[3]}" 10 60
	status=$?

	interface=${ipcfgarray[0]}
	ipaddress=${ipcfgarray[1]}
	gatewayaddress=${ipcfgarray[2]}
	masklength=${ipcfgarray[3]}
}
networkconfig
if [ $status -eq 1 ] ; then
	networkconfig
fi
if [ $status -eq 255 ] ; then
	exit 255
fi

dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "\nLe programme va maintenant effectuer la configuration réseau." 7 60
echo "CONFIGURATION RESEAU EN COURS..."
rm -rf /etc/netplan/*
echo "# This is an automatically generated network config file by the IFF project." > /etc/netplan/00-installer-config.yaml
echo "network:" >> /etc/netplan/00-installer-config.yaml
echo " ethernets:" >> /etc/netplan/00-installer-config.yaml
echo "  $interface:" >> /etc/netplan/00-installer-config.yaml
echo "   dhcp4: no" >> /etc/netplan/00-installer-config.yaml
echo " bridges:" >> /etc/netplan/00-installer-config.yaml
echo "  br0:" >> /etc/netplan/00-installer-config.yaml
echo "   interfaces: [$interface]" >> /etc/netplan/00-installer-config.yaml
echo "   addresses: [$ipaddress/$masklength]" >> /etc/netplan/00-installer-config.yaml
echo "   gateway4: $gatewayaddress" >> /etc/netplan/00-installer-config.yaml
echo "   nameservers:" >> /etc/netplan/00-installer-config.yaml
echo "    addresses:" >> /etc/netplan/00-installer-config.yaml
echo "    - 8.8.8.8" >> /etc/netplan/00-installer-config.yaml
echo "    - 1.1.1.1" >> /etc/netplan/00-installer-config.yaml
echo "    - $gatewayaddress" >> /etc/netplan/00-installer-config.yaml
echo " version: 2" >> /etc/netplan/00-installer-config.yaml
netplan apply
echo "======================"
echo "GENERATION DE LA CLE SSH"
ssh-keygen -t rsa -f /home/isc/.ssh/id_rsa
echo "CONFIGURATION HOTE TERMINEE"
echo "======================"

dialog --checklist "Choisissez ce qu'il faut installer:" 10 40 3 \
        1 "Machine virtuelle ISIL" on \
        2 "Machine d'accès à distance" off \
        3 "Programme de sauvegardes" on 2>/srv/iff/tmp/checklist
checklistfile="/srv/iff/tmp/checklist"
list=$(cat $checklistfile)
IFS=$' '; listarray=($list); unset IFS;

for i in "${listarray[@]}"
do
	if [ $i -eq 1 ] ; then
		echo "Installation d'ISIL..."
	fi
	if [ $i -eq 2 ] ; then
		echo "Installation de la machine d'accès..."
	fi
	if [ $i -eq 3 ] ; then
		echo "Mise en place de la sauvegarde..."
	fi
done
