#!/bin/bash

#====VARIABLES====
current_date=$(date +"%Y%m%d-%H%M%S")
statusfile="/backup/scripts/status"
status=$(cat "$statusfile")
stamp=$(date +"%Y%m%d")
precistetime=$(date +"%H:%M:%S")
sender=""
recipients=""
site=""
sujet=""
dbcheck=$(cat /backup/scripts/dbcheck)
uploadscheck=$(cat /backup/scripts/uploadscheck)
uploadpartial=$(cat /backup/scripts/uploadpartial)
vmcheck=$(cat /backup/scripts/vmcheck)


#echo $status
#echo "${stamp}0"

#Codes d'etat :
# 0 - Les fonctions de sauvegarde au sein du script de s'est pas effectue.
# 1 - Sauvegarde complétée sans problèmes.
# 2 - Un ou plusieurs composants ne se sont pas executes.
# 5 - Defailliance générale du script.

function endhistory
{
	echo "${current_date}-$(precistetime) - Fin de la sauvegarde." >> /backup/latest.log
	cat /backup/latest.log >> /backup/history.log
}

function sendmail
{

    echo "To: ${recipients}" >> /backup/scripts/sendmail
    echo "From: ${sender}" >> /backup/scripts/sendmail
    
	if [ $status -eq "${stamp}0" ] ; then
		echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonjour," >> /backup/scripts/sendmail
		echo "La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie correctement." >> /backup/scripts/sendmail #Changer ici au besoin
    fi
    if [ $status -eq "${stamp}1" ] ; then
		echo "Subject: [${sujet}][${site}] SUCCES - La sauvegarde des donnees ISIL s'est effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonjour," >> /backup/scripts/sendmail
		echo "La sauvegarde du serveur ISIL du site ${site} s'est effectuee correctement." >> /backup/scripts/sendmail #Changer ici au besoin
    fi
	if [ $status -eq "${stamp}2" ] ; then
		echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee correctement." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonjour," >> /backup/scripts/sendmail
		echo "La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie correctement en raison d'un ou plusieurs des composants de sauvegarde qui ne se sont pas execute correctement." >> /backup/scripts/sendmail
    fi
	if [ $status = "${stamp}5" ] ; then
        echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
        echo "Bonjour," >> /backup/scripts/sendmail
        echo "La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie. Le script de sauvegarde ne s'est pas execute." >> /backup/scripts/sendmail #Changer ici au besoin 
    fi
	echo "" >> /backup/scripts/sendmail
	echo "Voici le récapitulatif de la sauvegarde :" >> /backup/scripts/sendmail
	if [ $dbcheck = true ] ; then
		echo "- Sauvegarde de la base de données OK" >> /backup/scripts/sendmail
	fi
	if [ $dbcheck = false ] ; then
		echo "- Sauvegarde de la base de données HS" >> /backup/scripts/sendmail
	fi
	if [ $uploadscheck = true ] ; then
		echo "- Sauvegarde du dossier uploads OK" >> /backup/scripts/sendmail
	fi
	if [ $uploadscheck = false ] ; then
		echo "- Sauvegarde du dossier uploads HS" >> /backup/scripts/sendmail
	fi
	if [ $uploadpartial = false ] ; then
		echo "- Dossier uploads sauvegardé partiellement." >> /backup/scripts/sendmail
	fi
	if [ $vmcheck = true ] ; then
		echo "- Sauvegarde des machines virtuelles OK" >> /backup/scripts/sendmail
	fi
	if [ $vmcheck = false ] ; then
		echo "- Sauvegarde des machines virtuelles HS" >> /backup/scripts/sendmail
	fi
	echo "Bonne journee," >> /backup/scripts/sendmail
    echo "SFF 1.0" >> /backup/scripts/sendmail
    /usr/sbin/ssmtp $sender < /backup/scripts/sendmail
    #rm /backup/scripts/sendmail
    echo "${current_date} - Envoi du mail effectue." >> /backup/latest.log
}


function errorhandler
{
	if [ "$status" = "${stamp}0" ] ; then
		echo "${current_date}-$(precistetime) - [ERREUR] Erreur dans l'execution du script de sauvegarde." >> /backup/latest.log
	fi
	if [ "$status" = "${stamp}1" ] ; then
                echo "${current_date}-$(precistetime) - Confirmation de la bonne execution du script de sauvegarde." >> /backup/latest.log
        fi
	if [ "$status" = "${stamp}5" ] ; then
                echo "${current_date}-$(precistetime) - [ERREUR] NON EXECUTION DU SCRIPT DE SAUVEGARDE." >> /backup/latest.log
        	sendmail
	fi
	echo "${stamp}5" > /backup/scripts/status
}

errorhandler
sendmail
endhistory
