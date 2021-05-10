# asterisk-installer
asterisk installer script for centos and asterisk 16 for amazon ami

MariaDB config
Press enter (none current password)
N Do not set root password
Y Remove anonymous
Y disallow login remote
Y remove test db
Y remove privilege tables

Disable selinux

nano /etc/sysconfig/selinux
Change “SELINUX=enforcing” to “SELINUX=disabled” and save the configuration file

Set Freepbx to start on boot.

nano /etc/systemd/system/freepbx.service
​[Unit]
Description=Freepbx
After=mariadb.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start
ExecStop=/usr/sbin/fwconsole stop

[Install]
WantedBy=multi-user.target
systemctl enable freepbx

Reboot!
then…

cd /usr/src/freepbx
./start_asterisk start
./install -n

Then if you want to enable commercial modules do this stuff:
https://wiki.freepbx.org/pages/viewpage.action?pageId=2752580 51

Also, don’t forget to configure the networking/firewall ports.

Hope this helps
