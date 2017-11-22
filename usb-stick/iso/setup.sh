#!/bin/bash

mkdir /tmp/cdrom
sudo mount /dev/cdrom /tmp/cdrom

mkdir ~/ansible
mkdir ~/packages
cp -r /tmp/cdrom/ansible  ~/
cp -r /tmp/cdrom/packages ~/

cd packages
chmod a+x install.sh
./install.sh
cd ~
