#!/bin/bash

mkdir /backup
cp -r /srv/iff/bin/backup/* /backup/
dos2unix /backup/scripts/export.sh
dos2unix /backup/scripts/errorhandler.sh
chmod u+x /backup/scripts/export.sh
chmod u+x /backup/scripts/errorhandler.sh
bckpassword=""
exec 3>&1
dbcfg=$(dialog --ok-label "Continuer" \
		--title "CONFIGURATION SAUVEGARDES" \
		--form "Entrez la configuration de la sauvegarde :" \
15 80 0 \
		"Clé de cryptage des sauvegardes :"	1 1	"$bckpassword" 		1 40 20 0 \
2>&1 1>&3)
exec 3>&-
IFS=$'\n'; dbcfgarray=($dbcfg); unset IFS;
bckpassword=${bckcfgarray[0]}
echo bckpassword > /backup/scripts/.psswd2
chown root:root /backup/scripts/.psswd
chown root:root /backup/scripts/.psswd2
chmod 700 /backup/scripts/.psswd
chmod 700 /backup/scripts/.psswd2
dialog --checklist "Choisissez les destinations de sauvegardes:" 10 40 3 \
        1 "Local" on \
        2 "NAS ou serveur de sauvegarde" off \
        3 "Cloud" off 2>/srv/iff/tmp/checklistbck
checklistfile="/srv/iff/tmp/checklistbck"
list=$(cat $checklistfile)
IFS=$' '; listarray=($list); unset IFS;
for i in "${listarray[@]}"
do
	if [ $i -eq 1 ] ; then
		echo "local" >> /backup/scripts/destinations
	fi
	if [ $i -eq 2 ] ; then
		echo "remote" >> /backup/scripts/destinations
		mkdir /backup/remotedata
		remoteip="192.168.1.110"
		remotedir="/var/www/html/"
		exec 3>&1
		remotecfg=$(dialog --ok-label "Continuer" \
			--title "CONFIGURATION SAUVEGARDES" \
			--form "Entrez la configuration de la sauvegarde :" \
		15 80 0 \
			"Addresse IP du NAS ou serveur distant :"	1 1	"$remoteip" 		1 40 40 0 \
			"Dossier du NAS ou serveur distant :"	2 1	"$remotedir" 		2 40 40 0 \
		2>&1 1>&3)
		exec 3>&-
		IFS=$'\n'; remotecfgarray=($remotecfg); unset IFS;
		remoteip=${remotecfgarray[0]}
		remotedir=${remotecfgarray[1]}
		echo "$remoteip":"$remotedir" "/backup/remotedata nfs defaults 0 0" >> /etc/fstab
	fi
	if [ $i -eq 3 ] ; then
		echo "cloud" >> /backup/scripts/destinations
	fi
done
sender="sauvegardes@example.com"
recipient="support@example.com"
sujet="CONTOSO"
site="PARIS"
exec 3>&1
bckcfg=$(dialog --ok-label "Continuer" \
	--title "CONFIGURATION SAUVEGARDES" \
	--form "Entrez la configuration de la sauvegarde :" \
20 80 0 \
	"Adresse mail de l'envoyeur :"	1 1	"$sender" 		1 40 40 0 \
	"Adresse mail du destinataire :"	2 1	"$recipient" 		2 40 40 0 \
	"Nom de l'entreprise :"	3 1	"$sujet" 		3 40 40 0 \
	"Nom du site :"	4 1	"$site" 		4 40 40 0 \
	"Utilisateur SMTP2GO :"	5 1	"$user" 		5 40 40 0 \
	"Mot de passe SMTP2GO :"	6 1	"$pwd" 		6 40 40 0 \
2>&1 1>&3)
exec 3>&-
IFS=$'\n'; bckarray=($bckcfg); unset IFS;
sender=${bckarray[0]}
recipient=${bckarray[1]}
sujet=${bckarray[2]}
site=${bckarray[3]}
user=${bckarray[4]}
pwd=${bckarray[5]}
sed -i 's/sender=""/sender="'$sender'"/g' /backup/scripts/errorhandler.sh
sed -i 's/recipients=""/recipients="'$recipient'"/g' /backup/scripts/errorhandler.sh
sed -i 's/site="IFF-01"/site="'$site'"/g' /backup/scripts/errorhandler.sh
sed -i 's/sujet="ISC"/sujet="'$sujet'"/g' /backup/scripts/errorhandler.sh
echo "mailhub=mail.smtp2go.com:2525" > /etc/ssmtp/ssmtp.conf
echo "AuthUser=$user" >> /etc/ssmtp/ssmtp.conf
echo "AuthPass=$pwd" >> /etc/ssmtp/ssmtp.conf
echo "UseSTARTTLS=YES" >> /etc/ssmtp/ssmtp.conf
echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf
echo "VMISIL" >> /backup/scripts/vmlist
mount -a
