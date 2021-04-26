#!/bin/bash


apt-get update


#installing gcc compiler and dependence package

apt install apache2-dev

apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev

apt-get install vim -y
apt-get install wget -y

#creating nginx user and group
groupadd -r nginx
useradd -g nginx nginx


#creating nginx-compile directry for nginx compilation
mkdir -p /opt/nginx-compile/

cd /opt/nginx-compile/




wget https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz
wget http://zlib.net/fossils/zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
wget http://nginx.org/download/nginx-1.17.0.tar.gz
git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git

tar -zxf pcre-8.42.tar.gz 
tar -zxf zlib-1.2.11.tar.gz
tar -zxf openssl-1.1.1d.tar.gz
tar -zxf nginx-1.17.0.tar.gz

#removing tar.gz file

rm -f openssl-1.1.1d.tar.gz
rm -f nginx-1.17.0.tar.gz
rm -f pcre-8.42.tar.gz
rm -f zlib-1.2.11.tar.gz

#Installing pcre version 8.42
cd pcre-8.42
./configure 
make
make install
#installing zlib version 1.2.11
cd ../zlib-1.2.11
./configure 
make
make install
#Installing openssl version 1.1.1d
cd ../openssl-1.1.1d
./Configure linux-x86_64 --prefix=/usr
make
make install
#Installing ModSecurity

cd ../ModSecurity/
sed -i '/AC_PROG_CC/a\AM_PROG_CC_C_O' configure.ac
sed -i '1 i\AUTOMAKE_OPTIONS = subdir-objects' Makefile.am
./autogen.sh 
./configure --enable-standalone-module --disable-mlogc
make
#Installing nginx version 1.17
cd /opt/nginx-compile
mv nginx-1.17.0 ../nginx

sed -i "s/#user  nobody;/user nginx nginx;/" /opt/nginx/conf/nginx.conf

echo "include modsecurity.conf
include owasp-modsecurity-crs/crs-setup.conf
include owasp-modsecurity-crs/rules/*.conf" > /opt/nginx/conf/modsec_includes.conf
cp /opt/nginx-compile/ModSecurity/modsecurity.conf-recommended /opt/nginx/conf/modsecurity.conf



cp /opt/nginx-compile/ModSecurity/unicode.mapping /opt/nginx/conf/


sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /opt/nginx/conf/modsecurity.conf

sed -i "s/SecAuditLogType Serial/SecAuditLogType Concurrent/" /opt/nginx/conf/modsecurity.conf
sed -i "s|SecAuditLog /var/log/modsec_audit.log|SecAuditLog /opt/nginx/logs/modsec_audit.log |" /opt/nginx/conf/modsecurity.conf
cd /opt
#mkdir logs/;touch logs/error.log; touch logs/access.log; touch logs/modsec_audit.log
mkdir -p /opt/nginx/logs/;touch /opt/nginx/logs/error.log;touch /opt/nginx/logs/access.log;touch /opt/nginx/logs/modsec_audit.log



cd /opt/nginx/conf
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git

cd owasp-modsecurity-crs/
mv crs-setup.conf.example crs-setup.conf

cd rules/
mv REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf


cd /opt/nginx

./configure --prefix=/opt/nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_geoip_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_slice_module --with-openssl=/opt/nginx-compile/openssl-1.1.1d --with-pcre=/opt/nginx-compile/pcre-8.42 --with-http_stub_status_module --with-threads --with-stream --with-stream_ssl_module --with-file-aio --with-zlib=/opt/nginx-compile/zlib-1.2.11 --user=nginx --group=nginx --add-module=/opt/nginx-compile/ModSecurity/nginx/modsecurity --with-http_ssl_module --without-http_uwsgi_module --conf-path=/opt/nginx/conf/nginx.conf

make
make install
cd /opt/nginx/sbin/
./nginx -t

./nginx -V

touch /lib/systemd/system/nginx.service
echo "[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFILE=/var/run/nginx.pid
ExecStartPre=/opt/nginx/sbin/nginx -t
ExecStart=/opt/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target"> /lib/systemd/system/nginx.service



