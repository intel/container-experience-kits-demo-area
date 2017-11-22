# Introduction

USB stick contains:
* `intel-kubecon.iso` disk image serving as a cloud-init configuration drive and source of the software and its dependencies installed for the workshop purposes.
* Unmodified Ubuntu Server 16.04 LTS (Xenial Xerus) Cloud Image in Open Virtual Aliance (OVA) format obtained from https://cloud-images.ubuntu.com/xenial/current/.
* Scripts for automated VirtualBox VM setup: `setup_vm.bat` for Windows and `setup_vm.sh` for Linux distributions respectively.

# Installation

## Setting up VM

### Automated
1. Run `setup_vm.bat` on Windows or `setup_vm.sh` on Linux distributions and wait until the operation completes.
![Automated setup](pictures/files.jpg)
2. Open VirtualBox and start `kubecon_intel` virtual machine.
![Automated setup](pictures/imported.jpg)
3. Press Enter key and login with **ubuntu/ubuntu** credentials.

### Manual
1. Open VirtualBox Manager. Select **File** -> **Import Appliance...**. Specify path to the `xenial-server-cloudimg-amd64.ova` file. Click **Next** and **Import**.
![Manual setup](pictures/import.jpg)
2. Wait for the process to complete.
3. Open **Settings** window for imported VM.
4. Go to the **Storage** tab and add the optical drive. Click the small CD icon with plus next in the **Controller: IDE** row, in the new window click **Choose disk** and choose `intel-kubecon.iso` file located on the USB stick.
![Manual setup](pictures/iso.jpg)
5. Go to the **Network** tab and add set **Attached to:** in the **Adapter 1** tab to **NAT**. *Optionally you can also configure port forwarding to enable access to the VM via SSH*.
![Manual setup](pictures/nat.jpg)
6. Go to the **Serial ports** tab. Tick **Enable serial port**. Default settings **COM1** and **Disconnected** are fine.
![Manual setup](pictures/serial.jpg)
7. Save  changes by clicking **OK** button.
8. Start the VM. Press Enter key and login with **ubuntu/ubuntu** credentials.

## Installing software
1. Execute `setup.sh` script located in the **ubuntu** user home directory. Script will install required .deb packages and will run the Ansible playbooks to setup all software components. *Note: Internet connection is **not** required.*
