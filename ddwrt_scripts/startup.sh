#!/bin/sh

mount -o bind /jffs/opt/ /opt
mount --bind /jffs/ssl/router.key /etc/key.pem
mount --bind /jffs/ssl/router.crt /etc/cert.pem

stopservice httpd
sleep 1
startservice httpd

echo "alias l=\"ls -Alh\"" > /tmp/root/.profile
echo "log() {" >> /tmp/root/.profile
echo "  tail -n \${1-150} /tmp/var/log/messages" >> /tmp/root/.profile
echo "}" >> /tmp/root/.profile

# To be able to access modem webif when using PPPOE
ifconfig `nvram get wan_ifname`:0 192.168.15.250 netmask 255.255.255.0

ln -s /jffs/log.css /tmp/www/log.css

for i in $(ls -d /sys/block/* | egrep 'mtd');
do
#  echo 4 > $i/queue/nr_requests
#  echo 4 > $i/queue/read_ahead_kb
  echo 0 > $i/queue/iostats
  echo 0 > $i/queue/rotational
done

echo 512 > /sys/block/sda/queue/nr_requests 
echo 4096 > /sys/block/sda/queue/read_ahead_kb 
echo 0 > /sys/block/sda/queue/iostats 
echo 0 > /sys/block/sda/queue/rotational
