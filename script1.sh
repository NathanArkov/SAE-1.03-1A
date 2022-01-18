date=`date +"%d-%m-%y"`   #date du jour
userlist="userlist.txt"
date_hier=`date -d "1 day ago" +'%d-%m-%y'`   #date d'hier
date_sd=`date -d "1 week ago" +'%d-%m-%y'`   #date de la semaine dernière
date_md=`date -d "1 month ago" +'%d-%m-%y'`   #date du mois dernier

# on rempli la userlist a l'aide des repertoires présents dans home après l'avoir vidé
cat /dev/null > $userlist
ls ../../../../home >> $userlist

# on crée un dossier nommée avec la date du jour

if [ ! -d $date ]; then
    mkdir $date;
fi

# on crée un fichier "RAPPORT-STOCKAGE" pour chaque utilisateur

while IFS= read -r user
do
    if [ ! -f "$date/RAPPORT-STOCKAGE-$user" ]; then
        touch "$date/RAPPORT-STOCKAGE-$user";
    fi

# on récupère la taille du dossier de chaque user
    du -s /home/$user | cut -f1 >> "$date/RAPPORT-STOCKAGE-$user"
    
    while IFS= read -r ligne_hier
    do
        taille_hier=$ligne_hier
    done < "$date_hier/RAPPORT-STOCKAGE-$user"
    
    while IFS= read -r ligne_ajd
    do
        taille_ajd=$ligne_ajd
    done < "$date/RAPPORT-STOCKAGE-$user"
    
    while IFS= read -r ligne_sd
    do
        taille_sd=$ligne_sd
    done < "$date_sd/RAPPORT-STOCKAGE-$user"
    
    while IFS= read -r ligne_md
    do
        taille_md=$ligne_md
    done < "$date_md/RAPPORT-STOCKAGE-$user"
    
    delta_hier=$(($taille_ajd * 100 / $taille_hier - 100))
    delta_sd=$(($taille_ajd * 100 / $taille_sd - 100))
    delta_md=$(($taille_ajd * 100 / $taille_md - 100))
    
    if [ $delta_hier -gt 110 ]; then
        echo "Augmentation de $delta_hier % de l'espace disque utilisé entre $date_hier et $date. Voici les 10 plus gros fichiers de l'utilisateur $user :" >> "$date/INVENTAIRE-STOCKAGE-$user"
        echo -ne '\n' >> "$date/INVENTAIRE-STOCKAGE-$user"
        find /home/$user -user $user -printf "%s %p\n" | sort -rn | sed 's/^[0-9]* //' | awk 'NR<=10' >> "$date/INVENTAIRE-STOCKAGE-$user"
        
        echo -ne '\n' >> "$date/INVENTAIRE-STOCKAGE-$user"
        echo "Fichiers récents (< 24h) de l'utilisateur $user :" >> "$date/INVENTAIRE-STOCKAGE-$user"
        echo -ne '\n' >> "$date/INVENTAIRE-STOCKAGE-$user"
        find /home/$user -user $user -printf "%T@ %p\n" | sort -k 1nr | sed 's/^[^ ]* //' >> "$date/INVENTAIRE-STOCKAGE-$user"
    else
        echo "Analyse de l'espace disque effectuée. Augmentation de l'espace utilisé de $delta_hier %. Tout va bien !" >> "$date/INVENTAIRE-STOCKAGE-$user"
    fi
    
    
done < "$userlist"

#PARTIE PROCESSUS

while IFS= read user
do
    if [ ! -f "$date/PROCESS-$user" ]; then
        touch "$date/PROCESS-$user";
    fi
    
    ps -e -u "$user" -o "pid,etimes,command" | awk 'NR>2 {if($2>86400) print $1}' >> "$date/PROCESS-$user"
    
    while IFS= read process_48h
    do
        while IFS= read process
        do
            if [[ $process_48h -eq $process ]]; then
                echo "Le processus suivant tourne depuis plus de 48h, il a été arrêté : $process" >> "$date/RAPPORT-PROCESS-$user"
                kill $process
            fi
        done < "$date/PROCESS-$user"
    done < "$date_hier/PROCESS-$user"
    
done < "$userlist"



