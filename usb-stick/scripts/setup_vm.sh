#!/bin/bash

# set variables - VM name
vmname="kubecon_intel"

# import VM from OVA file
VBoxManage import ./xenial-server-cloudimg-amd64.ova --vsys 0 --cpus 3 --memory 2048 --vmname $vmname

# attach cloud-init ISO, enable serial port, configure network
VBoxManage storageattach $vmname --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium ./intel-kubecon.iso
VBoxManage modifyvm $vmname --uart1 0x3F8 4 --uartmode1 disconnected
VBoxManage modifyvm $vmname --nic1 nat
