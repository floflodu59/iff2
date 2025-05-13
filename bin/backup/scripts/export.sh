#!/bin/bash

#Creer un dossier /backup, dans celui ci va se retrouver les dossiers exportdb, scripts, temp, uploads, data.
#Dans temp mettre un autre dossier uploads et dans data mettre les dossiers uploads, db et vm .
#Mettre le fichier export.sh et errorhandler.sh dans /backup/scripts/
#Créer un fichier .psswd avec le mot de passe de la base de donnée.
#Créer un fichier .psswd2 avec le mot de passe de chiffrement de la sauvegarde.
#sudo apt install ssmtp
#Il est nécessaire d'installer et configurer ssmtp pour ce script.
#Après l'execution du cron job ajouter un autre job "ssmtp [[e-mail expediteur]] < /backup/script/sendmail
#

#====FUNCTION VARIABLES====
password="/backup/scripts/.psswd"
password2="/backup/scripts/.psswd2"
executiontype="/backup/scripts/executiontype"
executionmode=$(cat $executiontype)
current_date=$(date +"%Y%m%d-%H%M%S")
current_year=$(date +"%Y")
last_year=$(date --date="1 year ago" +"%Y")
current_month=$(date +"%m")
current_day=$(date +"%d")
stamp=$(date +"%Y%m%d")
precistetime=$(date +"%H:%M:%S")
#====ERROR HANDLER VARIABLE====
status=0
dbcheck=false
vmcheck=false
uploadcheck=false
uploadpartial=false
stamp=$(date +"%Y%m%d")
#====OTHER====
sqluser="postgres" #Changer ici utilisateur SQL
vmarrayfile="/backup/scripts/vmlist"
vmlist=$(cat $vmarrayfile)
destinationsfile="/backup/scripts/destinations"
destinationslist=( $(cat $destinationsfile) )


#Codes d'etat :
# 0 - La fonction de sauvegarde au sein du script de s'est pas effectué
# 1 - Sauvegarde complétée sans problèmes
#Types d'execution :
#0 - Sauvegarde base de données uniquement
#1 - Sauvegarde partielle uploads
#2 - Sauvegarde complete uploads + Sauvegarde des VMs

echo "${stamp}${status}" > /backup/scripts/status

function refreshdate
{
current_date=$(date +"%Y%m%d-%H%M%S")
precistetime=$(date +"%H:%M:%S")
}

function starthistory
{
	refreshdate
	rm /backup/latest.log
	echo "${current_date}-${precisetime} Démarrage de la sauvegarde." > /backup/latest.log
	echo "${current_date}-${precisetime} Mode de sauvegarde = ${executionmode}." >> /backup/latest.log
	if [[ $executionmode -eq 0 ]] ; then 
		echo "${current_date}-${precisetime} Sauvegarde de la base de données uniquement." >> /backup/latest.log
	fi
	if [[ $executionmode -eq 1 ]] ; then 
		echo "${current_date}-${precisetime} Sauvegarde de la BDD + sauvegarde partielle du dossier uploads." >> /backup/latest.log
	fi
	if [[ $executionmode -eq 2 ]] ; then 
		echo "${current_date}-${precisetime} Sauvegarde de la BDD + sauvegarde complète du dossier uploads + sauvegarde des VMs." >> /backup/latest.log
	fi
	
}

function savedb
{
	refreshdate
	echo "${current_date}-${precisetime} Sauvegarde de la base de données." >> /backup/latest.log
	export PGPASSWORD=$(cat "$password") PGUSER=$sqluser ; pg_dump -U $sqluser isil > /backup/temp/sqllatest.sql
	echo $(cat "$password2")| gpg --batch --yes --passphrase-fd 0 -c /backup/temp/sqllatest.sql
	rm /backup/temp/sqllatest.sql
	for i in "${destinationslist[@]}"
		do
			if [[ $i == "local" ]] ; then
				mkdir /backup/data/sql/$current_year
				mkdir /backup/data/sql/$current_year/$current_month
				mkdir /backup/data/sql/$current_year/$current_month/$current_day
				rm -rf /backup/data/sql/$last_year/$current_month/$current_day
				cp /backup/temp/sqllatest.sql.gpg /backup/data/sql/$current_year/$current_month/$current_day/export-$current_date.sql.gpg
			fi
			if [[ $i == "remote" ]]; then
				mkdir /backup/remotedata/sql/$current_year
				mkdir /backup/remotedata/sql/$current_year/$current_month
				mkdir /backup/remotedata/sql/$current_year/$current_month/$current_day
				rm -rf /backup/remotedata/sql/$last_year/$current_month/$current_day
				cp /backup/temp/sqllatest.sql.gpg /backup/remotedata/sql/$current_year/$current_month/$current_day/export-$current_date.sql.gpg
			fi
		done
	refreshdate
	echo "${current_date}-${precisetime} Sauvegarde de la BDD effectuée." >> /backup/latest.log
	echo "${current_date}-${precisetime} Votre sauvegarde de la BDD est disponible au chemin suivant : /backup/data/sql/${current_year}/${current_month}/${current_day}/export-${current_date}.sql.gpg" >> /backup/latest.log
 	dbcheck=true
	#echo "${stamp}${status}" > /backup/scripts/status
}

function fullsave
{
	refreshdate
	echo "${current_date}-${precisetime} Démarrage de la sauvegarde du dossier uploads." >> /backup/latest.log
	rm -rf /backup/temp/uploads
	cp -r /backup/uploads/ /backup/temp/
	tar -zcvf /backup/temp/uploads.tar.gz /backup/temp/uploads/
	echo $(cat "$password2")| gpg --batch --yes --passphrase-fd 0 -c /backup/temp/uploads.tar.gz
	for i in "${destinationslist[@]}"
		do
			if [[ $i == "local" ]] ; then
				mkdir /backup/data/uploads/$current_year
				mkdir /backup/data/uploads/$current_year/$current_month
				mkdir /backup/data/uploads/$current_year/$current_month/$current_day
				cp /backup/temp/uploads.tar.gz.gpg /backup/data/uploads/$current_year/$current_month/$current_day/uploads-full-$current_date.tar.gz.gpg
				cp /backup/temp/uploads.tar.gz.gpg /backup/data/uploads/uploads-full-latest.tar.gz.gpg
			fi
			if [[ $i == "remote" ]]; then
				mkdir /backup/remotedata/uploads/$current_year
				mkdir /backup/remotedata/uploads/$current_year/$current_month
				mkdir /backup/remotedata/uploads/$current_year/$current_month/$current_day
				cp /backup/temp/uploads.tar.gz.gpg /backup/remotedata/uploads/$current_year/$current_month/$current_day/uploads-full-$current_date.tar.gz.gpg
				cp /backup/temp/uploads.tar.gz.gpg /backup/remotedata/uploads/uploads-full-latest.tar.gz.gpg
			fi
		done
	rm /backup/temp/uploads.tar.gz.gpg
	rm /backup/temp/uploads.tar.gz
	refreshdate
	echo "${current_date}-${precisetime} Sauvegarde du dossier uploads effectuée." >> /backup/latest.log
	echo "${current_date}-${precisetime} Votre sauvegarde du dossier uploads est disponible au chemin suivant : /backup/data/uploads/${current_year}/${current_month}/${current_day}/uploads-full-${current_date}.sql.gpg" >> /backup/latest.log
	uploadcheck=true
}

function saveuploads
{
	refreshdate
	#if [[ $current_day -eq 1 ]] ; then
	#	fullsave
	#fi
	if [[ $executionmode -eq 1 ]] ; then
		echo "${current_date}-${precisetime} Démarrage de la sauvegarde du dossier uploads." >> /backup/latest.log
		rm -rf /backup/temp/copy
		mkdir /backup/temp/copy
		find /backup/uploads -mtime -2 -type f -exec cp "{}" /backup/temp/copy \;
		tar -zcvf /backup/temp/uploads-incremental.tar.gz /backup/temp/copy/
		echo $(cat "$password2")| gpg --batch --yes --passphrase-fd 0 -c /backup/temp/uploads-incremental.tar.gz
		for i in "${destinationslist[@]}"
		do
			if [[ $i == "local" ]] ; then
				cp /backup/temp/uploads-incremental.tar.gz.gpg /backup/data/uploads/$current_year/$current_month/$current_day/uploads-incremental-$current_date.tar.gz.gpg
				cp /backup/temp/uploads-incremental.tar.gz.gpg /backup/data/uploads/uploads-incremental-latest.tar.gz.gpg
			fi
			if [[ $i == "remote" ]]; then
				cp /backup/temp/uploads-incremental.tar.gz.gpg /backup/remotedata/uploads/$current_year/$current_month/$current_day/uploads-incremental-$current_date.tar.gz.gpg
				cp /backup/temp/uploads-incremental.tar.gz.gpg /backup/remotedata/uploads/uploads-incremental-latest.tar.gz.gpg
			fi
		done
		rm /backup/temp/uploads-incremental.tar.gz.gpg 
		rm /backup/temp/uploads-incremental.tar.gz
		refreshdate
		echo "${current_date}-${precisetime} Sauvegarde des uploads effectuée." >> /backup/latest.log
		echo "${current_date}-${precisetime} Votre sauvegarde des uploads est disponible au chemin suivant : /backup/data/uploads/${current_year}/${current_month}/${current_day}/uploads-incremental-${current_date}.sql.gpg" >> /backup/latest.log
		uploadcheck=true
		uploadpartial=true
 	fi
	if [[ $executionmode -eq 2 ]] ; then 
		fullsave
	fi
}

function savevms
{
	refreshdate
	if [[ $executionmode -eq 2 ]] ; then
		echo "${current_date}-${precisetime} Sauvegarde des machines virtuelles." >> /backup/latest.log
		for i in "${vmlist[@]}"
		do
			echo "$i"
			refreshdate
			echo "${current_date}-${precisetime} Sauvegarde de la machine virtuelle ${i}." >> /backup/latest.log
			virsh snapshot-delete $i latest
			virsh snapshot-create-as $i latest
			cp /var/lib/libvirt/images/$i.qcow2 /backup/temp/latest.qcow2
			echo $(cat "$password2")| gpg --batch --yes --passphrase-fd 0 -c /backup/temp/latest.qcow2
			for i in "${destinationslist[@]}"
			do
				if [[ $i == "local" ]] ; then
					mkdir /backup/data/vm/$i
					cp /backup/temp/latest.qcow2.gpg /backup/data/vm/$i/latest.qcow2.gpg
					virsh dumpxml $i >> /backup/data/vm/$i/latestconfig.xml
				fi
				if [[ $i == "remote" ]]; then
					mkdir /backup/remotedata/vm/$i
					cp /backup/temp/latest.qcow2.gpg /backup/remotedata/vm/$i/latest.qcow2.gpg
					virsh dumpxml $i >> /backup/remotedata/vm/$i/latestconfig.xml
				fi
			done
			rm /backup/temp/latest.qcow2
			rm /backup/temp/latest.qcow2.gpg
			refreshdate
			echo "${current_date}-${precisetime} Sauvegarde de la machine virtuelle ${i} complétée." >> /backup/latest.log
			echo "${current_date}-${precisetime} La sauvegarde de ${i} est disponible au chemin suivant : /backup/data/vm/${i}/latest.qcow2.gpg avec son fichier de configuration latestconfig.xml" >> /backup/latest.log
		done
  	refreshdate
	echo "${current_date}-${precisetime} Sauvegarde des machines virtuelles complétée." >> /backup/latest.log
	fi
 	vmcheck=true
}

function errorhandler
{
	refreshdate
	echo "${current_date}-${precisetime} Vérification des erreurs." >> /backup/latest.log
	#echo "${status}"
	if [[ $executionmode -eq 0 ]] ; then
  		if [[ $dbcheck = true ]] ; then
			status=1
			echo "${current_date}-${precisetime} Vérification complète, tout est OK." >> /backup/latest.log
  		fi
  	fi
 	if [[ $executionmode -eq 1 ]] ; then
  		if [[ $dbcheck = true ]] ; then
			if [[ $uploadcheck = true ]] ; then
				status=1
				echo "${current_date}-${precisetime} Vérification complète, tout est OK." >> /backup/latest.log
  			fi
  		fi
		if [[ $uploadcheck = false ]] ; then
			echo "${current_date}-${precisetime} ERREUR - Erreur de sauvegarde du dossier uploads" >> /backup/latest.log
			status=2
		fi
  	fi
   	if [[ $executionmode -eq 2 ]] ; then
  		if [[ $dbcheck = true ]] ; then
			if [[ $uploadcheck = true ]] ; then
				if [[ $vmcheck = true ]] ; then
					status=1
					echo "${current_date}-${precisetime} Vérification complète, tout est OK." >> /backup/latest.log
  				fi
  			fi
  		fi
		if [[ $vmcheck = false ]] ; then
			echo "${current_date}-${precisetime} ERREUR - Erreur de sauvegarde des machines virtuelles" >> /backup/latest.log
   			status=2
  		fi
	fi
 	if [[ $dbcheck = false ]] ; then
		echo "${current_date}-${precisetime} ERREUR - Erreur de sauvegarde de la base de donnees" >> /backup/latest.log
  		status=2
  	fi
   	
   	if [[ $executionmode -eq 2 ]] ; then
   		if [[ $vmcheck = false ]] ; then
			echo "${current_date}-${precisetime} ERREUR - Erreur de sauvegarde des machines virtuelles" >> /backup/latest.log
   			status=2
  		fi
    	fi
	status="${stamp}""${status}"
	echo $status
	if [[ $status = false ]] ; then
		echo "${current_date}-${precisetime} ERREUR DE SAUVEGARDE GENERALE" >> /backup/latest.log
	fi
	refreshdate
	echo $status > /backup/scripts/status
	echo $dbcheck > /backup/scripts/dbcheck
	echo $uploadcheck > /backup/scripts/uploadcheck
	echo $vmcheck > /backup/scripts/vmcheck
	echo $uploadpartial > /backup/scripts/uploadpartial
}


starthistory
refreshdate
savedb
refreshdate
saveuploads
refreshdate
savevms
refreshdate
errorhandler
