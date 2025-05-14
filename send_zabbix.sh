#!/bin/bash

SERVER="XXX.XXX.XXX.XXX"

read RAW_MSG

TIMESTAMP=$(echo $RAW_MSG | cut -d" " -f1 )
IP=$(echo $RAW_MSG | cut -d" " -f2 )
MAC=$(echo $RAW_MSG | grep -oE '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})')
PROG=$(echo $RAW_MSG | grep -oE '[a-z,A-Z]{1,}[" "]?\[+[0-9]+[:.]{1}[0-9]+\]' )
MESSAGE=$(echo $RAW_MSG | sed s/^.*[0-9]\]\:\ \\+//g )

#echo  "$TIMESTAMP | $IP | $MAC | $PROG | $MESSAGE" >> /tmp/out


#FULL_MESSAGE="$TIMESTAMP | $IP | $MAC | $PROG | $MESSAGE"

FULL_MESSAGE_JSON=$(jq -n \
--arg timestamp "$TIMESTAMP" \
--arg ip "$IP" \
--arg mac "$MAC" \
--arg prog "$PROG" \
--arg message "$MESSAGE" \
'[{timestamp: $timestamp, ip: $ip, mac: $mac, prog: $prog, message: $message}]')

#DEBUG
#if [[ ! -e /tmp/out ]]; then
#	touch /tmp/out && chmod ugo+rw /tmp/out
#fi
#echo "$FULL_MESSAGE_JSON" >> /tmp/out

zabbix_sender -z "$SERVER" -s rsyslog -k FULL_MESSAGE_JSON -o "$FULL_MESSAGE_JSON"
