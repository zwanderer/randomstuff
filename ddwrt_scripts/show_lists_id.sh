#!/bin/sh

for URL in "http://winhelp2002.mvps.org/hosts.txt" \
           "http://someonewhocares.org/hosts/zero/hosts" \
           "http://www.malwaredomainlist.com/hostslist/hosts.txt" \
           "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt" \
           "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext" \
           "https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts" \
           "https://raw.githubusercontent.com/lewisje/jansal/master/adblock/hosts" \
           "https://zeustracker.abuse.ch/blocklist.php?download=hostfile" \
           "https://hosts-file.net/ad_servers.txt" \
           "https://hosts-file.net/exp.txt" \
           "https://hosts-file.net/emd.txt" \
           "https://hosts-file.net/grm.txt" \
           "https://hosts-file.net/fsa.txt" \
           "https://hosts-file.net/hjk.txt" \
           "https://hosts-file.net/pha.txt" \
           "https://hosts-file.net/psh.txt" \
           "https://hosts-file.net/pup.txt" \
           "http://mirror1.malwaredomains.com/files/BOOT" \
           "http://malc0de.com/bl/BOOT" \
           "http://www.hostsfile.org/Downloads/hosts.txt"\
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level3.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level4.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/iblocklist_abuse_palevo.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/yoyo_adservers.ipset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_abusers_30d.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_abusers_1d.netset" \
           "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_webclient.netset" \
           "https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt" \
           "https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist" \
           "http://malc0de.com/bl/IP_Blacklist.txt" \
           "http://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt" \
           "http://cinsscore.com/list/ci-badguys.txt" \
           "https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt"; do
  UID_FILE="gen_host.`echo -n "$URL" | md5sum | cut -d " " -f 1`"
  echo $UID_FILE == $URL
done
