#!/bin/bash

#Actualizar el sistema
apt-get update && sudo apt-get upgrade -y

#Crear el usuario 
read -p "Nombre de usuario: " username
read -p "Password del usuario: " password

egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
        echo "$username ya existe!"
else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -m -p "$pass" "$username"
        [ $? -eq 0 ] && echo "Usuario añadido al sistema!" || echo "Error añadiendo creando el usuario!"
fi

usermod -aG sudo $username

#Instalar Dockers
curl -sSL https://get.docker.com | sh
usermod -aG docker $username

#Instalar Docker-Compose
apt-get install -y libffi-dev libssl-dev
apt install -y python3-dev
apt-get install -y python3 python3-pip

pip3 install docker-compose

systemctl enable docker

#Instalar GIT
apt install -y git

read -p "Usuario GIT: " gituser
read -p "Email GIT: " gitemail

git config --global user.name "$gituser"
git config --global user.email "$gitemail"

git clone https://github.com/ignacioborrajo/raspdockers.git

#Fijando la IP
read -p "Interfaz [wlan0, eth0]: " interfaz
read -p "IP Fija: " ipaddr
read -p "IP Router: " iprouter
sudo echo "interface $interfaz" >> /etc/dhcpcd.conf 
sudo echo "static ip_address=$ipaddr/24" >> /etc/dhcpcd.conf 
sudo echo "static routers=$iprouter" >> /etc/dhcpcd.conf 
sudo echo "static domain_name_servers=$iprouter 8.8.8.8" >> /etc/dhcpcd.conf

#Instal FTP
sudo apt install -y vsftpd
mv /etc/vsftpd.conf /etc/vsftpd.example.conf
touch /etc/vsftpd.conf
echo "listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
user_sub_token=\$USER
local_root=/" > /etc/vsftpd.conf
sudo service vsftpd restart

#Montar carpeta del NAS para hacer copias de seguridad
apt-get install -y cifs-utils
mkdir -p backup
read -p "IP del NAS: " nasip
read -p "Usuario: " nasuser
read -p "Contraseña: " naspass
sudo echo "//$nasip/home /home/$username/backup cifs defaults,rw,username=$nasuser,password=$naspass" >> /etc/fstab

echo "¿Quieres crear copias de seguridad de Home Assistant automáticamente?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) (crontab -l 2>/dev/null; echo "0 5 * * * tar -zcf /home/ignacio/backup/ha_config.tgz -C /data/compose/1/ config") | crontab -; break;;
        No ) exit;;
    esac
done

#Cambiar el password del usuario pi
passwd

sudo reboot