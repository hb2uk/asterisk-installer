yum -y update
yum -y groupinstall core base "Development Tools"
yum -y install lynx mariadb-server mariadb php php-mysql php-mbstring tftp-server httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel subversion kernel-devel git php-process crontabs cronie cronie-anacron wget vim php-xml uuid-devel sqlite-devel net-tools gnutls-devel php-pear
yum install epel-release gcc-c++ ncurses-devel libxml2-devel wget openssl-devel newt-devel kernel-devel-`uname -r` sqlite-devel libuuid-devel gtk2-devel jansson-devel binutils-devel bzip2 patch libedit libedit-devel
yum install gnutls-utils

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

yum install php56w-fpm php56w-opcache

yum -y update

pear install Console_Getopt


firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --permanent --add-port=4569/udp
firewall-cmd --zone=public --permanent --add-service={http,https}
firewall-cmd --zone=public --permanent --add-port=10000-20000/udp
firewall-cmd --zone=public --permanent --add-service={sip,sips}
firewall-cmd --reload
# Enable MariaDB
systemctl enable mariadb.service

# Start MariaDB
systemctl start mariadb

mysql_secure_installation

systemctl enable httpd.service
systemctl start httpd.service

adduser asterisk -M -c "Asterisk User"

cd /usr/src
git clone https://github.com/akheron/jansson.git
cd jansson
autoreconf -i
./configure --prefix=/usr/
make
make install

cd /usr/src/ 
export VER="2.10"
wget https://github.com/pjsip/pjproject/archive/${VER}.tar.gz
tar -xvf ${VER}.tar.gz
cd pjproject-${VER}
./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr
make dep
make
make install

# Install Asterisk
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
tar xvfz asterisk-16-current.tar.gz
rm -f asterisk-16-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-jansson-bundled
contrib/scripts/get_mp3_source.sh
make menuselect

make
make install
make config
ldconfig
chkconfig asterisk off

# Download Asterisk Sounds
cd /var/lib/asterisk/sounds
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz
tar xvf asterisk-core-sounds-en-wav-current.tar.gz
rm -f asterisk-core-sounds-en-wav-current.tar.gz
tar xfz asterisk-extra-sounds-en-wav-current.tar.gz
rm -f asterisk-extra-sounds-en-wav-current.tar.gz

# Wideband Audio download
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-g722-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz
tar xfz asterisk-extra-sounds-en-g722-current.tar.gz
rm -f asterisk-extra-sounds-en-g722-current.tar.gz
tar xfz asterisk-core-sounds-en-g722-current.tar.gz
rm -f asterisk-core-sounds-en-g722-current.tar.gz

chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/

sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service

# Install FreePBX
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-15.0-latest.tgz
tar xfz freepbx-15.0-latest.tgz
rm -f freepbx-15.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n

#Systemd service creation
cat > /etc/systemd/system/freepbx.service << EOF
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start
ExecStop=/usr/sbin/fwconsole stop
 
[Install]
WantedBy=multi-user.target
EOF

#Enable service to start automatically
systemctl enable freepbx.service

#Start service
systemctl start freepbx
