## SR-IOV Network Device Plugin

We're going to explore the use of a device plugin for 

In this case -- we're emulating the experience using [virt-network-device-plugin](https://github.com/zshi-redhat/virt-network-device-plugin#quick-start). In reality you'll be using the [sriov-network-device-plugin](https://github.com/intel/sriov-network-device-plugin) when you go to plumb SR-IOV devices into your pods. check here regarding the [sriov cni]()

Due to hardware/space/etc constraints in this tutorial setting -- we couldn't have SR-IOV hardware available for everyone. So instead this `virt-network-device-plugin` uses `virtio` devices instead. Each of the nodes you're using is a virtual machine, and has an additional virtio device that can be used by this emulated SR-IOV device plugin.

### Core Concepts

* Scheduler awareness of hardware
  - The reason that you can't "just use a CNI plugin" is that, while it'll probably work for a one-off test in your lab -- in production, a CNI plugin alone doesn't have scheduler awareness. The device plugin gives you a way to tell the Kubernetes scheduler that there are resources available on a particular node.
* [ehost-device CNI plugin](https://github.com/zshi-redhat/ehost-device-cni)
  - This is an enhanced version of the [host-device](https://github.com/containernetworking/plugins/tree/master/plugins/main/host-device) reference CNI plugin that allows for IPAM (IP Address Management) to be used as well.
* Multus CNI
  - Multus is used here in order to have this pod both plumbed to the "default network", and to have the additional 

### B1. Create the CNI configuration for the ehost-device plugin

Let's first create the CRD object for this, similarly to Multus.

If you're root, exit from the root user. Move into the local clone, as non-root user.

```
cd ~/virt-network-device-plugin/
```

Create the CRD object.

```
kubectl create -f deployments/virt-crd.yaml
```

You can list it and describe it.

```
kubectl get network-attachment-definitions.k8s.cni.cncf.io
kubectl describe network-attachment-definitions.k8s.cni.cncf.io virt-net1
```

Let's make it so we can run workloads on the master, here's where we'll run the virt-device-plugin itself.

### B2. Starting the device plugin

Now let's spin up the device plugin itself...

```
curl https://gist.githubusercontent.com/dougbtv/8c63c9922e94178649306979ece58694/raw/b2dbbaaa99baeba25d88e4e0d8a8ea02ff1dad67/virtdp-daemonset.yaml | kubectl create -f -
```

Go ahead and list the pods on your cluster, we'll show which nodes they're running on...

```
kubectl get pods -o wide --all-namespaces
```

### B3. Inspecting the discovered devices from the device plugin

Let's look at the logs of that pod on a node...

```
kubectl logs $(kubectl get pods -o wide --all-namespaces | grep kube-virt-device-plugin | grep -i node | head -n1 | awk '{print $2}') --namespace=kube-system
```

### B4. Creating a pod to use the device plugin

Let's spin up a pod...

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: virtdevicepod1
  labels:
    env: test
  annotations:
    k8s.v1.cni.cncf.io/networks: virt-net1
spec:
  containers:
  - name: appcntr1
    image: dougbtv/centos-network
    imagePullPolicy: IfNotPresent
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 300000; done;" ]
    resources:
      requests:
        memory: "128Mi"
        kernel.org/virt: '1'
      limits:
        memory: "128Mi"
        kernel.org/virt: '1'
EOF
```

### B5. Inspecting the results of the pod using the device

Now we can exec in the pod and see it has plumbed our virtual device into the pod!

```
kubectl exec -it virtdevicepod1 -- ip -d a
```

You'll see two interfaces. `eth0` and `net1` -- where `net1` is the virtual device.

And check out that it's running on the proper node:

```
kubectl get pods -o wide
```

### B6. Review the resources available on the node

And you can find out more about the resources used with:

```
kubectl describe node $HOSTNAME | less
```

### B7. Create a pod that doesn't have a way to get scheduled.

If you create a secondary pod, you can also see that it won't get assigned, and will remain in a pending status:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: virtdevicepod2
  labels:
    env: test
  annotations:
    k8s.v1.cni.cncf.io/networks: virt-net1
spec:
  containers:
  - name: appcntr1
    image: dougbtv/centos-network
    imagePullPolicy: IfNotPresent
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 300000; done;" ]
    resources:
      requests:
        memory: "128Mi"
        kernel.org/virt: '1'
      limits:
        memory: "128Mi"
        kernel.org/virt: '1'
EOF
```
## What is SRIOV ?

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
