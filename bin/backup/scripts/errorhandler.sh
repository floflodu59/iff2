#!/bin/bash

#====VARIABLES====
current_date=$(date +"%Y%m%d-%H%M%S")
statusfile="/backup/scripts/status"
status=$(cat "$statusfile")
stamp=$(date +"%Y%m%d")
sender=""
recipients=""
site=""
sujet=""

#echo $status
#echo "${stamp}0"

#Codes d'etat :
# 0 - Les fonctions de sauvegarde au sein du script de s'est pas effectue.
# 1 - Sauvegarde complétée sans problèmes.
# 2 - Un ou plusieurs composants ne se sont pas executes.
# 5 - Defailliance générale du script.

function sendmail
{

        echo "To: ${recipients}" >> /backup/scripts/sendmail
        echo "From: ${sender}" >> /backup/scripts/sendmail
        if [ "$status" = "${stamp}5" ] ; then
                echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
                echo "Bonjour," >> /backup/scripts/sendmail
                echo "La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie. Le script de sauvegarde ne s'est pas execute." >> /backup/scripts/sendmail #Changer ici au besoin
                echo "Bonne journee," >> /backup/scripts/sendmail
                echo "SFF 1.0" >> /backup/scripts/sendmail
        fi
	 if [ $status -eq "${stamp}0" ] ; then
		echo "Subject: [${sujet}][${site}] ECHEC - La sauvegarde des donnees ISIL ne s'est pas effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonjour," >> /backup/scripts/sendmail
		echo "La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie correctement." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonne journee," >> /backup/scripts/sendmail
		echo "SFF 1.0 - " >> /backup/scripts/sendmail
        fi
        if [ $status -eq "${stamp}1" ] ; then
		echo "Subject: [${sujet}][${site}] SUCCES - La sauvegarde des donnees ISIL s'est effectuee." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonjour," >> /backup/scripts/sendmail
		echo "La sauvegarde du serveur ISIL du site ${site} s'est effectuee correctement." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonne journee," >> /backup/scripts/sendmail
                echo "SFF 1.0" >> /backup/scripts/sendmail
        fi
	if [ $status -eq "${stamp}2" ] ; then
		echo "Subject: [${sujet}][${site}] SUCCES - La sauvegarde des donnees ISIL ne s'est pas effectuee correctement." >> /backup/scripts/sendmail #Changer ici au besoin
		echo "Bonjour," >> /backup/scripts/sendmail
		echo "La sauvegarde du serveur ISIL du site ${site} n'a pas aboutie correctement en raison d'un ou plusieurs des composants de sauvegarde qui ne se sont pas execute correctement." >> /backup/scripts/sendmail
		echo "Bonne journee," >> /backup/scripts/sendmail
                echo "SFF 1.0" >> /backup/scripts/sendmail
        fi
        /usr/sbin/ssmtp $sender < /backup/scripts/sendmail
        #rm /backup/scripts/sendmail
        echo "${current_date} - Envoi du mail effectue." >> /backup/history.log
}


function errorhandler
{
	if [ "$status" = "${stamp}0" ] ; then
		echo "${current_date} - [ERREUR] Erreur dans l'execution du script de sauvegarde." >> /backup/exportdb/history.log
	fi
	if [ "$status" = "${stamp}1" ] ; then
                echo "${current_date} - Confirmation de la bonne execution du script de sauvegarde." >> /backup/exportdb/history.log
        fi
	if [ "$status" = "${stamp}5" ] ; then
                echo "${current_date} - [ERREUR] NON EXECUTION DU SCRIPT DE SAUVEGARDE." >> /backup/exportdb/history.log
        	sendmail
	fi
	echo "${stamp}5" > /backup/scripts/status
}

errorhandler
sendmail
