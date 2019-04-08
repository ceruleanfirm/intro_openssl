#!/bin/bash
# openssltools.sh

Efile() {
  [[ ! -f $1 ]] && echo "$1 not found"
} 

Sfile() {
      [[ ! -s $1 ]] && ls -hl $1 && echo "$1 : Empty file"
}

Pemck() {
  ! grep -Eq "BEGIN.*PRIVATE KEY" $1 && echo "$1 : not a private key"
}

Intck() {	   
	[[ $1 != +([0-9]) ]] && echo An integer is required ...
}

Crtck() {
	! grep -Eq "BEGIN CERT" $1 && echo "$1 : not a certificate"
}

Hashfun() {
  printf "\nHash function : \n"
  select h in \
    "md5" \
    "sha1" \
    "sha256" \
    "sha512" \
    "Quit"
  do
    case $REPLY in
      1) h="md5" 
        break ;;
      2) h="sha1"
        break ;;
      3) h="sha256"
        break ;;
      4) h="sha512"
        break ;;
      5|*) echo -e "\nBack to main menu ... Press Enter\n"
        return
        ;;
    esac
  done
}

Symmetriccipher() {
  printf "\nAlgorithms available : \n"
  select a in \
    "aes-256-cbc" \
    "des" \
    "3des" \
    "rc4" \
    "rc5 (openssl version >= 1.1.0x)" \
    "Quit"
  do
    case $REPLY in
      1) a="aes-256-cbc"
        break ;;
      2) a="des"
        break;;
      3) a="3des"
        break ;;
      4) a="rc4"
        break ;;
      5) a="rc5"
        break ;;
      6) echo -e "\nBack to main menu ... Press Enter\n"
        return 
        ;;
      *) echo -e "Algorithm not available ...\nPress Enter"
        ;;
    esac
  done
}

Genkeys() {
  read -p "Key name (Private key : <keyname>.pem) : " pk
  openssl genrsa -out $pk.pem 
  chmod 400 $pk.pem
  echo "Public key (<keyname>.pub)"
  openssl rsa -in $pk.pem -pubout -out $pk.pub
  file $pk.*
}

openssl version
echo
PS3="Choose : "
select c in \
  "Verify signature" \
  "Sign a file and generate file.sig" \
  "Encrypt a file (Symmetric encryption)" \
  "Decrypt a file (Symmetric encryption)" \
  "Hash a file" \
  "Create a key pair" \
  "Encrypt a file (Asymmetric encryption)" \
  "Decrypt a file (Asymmetric encryption)" \
  "Generate a self-signed x509 certificate and private key" \
  "Display x509 certificate" \
  "Generate client x509 certificate" \
  "Generate a random password" \
  "Quit"
do
  case $REPLY in
    1) echo -e "\n$c\n"
      read -p "Signature file : " sig
      Efile $sig && continue
      read -p "Public key : " pub
      Efile $pub && continue
      read -p "File to verify : " fic
      Efile $fic && continue
      for i in md5 sha1 sha256 sha512
      do
        echo -e "\nTrying with hash function $i ..."
        openssl dgst -$i -verify $pub -signature $sig $fic 
        [[ $? == 0 ]] && printf "(Hash algorithm : $i)\n" && break
      done
      continue
      ;;
    2) echo -e "\n$c\n"
      read -p "Private key : " pem
      Efile $pem && continue
      Pemck $pem && continue
      read -p "File to sign : " fic
      Efile $fic && continue
      sig=$fic.sig
      Hashfun
      openssl dgst -$h -sign $pem -out $sig $fic 2>/dev/null && \
      echo -e "\n`file $sig` signed with $pem ($h)\n\nPress Enter\n"
      ;;
     3) echo -e "\n$c\n"
      read -p "File to encrypt : " fic
      Efile $fic && continue
      Sfile $fic && continue
      echo "Password : "
      stty -echo
      read pswd
      stty echo
      Symmetriccipher
      [[ $a == "Quit" ]] && continue
      [[ $a == "3des" ]] && a="des3"
      echo "Cypher : $a"
      read -p "Return an ASCII file (base64) (Y/n) ? : " rep
      case $rep in
        [Nn]*) openssl $a -in $fic -out $fic.$a -k $pswd 2>/dev/null
	       [[ ! -f $fic.$a ]] && echo $a : algorithm not supported in this version. && continue 
	    ;;
            *) openssl $a -in $fic -out $fic.$a.b64 -k $pswd -a 2>/dev/null
               [[ ! -f $fic.$a.b64 ]] && echo $a : algorithm not supported in this version. && continue 
            ;;
      esac
      file $fic.$a*
      echo -e "\nPress Enter\n"
      ;;
     4) echo -e "\n$c\n"
      read -p "File to decrypt : " df
      Efile $df && continue
      Sfile $df && continue
      Symmetriccipher
      [[ $a == "Quit" ]] && continue
      [[ $a == "3des" ]] && a="des3"
      res=`expr "$df" : '.*b64'$`
      case $res in
        0) openssl $a -d -in $df 
	 ;;
	*) openssl $a -d -in $df -a 
	 ;;
      esac
      echo -e "\nPress Enter\n"
      ;;
     5) echo -e "\n$c\n"
      read -p "File : " f
      Efile $f && continue
      Sfile $f && continue
      echo "Algorithms available : "
      select h in \
        "md5" \
        "sha1" \
        "sha256" \
        "sha512" \
        "Back to main menu" 
      do
        case $REPLY in
          1) openssl md5 $f
          ;;
          2) openssl sha1 $f
          ;;
          3) openssl sha256 $f
          ;;
          4) openssl sha512 $f
          ;;
          0|5) echo -e "\nMain menu\nPress Enter"
             break
          ;;
        esac
      done
      ;;
     6) echo -e "\n$c\n"
      Genkeys
      ;;
     7) echo -e "\n$c\n"
      read -p "File to encrypt : " fe
      Efile $fe && continue
      Sfile $fe && continue
      read -p "Public key for encryption : " pubk
      Efile $pubk && continue
      openssl rsautl -encrypt -inkey $pubk -pubin -in $fe -out $fe.dat || {
			echo
			Sfile $fe.dat && echo "deleting $fe.dat ..." && rm $fe.dat
			echo -e "\n\tTo encrypt a large file, please use symmetric encryption."
			echo -e "\tYou can also generate a password,"
			echo -e "\tencrypt the large file in symmetric encryption with this password,"
			echo -e "\tthen encrypt the password file (pswd.txt) in asymmetric encryption."
			echo -e "\tAt least send the 2 crypted files to your interlocutor.\n"
			continue
		}
      file $fe.dat
      ;;
     8) echo -e "\n$c\n"
      read -p "File to decrypt : " ef
      Efile $ef && continue
      Sfile $ef && continue
      read -p "Private key to decrypt this file : " kpem
      Efile $kpem && continue
      Pemck $kpem && continue
      openssl rsautl -decrypt -inkey $kpem -in $ef
      ;;
     9) echo -e "\n$c\n"
      read -p "Expiration time (numbers of days) : " day
      Intck $day  && continue
      read -p "Certificate name <certif-name>.crt : " crt
      read -p "Private key name : " k
      openssl req -new -newkey rsa:4096 -days $day -nodes -x509 -keyout $k.pem -out $crt.crt
      echo
      cat $crt.crt 
      echo
      cat $k.pem
      echo
      file $crt.crt $k.pem
      echo
      ;;       
     10) echo -e "\n$c\n"
      read -p "x509 certificate : " cert
      Efile $cert && continue
      Crtck $cert && continue
      openssl x509 -in $cert -text
      ;;
     11) echo -e "\n$c\n"
      read -p "Generate key pair too (N/y) ? : " rep
      case $rep in
	[yY]*) Genkeys 
	       cpem=$pk.pem
	       cpub=$pk.pub
	    ;;
	    *) read -p "Client Private key : " cpem
	       Efile $cpem && continue
	       Pemck $cpem && continue
	       read -p "Client Public key : " cpub
	       Efile $cpub
	    ;; 
      esac	
      chmod 600 $cpem
      read -p "Client name : " ccrt
      read -p "Client certificate duration (number of days) : " cdays
      Intck $cdays && continue
      read -p "CA cert : " cacrt
      Efile $cacrt && continue
      Crtck $cacrt && continue
      read -p "CA private key : " capem	
      Efile $capem && continue
      Pemck $capem && continue	
      # certif request from client pem		
      openssl req -new -key $cpem -out $ccrt.csr
      # client certif generation from CA cert and sign with CA pem
      openssl x509 -req -days $cdays -CAcreateserial -CA $cacrt -CAkey $capem -in $ccrt.csr -out $ccrt.crt
      # Rq : Pour que notre CA soit capable de générer et signer des certif clients (administrer une PKI), il faut créer les fichiers index.txt et serial (.srl) dans l'arborescence.
      chmod 400 $cpem
      file $ccrt.crt
      ;;
     12) echo -e "\n$c\n"
      read -p "Number of caracters : " nb
      Intck $nb && continue
      openssl rand -base64 $nb > pswd.txt
      echo "New password in pswd.txt"
      cat pswd.txt
       ;;
      13|0) exit
       ;;
  esac 
done
exit 0
