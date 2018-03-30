#!/bin/sh
export PATH='/bin:/usr/bin:/sbin:/usr/sbin:/jffs/sbin:/jffs/bin:/jffs/usr/sbin:/jffs/usr/bin:/mmc/sbin:/mmc/bin:/mmc/usr/sbin:/mmc/usr/bin:/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin'
export LD_LIBRARY_PATH='/lib:/usr/lib:/jffs/lib:/jffs/usr/lib:/jffs/usr/local/lib:/mmc/lib:/mmc/usr/lib:/opt/lib:/opt/usr/lib'

REF=$(/opt/usr/sbin/ipset list IPBLACKLIST -t|grep References|cut -f2 -d " ")

if [ -z "$REF" ] || [ $(($REF)) -eq 0 ]; then
  /jffs/ipset_setup.sh
fi
#/jffs/fix_services.sh
