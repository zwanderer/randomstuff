#!/bin/sh

##################################################################################
##
## gen_hosts by IronManLok
##
##   Downloads domain entries of known abusers from multiple sources,
##   cleans up, merges and removes duplicates. Includes white-listing and
##   custom host entries. Also, it downloads and builds an IP blacklist
##   to be used as input for iptables drop rules.
##
##   INSTALLATION
##
##   This script is intended to be used on units running DD-WRT kongac with kernel
##   4.4+ and requires that it's stored on /jffs (it's recommended to mount an USB
##   drive on /jffs). You can always edit the script and replace references to
##   /jffs.
##
##   Also, you should be using DNSMasq as DNS server, and OPKG package manager
##   (required packages: ca_certificates, ipset, iptables).
##
##   OPKG installation example:
##      1) Run "mkdir /jffs/opt".
##      2) Add "mount -o bind /jffs/opt/ /opt" to your startup script.
##      3) Also run "mount -o bind /jffs/opt/ /opt" if you haven't rebooted yet.
##      3) Run "bootstrap".
##      4) Check by running "opkg --version".
##      5) Run "opkg update".
##      6) Run "opkg install ca-certificates".
##      7) Run "opkg install iptables".
##      8) Run "opkg install ipset".
##
##   On Services Tab, at Additional DNSMasq options, add this line:
##      addn-hosts=/tmp/gen_host.txt
##
##   On Administration Tab, enable Cron and add this job to make the script run
##   daily at 22:00. You can change the time as you wish:
##      0 22 * * * root /jffs/gen_host.sh
##
##   To make sure the script runs after boot or when wan is up, run the following
##   commands:
##     1) echo "#!/bin/sh" > /jffs/etc/config/gen_host.wanup
##     2) echo "/jffs/gen_host.sh" >> /jffs/etc/config/gen_host.wanup
##     3) echo "#!/bin/sh" > /jffs/etc/config/gen_host.ipup
##     4) echo "/jffs/gen_host.sh" >> /jffs/etc/config/gen_host.ipup
##
##   For white-listing, create /jffs/whitelist_hosts.txt and list one domain
##   per line. For custom hosts entries, create /jffs/my_hosts.txt and
##   add any lines in the same format of a regular hosts file.
##
##   This script is free for use, modification and redistribution as long as
##   appropriate credit is provided.
##
##   THIS SCRIPT IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT
##   ANY WARRANTY. IT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
##   EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
##   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS
##   TO THE QUALITY AND PERFORMANCE OF THE SCRIPT IS WITH YOU. SHOULD THE SCRIPT
##   PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
##   CORRECTION.
##
##################################################################################

wait_for_connection()
{
  while :; do
    ping -c 1 -w 10 www.google.com > /dev/null 2>&1 && break
    sleep 60
    logger "gen_host: Retrying internet connection..."
  done
}

CA_PATH=/opt/etc/ssl/certs

download_file()
{
  ATTEMPT=1
  OUTPUT_FILE="$2"
  HTTP_CODE="$2.http"

  while :; do
    if [ -f "$OUTPUT_FILE" ]; then
      rm "$OUTPUT_FILE"
    fi

    if [ -f "$HTTP_CODE" ]; then
      rm "$HTTP_CODE"
    fi

    # Skip URL after 3 failed attempts...
    if [ $ATTEMPT = 4 ]; then
      logger "gen_host: Skipping $1 ..."
      return 1
    fi

    logger "gen_host: Downloading $1 (attempt `echo $ATTEMPT`)..."
    (curl -o "$OUTPUT_FILE" --silent --write-out '%{http_code}' --connect-timeout 90 --max-time 150 --capath $CA_PATH -L "$1" > "$HTTP_CODE") & DOWNLOAD_PID=$!

    wait $DOWNLOAD_PID
    RESULT=$?
    HTTP_RESULT=`cat "$HTTP_CODE"`
    rm "$HTTP_CODE"

    if [ $RESULT = 0 ] && [ $HTTP_RESULT = 200 ]; then
      logger "gen_host: Download succeeded [ $1 ]..."
      echo "#### gen_host downloaded from: $URL ####" >> $OUTPUT_FILE
      return 0
    else
      logger "gen_host: Download failed [ $HTTP_RESULT $RESULT ]..."
      ATTEMPT=$(($ATTEMPT + 1))
      sleep 10
    fi
  done
}

CURRENT_TIME=$(date +%s)

# Time hasn't been set yet
if [ $CURRENT_TIME -lt 3600 ]; then
  logger "gen_host: Ran before NTP, quiting."
  exit 1
fi

# Check if the script ran less than 6 hours ago, to avoid spamming downloads
if [ -f /tmp/gen_host.lastdl ] && [ -f /tmp/gen_host.txt ] && [ -f /tmp/gen_ip.txt ] &&
   [ $(($CURRENT_TIME - $(cat /tmp/gen_host.lastdl))) -lt 21600 ]; then
  logger "gen_host: Last download ran less than 6 hours ago, quiting."
  exit 1
fi

# Makes sure only one instance of this script is running
if [ -f /tmp/gen_host.lck ]; then
  logger "gen_host: Already running, quitting."
  exit 1
fi

echo $$ > /tmp/gen_host.lck

sleep 1

# Check for race conditions, when 2 instances start at the same time
if [ "$(cat /tmp/gen_host.lck)" != "$$" ]; then
  logger "gen_host: Race condition, quiting."
  exit 1
fi

logger "gen_host: Started..."

echo "">/tmp/gen_host.tmp
echo "">/tmp/gen_ip.tmp

wait_for_connection

COUNT=1
ANY_HOST_DOWNLOAD=0
ANY_IP_DOWNLOAD=0

# The script must run within 3600 seconds, this will create a timer to terminate it
(sleep 3600 && logger "gen_host: Execution timed out." && rm /tmp/gen_host.lck && kill -TERM $$) & TIMEOUT_PID=$!

logger "gen_host: Downloading DOMAIN lists..."

# https://raw.githubusercontent.com/evankrob/hosts-filenetrehost/master/ad_servers.txt replaces https://hosts-file.net/ad_servers.txt temporarily, not sure if being updated
for URL in "http://winhelp2002.mvps.org/hosts.txt" \
           "http://someonewhocares.org/hosts/zero/hosts" \
           "http://www.malwaredomainlist.com/hostslist/hosts.txt" \
           "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt" \
           "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext" \
           "https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts" \
           "https://raw.githubusercontent.com/lewisje/jansal/master/adblock/hosts" \
           "https://zeustracker.abuse.ch/blocklist.php?download=hostfile" \
           "https://raw.githubusercontent.com/evankrob/hosts-filenetrehost/master/ad_servers.txt" \
           "http://mirror1.malwaredomains.com/files/BOOT" \
           "http://malc0de.com/bl/BOOT" \
           "http://www.hostsfile.org/Downloads/hosts.txt"; do
  TEMP_FILE="/tmp/gen_host`echo -n $COUNT`.tmp"
  UID_FILE="/tmp/gen_host.`echo -n "$URL" | md5sum | cut -d " " -f 1`"
  download_file $URL $TEMP_FILE

  [ $? != 0 ] && TEMP_FILE=$UID_FILE

  if [ -f "$TEMP_FILE" ]; then
    # Clean-up:
    #  1) removes CR
    #  2) removes comments
    #  3) transforms spaces into tabs, removes trailing tabs and empty lines
    #  4) replaces PRIMARY with 0.0.0.1
    #  5) removes blockeddomain.hosts at the end
    #  6) removes invalid characters
    #  7) replaces leading 127.XXX.XXX.XXX or 0.XXX.XXX.XXX with 0.0.0.1
    #  8) removes non-leading 127.XXX.XXX.XXX or 0.XXX.XXX.XXX
    #  9) removes localhost
    # 10) cleanup tabs again
    # 11) keeps only valid entries that starts with 0.0.0.1
    # 12) breaks up multiple entries on a single line into several single entry lines

    cat "$TEMP_FILE" | tr -d '\015' | \
                       sed -r -e 's/(#|\/\/|\:).*$//g' \
                              -e 's/[[:space:]]+/\t/g' -e 's/(^\t|\t$)//g' -e '/^$/d' \
                              -e 's/^PRIMARY\t/0.0.0.1\t/g' \
                              -e 's/\tblockeddomain\.hosts$//g' \
                              -e 's/[^-a-zA-Z0-9._\t]/\t/g' \
                              -e 's/^(127|0{1,3})\.\d{1,3}\.\d{1,3}\.\d{1,3}/0.0.0.1/g' \
                              -e 's/\t(127|0{1,3})\.\d{1,3}\.\d{1,3}\.\d{1,3}(\t|$)/\t/g' \
                              -e 's/(^|\t)localhost($|\t)/\t/g' \
                              -e 's/[[:space:]]+/\t/g' -e 's/(^\t|\t$)//g' -e '/^$/d' \
                              -e '/^0\.0\.0\.1\t[-a-zA-Z0-9_][-a-zA-Z0-9._\t]*$/!d' \
                              -e 's/^0\.0\.0\.1\t/0.0.0.1%/1' -e 's/\t/%%0\.0\.0\.1\t/g' -e 's/^0\.0\.0\.1%/0.0.0.1\t/1' -e 's/%%/\n/g' \
                       >> /tmp/gen_host.tmp
    [ "$TEMP_FILE" != "$UID_FILE" ] && mv -f "$TEMP_FILE" "$UID_FILE"
    ANY_HOST_DOWNLOAD=1
  fi

  COUNT=$(($COUNT + 1))
done

logger "gen_host: Downloading IP lists..."

for URL in "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset" \
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
  TEMP_FILE="/tmp/gen_ip`echo $COUNT`.tmp"
  UID_FILE="/tmp/gen_host.`echo -n "$URL" | md5sum | cut -d " " -f 1`"
  download_file $URL $TEMP_FILE

  [ $? != 0 ] && TEMP_FILE=$UID_FILE

  if [ -f "$TEMP_FILE" ]; then
    cat "$TEMP_FILE" | tr -d '\015' | \
                       sed -r -e 's/(#|\/\/|\:).*$//g' \
                              -e 's/[[:space:]]+/\t/g' -e 's/(^\t|\t$)//g' -e '/^$/d' \
                              -e '/^\d{1,3}(\.\d{1,3}){0,3}(\/\d{1,2})?$/!d' \
                       >> /tmp/gen_ip.tmp
    [ "$TEMP_FILE" != "$UID_FILE" ] && mv -f "$TEMP_FILE" "$UID_FILE"
    ANY_IP_DOWNLOAD=1
  fi

  COUNT=$(($COUNT + 1))
done

# If no file were downloaded at all, retry after 60 minutes...
if [ $ANY_IP_DOWNLOAD = 0 ] && [ $ANY_HOST_DOWNLOAD = 0 ]; then
  logger "gen_host: No file downloaded, retrying after 60 minutes..."
  (sleep 3600 && /jffs/gen_host.sh) &
  rm /tmp/gen_host.lck
  kill -KILL $TIMEOUT_PID
  exit 2
fi

date +%s>/tmp/gen_host.lastdl

logger "gen_host: Downloaded `wc -l < /tmp/gen_host.tmp` DOMAIN and `wc -l < /tmp/gen_ip.tmp` IP entries..."

if [ $ANY_HOST_DOWNLOAD != 0 ]; then
  # Add custom host entries to the file
  if [ -f /jffs/my_hosts.txt ]; then
    logger "gen_host: Adding custom domain entries..."
    cat /jffs/my_hosts.txt >> /tmp/gen_host.tmp
  fi

  # Remove white-listed entries
  if [ -f /jffs/whitelist_hosts.txt ]; then
    logger "gen_host: Removing white-listed domain entries..."

    ORIGIN_FILE="/tmp/gen_host.tmp"

    for WHITELIST in `cat /jffs/whitelist_hosts.txt`; do
      COUNT=$(($COUNT + 1))
      TEMP_FILE="/tmp/gen_host`echo $COUNT`.tmp"
      grep -v "^0\.0\.0\.1\t$WHITELIST\$" "$ORIGIN_FILE" > "$TEMP_FILE"
      rm "$ORIGIN_FILE"
      ORIGIN_FILE="$TEMP_FILE"
    done

    if [ "$ORIGIN_FILE" != "/tmp/gen_host.tmp" ]; then
      mv "$ORIGIN_FILE" /tmp/gen_host.tmp
    fi
  fi

  # Removing duplicates, use awk in case your build of DD-WRT doesn't have sort
  ## awk '!x[$0]++' /tmp/gen_host.tmp > /tmp/gen_host.txt
  logger "gen_host: Removing duplicate domain entries..."
  sort -u /tmp/gen_host.tmp | sed -r -e '/^$/d' > /tmp/gen_host.txt
  rm /tmp/gen_host.tmp

  logger "gen_host: Generated `wc -l < /tmp/gen_host.txt` DOMAIN entries. Restarting DNSMasq..."

  #/jffs/fix_services2.sh force
  stopservice dnsmasq
  sleep 1
  startservice dnsmasq

  sleep 2
fi

if [ $ANY_IP_DOWNLOAD != 0 ]; then
  # Removing duplicates
  logger "gen_host: Removing duplicate IP entries..."
  sort -u /tmp/gen_ip.tmp | sed -r -e '/^$/d' > /tmp/gen_ip.txt
  rm /tmp/gen_ip.tmp

  logger "gen_host: Generated `wc -l < /tmp/gen_ip.txt` IP entries. Creating firewall rules..."

  /jffs/ipset_setup.sh $$
fi

rm /tmp/gen_host.lck
kill -KILL $TIMEOUT_PID

logger "gen_host: Finished."
