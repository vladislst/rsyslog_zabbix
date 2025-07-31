#!/bin/bash

SERVER="127.0.0.1"
FILE_MAC_NUM="/opt/parse/mac-num"
FILE_LIST_CHANNEL="/opt/parse/channel"

read RAW_MSG

#DEBUG
if [[ ! -e /tmp/out ]]; then
        touch /tmp/out && chmod ugo+rw /tmp/out
fi
echo "$RAW_MSG" >> /tmp/out

TIMESTAMP=$(echo $RAW_MSG | cut -d" " -f1 )
IP=$(echo $RAW_MSG | cut -d" " -f2 )
MAC=$(echo $RAW_MSG | grep -oE '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})')
MAC_SED=$(echo $MAC | sed s/\:/\/g )
PROG=$(echo $RAW_MSG | grep -oE '[a-z,A-Z]{1,}[" "]?\[+[0-9]+[:.]{1}[0-9]+\]' )
MESSAGE=$(echo $RAW_MSG | sed s/^.*[0-9]\]\:\ \\+//g )
NUMBER=$(grep -m 1 -iw "${MAC_SED:-"null"}" ${FILE_MAC_NUM} | awk -F \; '{print $2}')

if echo $MESSAGE | grep -qE 'ObjId=CMI[0-9]*\/CDK[0-9]*\.(Port[0-9]*|Other-1|)';then

        PORT=$(echo $MESSAGE | grep -oE 'ObjId=CMI[0-9]*\/CDK[0-9]*\.(Port[0-9]*|Other-1|)')
        CHANNEL_TEXT=$(grep -w "${PORT}" ${FILE_LIST_CHANNEL} | awk -F \; '{print "Порт А:"$2" Порт Б:"$3}')
        RAW_DESC=$(echo $MESSAGE | grep -oE "Desc=.* ObjId=")
        DESC=${RAW_DESC:5:-6}

        CHANNEL_MESSAGE_JSON=$(jq -n \
        --arg timestamp "$TIMESTAMP" \
        --arg desc "$DESC" \
        --arg channel "$CHANNEL_TEXT" \
        --arg ip "$IP" \
        --arg message "$MESSAGE" \
        '[{timestamp: $timestamp, ip: $ip, desc: $desc, channel: $channel, message: $message}]')
        zabbix_sender -z "$SERVER" -s rsyslog -k FULL_MESSAGE_JSON -o "$CHANNEL_MESSAGE_JSON"
        exit 0
fi

FULL_MESSAGE_JSON=$(jq -n \
--arg timestamp "$TIMESTAMP" \
--arg ip "$IP" \
--arg mac "$MAC" \
--arg prog "$PROG" \
--arg message "$MESSAGE" \
--arg number "$NUMBER" \
'[{timestamp: $timestamp, ip: $ip, mac: $mac, prog: $prog, number: $number, message: $message}]')


zabbix_sender -z "$SERVER" -s rsyslog -k FULL_MESSAGE_JSON -o "$FULL_MESSAGE_JSON"