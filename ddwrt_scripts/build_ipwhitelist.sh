#!/bin/sh

[ -f "/tmp/whitelist_ip.tmp" ] && rm "/tmp/whitelist_ip.tmp"

while read ENTRY
do
    HOST=$(echo "$ENTRY")
    IP=$(nslookup $HOST| awk '/^Address / { print $3 }')
    echo "$IP" >> /tmp/whitelist_ip.tmp
done < /jffs/whitelist_hosts.txt

sort -u /tmp/whitelist_ip.tmp | grep "^\d+\.\d+\.\d+\.\d+$" -E > /tmp/whitelist_ip.txt