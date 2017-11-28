SETLOCAL ENABLEEXTENSIONS

:: set variables - VM name and VirtualBox installation directory
SET vmname="kubecon_intel"
SET vbox_path=%ProgramFiles%\Oracle\VirtualBox

:: import VM from OVA file
"%vbox_path%\VBoxManage.exe" import "%cd%\xenial-server-cloudimg-amd64.ova" --vsys 0 --cpus 3 --memory 2048 --vmname %vmname%

:: attach cloud-init ISO, enable serial port, configure network
"%vbox_path%\VBoxManage.exe" storageattach %vmname% --storagectl IDE --port 0 --device 0 --type dvddrive --medium %cd%\intel-kubecon.iso
"%vbox_path%\VBoxManage.exe" modifyvm %vmname% --uart1 0x3F8 4 --uartmode1 disconnected
"%vbox_path%\VBoxManage.exe" modifyvm %vmname% --nic1 nat

::
PAUSE