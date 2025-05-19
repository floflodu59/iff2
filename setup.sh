#!/bin/bash
# IFF - Script de configuration hôte
# Todo :
# --Outils pour cas spéciaux (changement IP, configuration sauvegarde)
# --Maj auto du script de sauvegarde
# --Log d'installation
echo "INSTALLATION DE DIALOG"
echo "======================"
apt-get update
apt-get install dialog
mkdir /srv/iff/tmp
dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "Ce programme permet d'installer les outils de virtualisation pour les déploiments ISIL.\n\nMerci de bien suivre la documentation associée afin de pouvoir completer cette installation avec succès." 10 60
dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "Le programme va maintenant installer les prérequis." 6 60
apt-get install dos2unix ansible cockpit cockpit-pcp qemu qemu-kvm bridge-utils cpu-checker libvirt-clients libvirt-daemon postgresql cockpit-machines cloud-image-utils ssmtp nfs-kernel-server nfs-common -y
apt-get install -t jammy-backports cockpit
apt-get install -t noble-backports cockpit
mkdir /usr/local/share/cockpit
mkdir /usr/local/share/cockpit/cockpit-files
cp /srv/iff/bin/cockpit-files/* /usr/local/share/cockpit/cockpit-files/

function networkconfig {
	dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "Le programme va maintenant afficher les interfaces réseau de votre machine.\nMerci de bien vouloir noter le nom de celle qui doit être utilisée pour le serveur." 9 60
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
dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "Le programme va maintenant effectuer la configuration réseau." 6 60
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
dbpassword=""
exec 3>&1
dbcfg=$(dialog --ok-label "Continuer" \
		--title "CONFIGURATION BASE DE DONNÉES" \
		--form "Entrez la configuration de la base de données :" \
15 80 0 \
		"Mot de passe de la base de données :"	1 1	"$dbpassword" 		1 40 20 0 \
2>&1 1>&3)
exec 3>&-
IFS=$'\n'; dbcfgarray=($dbcfg); unset IFS;
dbpassword=${dbcfgarray[0]}
echo $dbpassword > /srv/iff/bin/backup/scripts/.psswd
echo "CONFIGURATION DE LA BASE DE DONNEES"
systemctl enable postgresql && systemctl start postgresql
sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/14/main/pg_hba.conf
systemctl restart postgresql
psql -U postgres -c "Alter USER postgres WITH PASSWORD '$dbpassword';"
psql -U postgres -c "create database isil;"
sed -i 's/local   all             postgres                                trust/local   all             postgres                                md5/g' /etc/postgresql/14/main/pg_hba.conf

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
		dos2unix /srv/iff/bin/isil.sh
		chmod u+x /srv/iff/bin/isil.sh
		/srv/iff/bin/isil.sh
	fi
	if [ $i -eq 2 ] ; then
		echo "Installation de la machine d'accès..."
		dos2unix /srv/iff/bin/access.sh
		chmod u+x /srv/iff/bin/access.sh
		/srv/iff/bin/access.sh
	fi
	if [ $i -eq 3 ] ; then
		echo "Mise en place de la sauvegarde..."
		echo $dbpassword > /srv/iff/bin/backup/scripts/.psswd
		dos2unix /srv/iff/bin/backup.sh
		chmod u+x /srv/iff/bin/backup.sh
		/srv/iff/bin/backup.sh
	fi
done
dialog --title "PROGRAMME D'INSTALLATION IFF" --msgbox "Installation terminée." 10 60