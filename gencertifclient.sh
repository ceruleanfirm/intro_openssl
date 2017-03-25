#!/bin/bash
# gencertifclient.sh
# Le certif sera créé si le client est sur le réseau

[[ $# < 1 ]] && echo "Usage : $0 <nom client(s)>" && exit 1

read -p "Certificat racine (chemin absolu) : " cert
[[ -f $cert && -r $cert ]] || { 
	echo -e "$cert inaccessible ...\nFin du programme" 
	exit 2 
	}
file $cert
read -p "Clé privée (chemin absolu) : " cle
[[ -f $cle && -r $cle ]] || { 
	echo -e "$cle inaccessible ...\nFin du programme" 
	exit 2 
	}
file $cle
read -p "Clé publique (chemin absolu) : " pub
[[ -f $pub && -r $pub ]] || { 
	echo -e "$pub inaccessible ...\nFin du programme" 
	exit 2 
	}
echo -e "\nVeuillez vérifier qu'il s'agit bien de la clé PUBLIQUE du CA\n"
file $pub
sleep 2
echo
read -p "Durée de validité du certificat (nombre de jours) : " day
echo
while [[ "$#" -ge 1 ]] ; do
	ping -c2 $1 || {
		echo -e "\n$1 : host unreachable\n"
		sleep 2
		shift 
		continue
	}
	mkdir "$1" 2>/dev/null
	cd "$1"
	{
		echo -e "\n\tCRÉATION CERTIFICAT : $1\n"
		sleep 2 
	# création rsa priv du client
		openssl genrsa -out $1.pem 
		chmod 400 $1.pem   
	# dérivation rsa pub client
		openssl rsa -in $1.pem -pubout -out $1.pub 
	# requête certificat client émanant de sa priv
		openssl req -new -key $1.pem -out $1.csr 
	# création certif client dps le certif du CA 
	# et signature du certif client avec priv du CA
		openssl x509 -req -days $day -CAcreateserial -CA $cert \
	-CAkey $cle -in $1.csr -out $1.crt  # 
	}
	[[ $? = 0 ]] && echo -e "\n\tCERTIFICAT DE $1 CRÉÉ AVEC SUCCÈS\n" || \
	{
		echo -e "\nERREUR CRÉATION CERTIFICAT\n"
		cd ..
		rm -fr $1
		exit 11
	}
	sleep 2
	chmod 400 $1.crt
	read -p "Envoi sécurisé des données (certificat et clés) vers $1 (O/N) ? " rep
	case $rep in 
	   O|o) read -p "Port ssh : " port
	        ssh -p$port root@$1 "mkdir x509 2>/dev/null"
		scp -P$port $pub $1.crt $1.pem $1.pub root@$1:/root/x509/
		[[ $? = 0 ]] && echo -e "\nDonnées envoyées.\n" || \
		echo -e "\nEchec envoi ...\n"
		;;
	     *) echo -e "\nEnvoi annulé\n" 
		;;
	esac
	cd ..
	sleep 2
	shift
	
done

exit 0	
