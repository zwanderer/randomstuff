#!/bin/sh

export PATH='/bin:/usr/bin:/sbin:/usr/sbin:/jffs/sbin:/jffs/bin:/jffs/usr/sbin:/jffs/usr/bin:/mmc/sbin:/mmc/bin:/mmc/usr/sbin:/mmc/usr/bin:/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin'
export LD_LIBRARY_PATH='/lib:/usr/lib:/jffs/lib:/jffs/usr/lib:/jffs/usr/local/lib:/mmc/lib:/mmc/usr/lib:/opt/lib:/opt/usr/lib'

sleep 5

lsmod | grep xt_set >/dev/null
if [ $? -ne 0 ]; then
  logger "ipset_setup: Loading IPSET kernel module..."
  insmod /opt/lib/modules/4.4.7/xt_set.ko
  sleep 1
fi

/opt/usr/sbin/ipset create -exist IPBLACKLIST hash:net hashsize 32768 maxelem 1048576
/opt/usr/sbin/ipset create -exist IPBLACKLIST_TMP hash:net hashsize 32768 maxelem 1048576
/opt/usr/sbin/ipset create -exist IPWHITELIST hash:net hashsize 1024 maxelem 65536
sleep 1

/opt/usr/sbin/iptables -nvL | grep LOG_BLACKLIST >/dev/null
if [ $? -ne 0 ]; then
  logger "ipset_setup: Creating firewall rules for logging IPs..."
  /opt/usr/sbin/iptables -N LOG_BLACKLIST
  /opt/usr/sbin/iptables -A LOG_BLACKLIST -o $(get_wanface) -m set --match-set IPWHITELIST dst -j ACCEPT
  /opt/usr/sbin/iptables -A LOG_BLACKLIST -j LOG --log-prefix 'BLACKLIST: ' --log-level 4
  /opt/usr/sbin/iptables -A LOG_BLACKLIST -j DROP
  sleep 1
fi

/opt/usr/sbin/iptables -nvL | grep IPBLACKLIST >/dev/null
if [ $? -ne 0 ]; then
  logger "ipset_setup: Creating firewall rules for blacklisting IPs..."
  /opt/usr/sbin/iptables -I INPUT 2 -i $(get_wanface) -m set --match-set IPBLACKLIST src -j LOG_BLACKLIST
  /opt/usr/sbin/iptables -I FORWARD 2 -i $(get_wanface) -m set --match-set IPBLACKLIST src -j LOG_BLACKLIST
  /opt/usr/sbin/iptables -I INPUT 2 -p tcp --syn -i $(get_wanface) -m set --match-set IPBLACKLIST src -j LOG_BLACKLIST
  /opt/usr/sbin/iptables -I FORWARD 2 -p tcp --syn -i $(get_wanface) -m set --match-set IPBLACKLIST src -j LOG_BLACKLIST
  /opt/usr/sbin/iptables -I OUTPUT 2 -o $(get_wanface) -m set --match-set IPBLACKLIST dst -j LOG_BLACKLIST
  /opt/usr/sbin/iptables -I FORWARD 2 -o $(get_wanface) -m set --match-set IPBLACKLIST dst -j LOG_BLACKLIST
  sleep 1
fi

/jffs/build_ipwhitelist.sh
if [ -f /tmp/whitelist_ip.txt ]; then
  logger "ipset_setup: Loading whitelisted IPs into set..."
  /opt/usr/sbin/ipset flush IPWHITELIST
  for IP in `cat /tmp/whitelist_ip.txt`; do
    /opt/usr/sbin/ipset add -exist IPWHITELIST $IP
  done
  sleep 1
fi

if [ -f /tmp/gen_ip.txt ]; then
  logger "ipset_setup: Loading blacklisted IPs into set..."
  /opt/usr/sbin/ipset flush IPBLACKLIST_TMP
  for IP in `cat /tmp/gen_ip.txt`; do
    /opt/usr/sbin/ipset add -exist IPBLACKLIST_TMP $IP
  done
  /opt/usr/sbin/ipset flush IPBLACKLIST
  /opt/usr/sbin/ipset swap IPBLACKLIST_TMP IPBLACKLIST
  sleep 1
fi

logger "ipset_setup: Done."
