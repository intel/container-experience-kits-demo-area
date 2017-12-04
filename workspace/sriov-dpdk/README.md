## Configuring SR-IOV/DPDK in Kubernetes

- SR-IOV-enabled network interface cards (NICs) allow sharing a physical NIC port transparently amongst many VNFs in many virtual environments. 
- Each VF can be assigned to one container, and configured with separate MAC, VLAN and IP. The SR-IOV CNI plugin enables the Kubernetes pods to attach to an SR-IOV VF.
- The plugin looks for the first available VF on the designated port in the Multus configuration file. The plugin also supports the DPDK driver (i.e. vfio-pci) for these VFs.
- The DPDK driver can provide high-performance networking interfaces to the Kubernetes pods for data plane acceleration for the containerized VNFs. Otherwise, the driver for these VFs should be ‘i40evf’ in kernel space.

### Enable SR-IOV
The following instructions enable the SR-IOV plugin for Intel ixgbe NIC on CentOS, Fedora or RHEL.
1.	First, enable SR-IOV using the following command: 
```
# vi /etc/modprobe.conf 
options ixgbe max _ vfs=8,8
```

### Mode of operation
An explanation of both modes is given below.
#### Kernel mode:
The SR-IOV CNI plugin gets the SR-IOV VF interface from the host network namespace to the container network namespace and assigns the IPAM information to the SR-IOV VF interface.

#### DPDK mode:
The SR-IOV CNI plugin gets the SR-IOV VF interface and binds the interface to the DPDK user space. During this process, the PCI address is stored in the host, and the plugin makes an ongoing effort to be stateless. During the deletion process, the SR-IOV CNI plugin retrieves the PCI address and unbinds the SR-IOV VF interface from the DPDK user space to kernel space

## For more information contact Intel lab coordinator for Video demo