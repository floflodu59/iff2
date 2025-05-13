#!/bin/bash

#====VARIABLES====
current_date=$(date +"%Y%m%d-%H%M%S")
statusfile="/backup/scripts/status"
status=$(cat "$statusfile")
stamp=$(date +"%Y%m%d")
precistetime=$(date +"%H:%M:%S")
sender=""
recipients=""
site="IFF-01"
sujet="ISC"
dbcheck=$(cat /backup/scripts/dbcheck)
uploadscheck=$(cat /backup/scripts/uploadcheck)
uploadpartial=$(cat /backup/scripts/uploadpartial)
vmcheck=$(cat /backup/scripts/vmcheck)


#echo $status
#echo "${stamp}0"

#Codes d'etat :
# 0 - Les fonctions de sauvegarde au sein du script de s'est pas effectue.
# 1 - Sauvegarde complétée sans problèmes.
# 2 - Un ou plusieurs composants ne se sont pas executes.
# 5 - Defailliance générale du script.

function refreshdate
{
current_date=$(date +"%Y%m%d-%H%M%S")
precistetime=$(date +"%H:%M:%S")
}

function endhistory
{
	refreshdate
	echo "${current_date}-${precisetime} - Fin de la sauvegarde." >> /backup/latest.log
	cat /backup/latest.log >> /backup/history.log
}

function insertheader
{
	echo "<style>" >>/backup/scripts/sendmail
	echo "p { margin: 0px; padding: 0px; }" >>/backup/scripts/sendmail
	echo "</style>" >>/backup/scripts/sendmail
}

function sendmail
{
	refreshdate
	rm /backup/scripts/sendmail
    echo "To: ${recipients}" >> /backup/scripts/sendmail
    echo "From: ${sender}" >> /backup/scripts/sendmail
	echo "MIME-Version: 1.0" >> /backup/scripts/sendmail
    echo "Content-Type: text/html; charset=utf-8" >> /backup/scripts/sendmail
	
	if [[ $status -eq "${stamp}0" ]] ; then
		echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
		insertheader
		echo "<p>Bonjour,</p>" >> /backup/scripts/sendmail
		echo "<p>La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie correctement.</p>" >> /backup/scripts/sendmail #Changer ici au besoin
    fi
    if [[ $status -eq "${stamp}1" ]] ; then
		echo "Subject: [${sujet}][${site}] SUCCES - La sauvegarde des donnees ISIL s'est effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
		insertheader
		echo "<p>Bonjour,</p>" >> /backup/scripts/sendmail
		echo "<p>La sauvegarde du serveur ISIL du site ${site} s'est effectuee correctement.</p>" >> /backup/scripts/sendmail #Changer ici au besoin
    fi
	if [[ $status -eq "${stamp}2" ]] ; then
		echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee correctement." >> /backup/scripts/sendmail #Changer ici au besoin
		insertheader
		echo "<p>Bonjour,</p>" >> /backup/scripts/sendmail
		echo "<p>La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie correctement en raison d'un ou plusieurs des composants de sauvegarde qui ne se sont pas execute correctement.</p>" >> /backup/scripts/sendmail
    fi
	if [[ $status = "${stamp}5" ]] ; then
       echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
       insertheader
       echo "<p>Bonjour,</p>" >> /backup/scripts/sendmail
       echo "<p>La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie. Le script de sauvegarde ne s'est pas execute.</p>" >> /backup/scripts/sendmail #Changer ici au besoin 
    fi
	echo "<p></p>" >> /backup/scripts/sendmail
	echo "<p>Voici le récapitulatif de la sauvegarde :</p>" >> /backup/scripts/sendmail
	if [[ $dbcheck = true ]] ; then
		echo "<p>- Sauvegarde de la base de données OK</p>" >> /backup/scripts/sendmail
	fi
	if [[ $dbcheck = false ]] ; then
		echo "<p>- Sauvegarde de la base de données HS</p>" >> /backup/scripts/sendmail
	fi
	if [[ $uploadscheck = true ]] ; then
		echo "<p>- Sauvegarde du dossier uploads OK</p>" >> /backup/scripts/sendmail
	fi
	if [[ $uploadscheck = false ]] ; then
		echo "<p>- Sauvegarde du dossier uploads HS</p>" >> /backup/scripts/sendmail
	fi
	if [[ $uploadpartial = true ]] ; then
		echo "<p>- Dossier uploads sauvegardé partiellement.</p>" >> /backup/scripts/sendmail
	fi
	if [[ $vmcheck = true ]] ; then
		echo "<p>- Sauvegarde des machines virtuelles OK</p>" >> /backup/scripts/sendmail
	fi
	if [[ $vmcheck = false ]] ; then
		echo "<p>- Sauvegarde des machines virtuelles HS</p>" >> /backup/scripts/sendmail
	fi
	echo "</br><small><small><small>" >> /backup/scripts/sendmail
	latestlog=$(cat /backup/latest.log)
	IFS=$'\n'; latestarray=($latestlog); unset IFS;
	
	for i in "${latestarray[@]}"
		do
		echo "$i"
		echo "<p>$i</p>" >> /backup/scripts/sendmail
	done
	echo "</br></small></small></small>" >> /backup/scripts/sendmail
	refreshdate
	echo "<p>Bonne journee,</p>" >> /backup/scripts/sendmail
    echo "<p>SFF 1.0</p>" >> /backup/scripts/sendmail
    /usr/sbin/ssmtp $recipients < /backup/scripts/sendmail
    #rm /backup/scripts/sendmail
    echo "${current_date} - Envoi du mail effectue." >> /backup/latest.log
}


function errorhandler
{
	refreshdate
	if [[ "$status" = "${stamp}0" ]] ; then
		echo "${current_date}-${precisetime} - [[ERREUR]] Erreur dans l'execution du script de sauvegarde." >> /backup/latest.log
	fi
	if [[ "$status" = "${stamp}1" ]] ; then
                echo "${current_date}-${precisetime} - Confirmation de la bonne execution du script de sauvegarde." >> /backup/latest.log
        fi
	if [[ "$status" = "${stamp}5" ]] ; then
                echo "${current_date}-${precisetime} - [[ERREUR]] NON EXECUTION DU SCRIPT DE SAUVEGARDE." >> /backup/latest.log
        	sendmail
	fi
	echo "${stamp}5" > /backup/scripts/status
}

refreshdate
errorhandler
refreshdate
sendmail
refreshdate
endhistory
