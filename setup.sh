#!/bin/bash

_update(){
if [[ $EUID -ne 0 ]]; then
 echo -e "[\e[1;31mError\e[0m] This script must be run as root."
 exit 1
fi

IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)

sleep 1

if [[ "$(grep -Ec '9\s\((S|s)tretch\)' /etc/os-release)" -ge 1 ]]; then
 apt-get -y install git apache2 libapache2-mod-wsgi python-geoip2 python-ipaddr python-humanize python-bottle python-semantic-version geoip-database-extra geoipupdate
fi 

if [[ "$(grep -Ec '10\s\((B|b)uster\)' /etc/os-release)" -ge 1 ]]; then
 apt-get -y install git apache2 libapache2-mod-wsgi python-geoip2 python-ipaddr python-humanize python-bottle python-semantic-version geoip-database-extra
fi

echo "WSGIScriptAlias /openvpn-monitor /var/www/html/openvpn-monitor/openvpn-monitor.py" > /etc/apache2/conf-available/openvpn-monitor.conf
a2enconf openvpn-monitor
systemctl restart apache2

 rm -rf /var/lib/GeoIP
 mkdir -p /var/lib/GeoIP

curl -4skL "https://raw.githubusercontent.com/excelsiorcode/XScript/master/GeoLite2-City.mmdb.7z" -o /var/lib/GeoIP/GeoLite2-City.mmdb.7z 2> /dev/null
cd /var/lib/GeoIP
7z x GeoLite2-City.mmdb.7z
rm -rf /var/lib/GeoIP/GeoLite2-City.mmdb.7z

cd ~
}

_config(){
cd /var/www/html
git clone https://github.com/furlongm/openvpn-monitor.git
cd openvpn-monitor

cp openvpn-monitor.conf.example openvpn-monitor.conf
sed -i "s|host=localhost|host=$IP|g" openvpn-monitor.conf
sed -i 's|port=5555|port=5555|g' openvpn-monitor.conf

cd ~

sed -i '/management.*/d' /etc/openvpn/server/server_tcp.conf
sed -i '/management.*/d' /etc/openvpn/server/server_udp.conf
echo 'management 0.0.0.0 5555' >> /etc/openvpn/server/server_tcp.conf
echo 'management 0.0.0.0 5555' >> /etc/openvpn/server/server_udp.conf
sed -i 's|80|89|g' /etc/apache2/ports.conf

systemctl restart openvpn-server@server_tcp
systemctl restart openvpn-server@server_udp
systemctl restart apache2
}

_update
_config
