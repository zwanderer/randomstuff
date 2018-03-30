#!/bin/sh

WANNAME=$(nvram get wan_ifname)
LANNAME=$(nvram get lan_ifname)
PPPNAME=$(nvram get pppoe_ifname)
WANIP=$(nvram get wan_ipaddr)

if [ "$WANIP" = "0.0.0.0" ]; then
    exit
fi

if [ "$WANNAME" = "" ]; then
    WANNAME=$(get_wanface)
fi

echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/eth0/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/eth1/accept_source_route

echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/eth0/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/eth1/accept_redirects

echo 0 > /proc/sys/net/ipv4/conf/all/forwarding
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/forwarding
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/forwarding
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/forwarding
echo 0 > /proc/sys/net/ipv4/conf/eth0/forwarding
echo 0 > /proc/sys/net/ipv4/conf/eth1/forwarding

echo 0 > /proc/sys/net/ipv4/conf/all/mc_forwarding
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/mc_forwarding
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/mc_forwarding
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/mc_forwarding
echo 0 > /proc/sys/net/ipv4/conf/eth0/mc_forwarding
echo 0 > /proc/sys/net/ipv4/conf/eth1/mc_forwarding

echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
echo 1 > /proc/sys/net/ipv4/conf/$WANNAME/log_martians
echo 1 > /proc/sys/net/ipv4/conf/$LANNAME/log_martians
echo 1 > /proc/sys/net/ipv4/conf/$PPPNAME/log_martians
echo 1 > /proc/sys/net/ipv4/conf/eth0/log_martians
echo 1 > /proc/sys/net/ipv4/conf/eth1/log_martians

echo 10 > /proc/sys/net/ipv4/neigh/all/locktime
echo 10 > /proc/sys/net/ipv4/neigh/$WANNAME/locktime
echo 10 > /proc/sys/net/ipv4/neigh/$LANNAME/locktime
echo 10 > /proc/sys/net/ipv4/neigh/$PPPNAME/locktime
echo 10 > /proc/sys/net/ipv4/neigh/eth0/locktime
echo 10 > /proc/sys/net/ipv4/neigh/eth1/locktime

echo 0 > /proc/sys/net/ipv4/conf/all/proxy_arp
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/proxy_arp
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/proxy_arp
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/proxy_arp
echo 0 > /proc/sys/net/ipv4/conf/eth0/proxy_arp
echo 0 > /proc/sys/net/ipv4/conf/eth1/proxy_arp

echo 50 > /proc/sys/net/ipv4/neigh/all/gc_stale_time
echo 50 > /proc/sys/net/ipv4/neigh/$WANNAME/gc_stale_time
echo 50 > /proc/sys/net/ipv4/neigh/$LANNAME/gc_stale_time
echo 50 > /proc/sys/net/ipv4/neigh/$PPPNAME/gc_stale_time
echo 50 > /proc/sys/net/ipv4/neigh/eth0/gc_stale_time
echo 50 > /proc/sys/net/ipv4/neigh/eth1/gc_stale_time

echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/eth0/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/eth1/send_redirects

echo 0 > /proc/sys/net/ipv4/conf/all/secure_redirects
echo 0 > /proc/sys/net/ipv4/conf/$WANNAME/secure_redirects
echo 0 > /proc/sys/net/ipv4/conf/$LANNAME/secure_redirects
echo 0 > /proc/sys/net/ipv4/conf/$PPPNAME/secure_redirects
echo 0 > /proc/sys/net/ipv4/conf/eth0/secure_redirects
echo 0 > /proc/sys/net/ipv4/conf/eth1/secure_redirects

echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/$WANNAME/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/$LANNAME/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/$PPPNAME/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/eth0/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/eth1/rp_filter

echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 10 > /proc/sys/net/ipv4/ipfrag_time
echo 5 > /proc/sys/net/ipv4/icmp_ratelimit
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
echo 5 > /proc/sys/net/ipv4/igmp_max_memberships
echo 2 > /proc/sys/net/ipv4/igmp_max_msf
echo 1024 > /proc/sys/net/ipv4/tcp_max_orphans
echo 2 > /proc/sys/net/ipv4/tcp_syn_retries
echo 2 > /proc/sys/net/ipv4/tcp_synack_retries
echo 1 > /proc/sys/net/ipv4/tcp_abort_on_overflow
echo 10 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 0 > /proc/sys/net/ipv4/route/redirect_number
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
echo 61 > /proc/sys/net/ipv4/ip_default_ttl

echo 4096 87380 4194304 >/proc/sys/net/ipv4/tcp_rmem
echo 4096 87380 4194304 >/proc/sys/net/ipv4/tcp_wmem
echo 262144 > /proc/sys/net/core/rmem_max
echo 262144 > /proc/sys/net/core/wmem_max
echo 999999999 > /proc/sys/net/ipv4/tcp_challenge_ack_limit

echo 1000 > /proc/sys/net/core/netdev_max_backlog

echo 1 > /proc/sys/net/ipv4/tcp_ecn

echo 32768 61001 > /proc/sys/net/ipv4/ip_local_port_range

echo 32768 > /proc/sys/net/ipv4/netfilter/ip_conntrack_max
echo 16384 > /sys/module/nf_conntrack/parameters/hashsize

ifconfig eth0 txqueuelen 50
ifconfig eth1 txqueuelen 50
ifconfig $WANNAME txqueuelen 50
ifconfig $LANNAME txqueuelen 50
ifconfig $PPPNAME txqueuelen 50

# To be able to access modem webif when using PPPOE
iptables -t nat -I POSTROUTING -o $WANNAME -j MASQUERADE

#iptables -I INPUT 2 -p tcp -i wl0.1 -d $(nvram get lan_ipaddr) --dport 80 -j ACCEPT
#iptables -I INPUT 2 -p tcp -i wl0.1 -d $(nvram get lan_ipaddr) --dport 8118 -j ACCEPT

# Samba protocol SMB2
#if [ "$(grep -iE "^max protocol = SMB2$" "/tmp/smb.conf")" == "" ]; then
#  logger "firewall.sh 4"
#  sed "s/^\[global\]/\[global\]\nmax protocol = SMB2/" -i /tmp/smb.conf
#
#  stopservice samba3
#  sleep 1
#  startservice samba3
#fi

gpio disable 15

sleep 1

gpio enable 15

sleep 1

gpio disable 15

sleep 1

gpio enable 15

sleep 1

logger "firewall.sh loaded successfully..."

#nohup /jffs/fix_services.sh noforce 15&>/dev/null&