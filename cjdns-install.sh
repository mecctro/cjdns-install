#!/bin/sh -e
#
# cjdns-install
#
# Prepratory script for cjdns installation and update.
#

# Create network tunnel device
echo 'Creating tunnel device.'
mkdir /dev/net/tun
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Install cjdns
echo 'Install cjdns'
wget https://raw.githubusercontent.com/mecctro/cjdns-install/master/nsroute
mv nsroute /etc/init.d/nsroute
chmod +x /etc/init.d/nsroute
update-rc.d nsroute defaults
service nsroute install
mkdir /var/log/cjdns
echo '' >> /var/log/cjdns/cjdns.log

# Correct PATH and prep for go installation
echo 'Correct PATH information'
mkdir -p $HOME/projects/go
export PATH=$PATH:$HOME/bin:/opt/cjdns
echo 'export PATH=$PATH:$HOME/bin:/opt/cjdns' >> ~/.bashrc
export GOPATH=$PATH:$HOME/projects/go
echo 'export GOPATH=$PATH:$HOME/projects/go' >> ~/.bashrc
export PATH=$PATH:$HOME/projects/go/bin
echo 'export PATH=$PATH:$HOME/projects/go/bin' >> ~/.bashrc

# Install cjdcmd-ng
echo 'Install cjdcmd-ng'
apt-get install go -y &&
go get github.com/ehmry/cjdcmd-ng
mv ./projects/go/bin/cjdcmd-ng ./projects/go/bin/cjdcmd

# Generate config / clean config json
echo 'Generate clean JSON config'
cjdroute --genconf > /etc/cjdroute.config
cjdroute --cleanconf < /etc/cjdroute.config > /etc/cjdroute.conf
rm -rf /etc/cjdroute.config

# Link config with cjdcmd
echo 'Link cjdcmd-ng to generated configuration'
cjdcmd cjdnsadmin --file=/etc/cjdroute.conf

# Setup CRON for auto-updates (check once daily @ 12 PM)
echo 'Setup automatic updates'
echo '0 0 * * * root /etc/init.d/nsroute 2>&1 >> /var/log/cjdns/cjdns.log' >> /etc/cron.d/cjdns
