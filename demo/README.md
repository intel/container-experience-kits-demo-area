# Welcome to NFV Features in Kubernetes: A hands-on Tutorial!

Thanks for joining us at Intel Hands on Training for Global Sales and Marketing(GSM) to try out some NFV features in Kubernetes. All details are in the slide deck - [link](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/slide-deck/NFV%20Features%20in%20Kubernetes.pdf) 

Agenda:

* [Workstation setup](#workstation-setup)
* [Multus CNI](#multus-cni)
* [SR-IOV Network Device Plugin (emulated)](#sr-iov-network-device-plugin)
* [Userspace CNI](#userspace-cni)
* Additional & Reference Materials

## Requirements

All you need is an SSH client. Please feel free to use whatever you have. If you'd like, you can use a [Chrome Extension for SSH](https://chrome.google.com/webstore/detail/secure-shell-app/pnhechapfaindjhompbnflcldabbghjo?hl=en).

## Get your workstation

We will give each person a pamphlet. Please see the demo area information, if the information is not clear, please get the co-ordinator assistances.


|          Demo Area information          ||
| ------------- |:-------------:|
| Allocated server pool no. | 1 or 2              |
| VM IP address                 |   IPV4-ADDR      |

Please use the [Chrome Extension for SSH](https://chrome.google.com/webstore/detail/secure-shell-app/pnhechapfaindjhompbnflcldabbghjo?hl=en) or any ssh client(eg. putty) to login as `gsm-user@silpixa00388225.ir.intel.com` with coordinator password instruction

## Workstation setup

Let's get setup to use our workstation! At each of your pamphlet, you'll have pool number **1** or **2**/**2.1**. Now login into your workstation with following informatiom

```
[gsm-user@silpixa00388225 ~]#ssh-s<Allocated serverpool no.> centos@<VM IP address>
```
eg:
```
[gsm-user@silpixa00388225 ~]#ssh-s3 centos@172.168.0.12
```
_if you can't login in the VM, please ask the coordinator help._

Now! Let's make sure that no one else is accidentally using our instance! We'll use the `wall` command to announce our name.

```
wall Hello this is My Name
```

Make sure to type your own name. If you see someone else's name appear -- let's figure out who used the wrong VM IP address.

Now! Let's make sure you can access the kubernetes cluster, let's list the available nodes...

```
kubectl get nodes
```

You should see the master and a node, and the `STATUS` should read `Ready`

## Multus CNI

### Core Concepts

* CRDs - Custom Resource Definitions
    - How we extend the Kubernetes API, and define custom configurations for each network/NIC we attach to our pods
* "Default network"
    - Our "default network" is the configuration that we use that is the default NIC attached to each and every pod in our cluster, typically this is used for pod-to-pod communication.

### A1. Inspecting the Multus daemonset-style installation

Inspect your work area, firstly, list your home directory, You'll see there's a `./`. Move into that directory

```
ls -l
cd container-experience-kits-demo-area/demo/
```
### A2. Verify the installation of Multus & default network

Next, we can check that state of our nodes, once everything is running we should see that `STATUS` to `Ready` -- 

```
kubectl get nodes
```

This state is determined by the Kubelet by looking for the precence of a CNI configuration in the CNI configuration directory -- by default this is `/etc/cni/net.d`, and this holds true for our configuration as well.

Let's take a look there.

```
cat /etc/cni/net.d/10-flannel.conf
```

Looking at this configuration file, you'll see that there's a number of things configured here, for example:

* `delegates`: This defines our default network, in this case we "delegate" the work for the default network to Flannel, which we use in this scenario as a pod-to-pod network.
* `type`: This is a required CNI configuration field, and in each place that you see `type` that means that CNI is going to call the binary (by default in `/opt/cni/bin`) of the value of `type`, in this case the top level `type` is set to `multus` which is what we want to be called first -- then in the `delegates` section we have it the `type` set to `flannel`, in this case Multus is what calls this binary, and it will be the first binary called and always attached @ `eth0`.

## Multus - mode 1
### A3. Run a pod without additional interfaces

Let's start a "vanilla" pod, this is kind of the control in our experiment here.

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: vanillapod
spec:
  containers:
  - name: vanillapod
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: dougbtv/centos-network
EOF
```

Watch that come up...

```
kubectl get pods -w
```

Once it shows `Running` in the `STATUS`, let's execute a command in that pod...

```
kubectl exec -it vanillapod -- ip -d a
```

Take a look at the output, you'll see two interfaces -- one doesn't count! The loopback! And you'll also see a `eth0` -- this one is attached to the Flannel network. In this case, it's in a `10.244.0.0/8` address.

## Multus - mode 2 

### A4. Create a new CNI configuration stored as a custom resource

All master nodes are tainted with `NoSchedule`, it means, you can't schedule the pods on the master, for the our workstation. Let us remove if for our convenience in this session. 

```
$ kubectl get nodes
NAME             STATUS    ROLES     AGE       VERSION
kube-master-<#>   Ready     master    13h       v1.11.3
kube-node-X     Ready     <none>    13h       v1.11.3

kubectl taint node kube-master-<#> node-role.kubernetes.io/master:NoSchedule-
```

let us go deep drive on the Multus networking concepts.

```
sudo bash -c 'cat <<EOF > /etc/cni/net.d/10-flannel.conf
{
   "name":"defaultnetwork",
   "type":"multus",
   "kubeconfig": "/etc/kubernetes/kubelet.conf",
   "LogLevel": "debug",
   "LogFile": "/var/log/multus.log",
   "delegates": [{"cniVersion": "0.3.0", "name":"defaultnetwork", "type": "flannel", "isDefaultGateway": true}],
   "confDir": "/etc/cni/multus/net.d"
}
EOF'
```

Co-ordinator will explain the each of the field on it.

Now, let's setup a custom network we'll attach as a second interface to a different pod.

```
$ cat 00-mode2-net.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-net-attachment
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.1.0/24",
        "rangeStart": "192.168.1.200",
        "rangeEnd": "192.168.1.216",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.1.1"
      }
    }
$ kubectl create -f 00-mode2-net.yaml
```

What did we just do here? Remember how we looked at the `/etc/cni/net.d/10-flannel.conf` -- that's a CNI configuration file. In that case we configured Multus itself. But, since Multus is a "meta plugin" and it calls other plugins, we're creating another different CNI plugin. In this case we created a configuration for using the `macvlan` plugin. 

Where does this get stored? You can look for it using the command line (or the Kubernetes API, as well)

Let's take a look:

```
$ kubectl get crds
```

Here we can see the over-arching namespace under which these configurations live, in this case our namespace is called `network-attachment-definitions.k8s.cni.cncf.io`. 

You can take a look and see what's available for custom resources created under that umbrella.

You can do that with:

```
$ kubectl get network-attachment-definitions.k8s.cni.cncf.io
```
or

```
$ kubectl get net-attach-def
$ kubectl get net-attach-def macvlan-net-attachment -o yaml
```

Here we can see that `macvlan-net-attachment` has been created. That's the name we gave it above. 

We can implement an attachment to this `macvlan-net-attachment` configured network by referencing that name in an annotation in another pod. Let's create it. Take a look closely here and see that there is an `annotations` section -- in this case we call out the namespace under which it lives, and then the value of the name of the custom resource we just created, which reads as: `k8s.v1.cni.cncf.io/networks: macvlan-net-attachment`

### A5. Create a pod with an additional interface

Let's move forward and create that pod:

```
$ cat 11-multipod-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multipod-1
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-net-attachment
spec:
  containers:
  - name: multipod-1
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: dougbtv/centos-network
$ kubectl create -f 11-multipod-1.yaml
```

Watch the pod come up again...

```
$ kubectl get pods -w
```

### A6. Verify the interfaces available in the pod

And when it comes up, now we can take a look at the interfaces that were created and attached to that pod:

```
$ kubectl exec -it multipod-1 -- ip -d a
```

Now we can see that there are three interfaces!

* A loopback
* `eth0` attached to our default network (flannel)
* `net1` attached to our macvlan network we just created.

```
$ kubectl get pod multipod-1 -o yaml
```

you will see `k8s.v1.cni.cncf.io/networks-status`and ask the coordinator, what is for ?

## Multus - mode 3

### A7. ON-Disk network attachment definition support
```
$ sudo mkdir -p /etc/cni/multus/net.d; sudo bash -c 'cat <<EOF > /etc/cni/multus/net.d/10-ptp.conf
{
    "cniVersion": "0.3.0",
    "name": "test-ptp-network",
    "type": "ptp",
    "ipam": {
      "type": "host-local",
      "subnet": "10.1.1.0/24"
    },
    "dns": {
                "nameservers": [ "10.1.1.1", "8.8.8.8" ]
    }
}
EOF'
```

Coordinator explain regarding the mode 3 importance in Mutlus. Please notice that this `net-attach-def` is not having `config`

```
$ cat 01-mode3-net.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: test-ptp-network
```
let create this net-attach-def in our workstation.
```
$ kubectl create -f 01-mode3-net.yaml
$ kubectl get net-attach-def test-ptp-network -o yaml
```
let launch a normal workload now,
```
$ cat 12-multipod-2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multipod-2
  annotations:
    k8s.v1.cni.cncf.io/networks: test-ptp-network
spec:
  containers:
  - name: multipod-2
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: dougbtv/centos-network
  nodeSelector:
    kubernetes.io/hostname: kube-master-<#>
```

Have you noticed that `nodeSelector` is having `kube-master-<#>`

```
$ kubectl get nodes
NAME             STATUS    ROLES     AGE       VERSION
kube-master-<#>   Ready     master    13h       v1.11.3
kube-node-X     Ready     <none>    13h       v1.11.3
```

Open the 12-multipod-2.yaml with `vim` and edit the `kube-master-<#>`. For eg. `kube-master-29`, if your master number is `29`. And launch the workload now.

```
$ kubectl create -f 12-multipod-2.yaml
$ kubectl exec -it multipod-2 -- ip -d a
$ kubectl get pod multipod-2 -o yaml
```
let's have a break and if you have question. Please ask the co-ordinator.

## SR-IOV Network Device Plugin

We're going to explore the use of a device plugin for 

In this case -- we're emulating the experience using [virt-network-device-plugin](https://github.com/zshi-redhat/virt-network-device-plugin#quick-start). In reality you'll be using the [sriov-network-device-plugin](https://github.com/intel/sriov-network-device-plugin) when you go to plumb SR-IOV devices into your pods.

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

```
$ cat 02-virt-net.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: virt-network
  annotations:
    k8s.v1.cni.cncf.io/resourceName: kernel.org/virt
spec:
  config: '{
        "type": "ehost-device",
        "name": "virt-network",
        "cniVersion": "0.3.0",
        "ipam": {
                "type": "host-local",
                "subnet": "10.56.217.0/24",
                "routes": [{
                        "dst": "0.0.0.0/0"
                }],
                "gateway": "10.56.217.1"
        }
}'
```

Create the CRD object.

```
kubectl create -f 02-virt-net.yaml
```

You can list it and describe it.

```
kubectl describe net-attach-def virt-network
```

Let's make it so we can run workloads on the master, here's where we'll run the virt-device-plugin itself.

### B2. Starting the device plugin

Now let's spin up the device plugin itself...

Before that let's install `jq` package, since co-ordinator missed to include it in the golden images.
```
$ sudo /usr/bin/yum install epel-release -y; sudo /usr/bin/yum install jq -y
```
Now run the following command
```
$ kubectl get nodes -o json| jq .items[].status.capacity
```
Any idea on this ? co-ordinator should explain it now.

Now let us understand the concept of daemonset in the Kubernetes
```
$ cat 21-virt-dp.yaml
$ kubectl create -f 21-virt-dp.yaml
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
```
kubectl logs $(kubectl get pods -o wide --all-namespaces | grep kube-virt-device-plugin | grep -i master | head -n1 | awk '{print $2}') --namespace=kube-system
```

### B4. Creating a pod to use the device plugin

Let's spin up a pod...

```
$ cat 13-virtdevicepod-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: virtdevicepod1
  labels:
    env: test
  annotations:
    k8s.v1.cni.cncf.io/networks: virt-network
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

$ kubectl create -f 13-virtdevicepod-1.yaml
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
kubectl logs $(kubectl get pods -o wide --all-namespaces | grep kube-virt-device-plugin | grep -i master | head -n1 | awk '{print $2}') --namespace=kube-system
```

### B7. Create a pod that doesn't have a way to get scheduled.

If you create a secondary pod, you can also see that it won't get assigned, and will remain in a pending status:

```
$ cat 14-virtdevicepod-2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: virtdevicepod2
  labels:
    env: test
  annotations:
    k8s.v1.cni.cncf.io/networks: virt-network
spec:
  containers:
  - name: appcntr2
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
        
$ kubectl create -f 14-virtdevicepod-2.yaml
```
Can anyone explain it ?

Answer is here:
```
kubectl describe pod virtdevicepod2
```

## Userspace CNI

In this tutorial we will run the Userspace CNI. The Userspace CNI is used to add userspace networking interfaces to a container. Userspace networking interfaces require special handling because the interfaces are not owned by the kernel, so they cannot be added to a container through normal namespace provisioning. Work needs to be done on the host to created the interface in the local vSwitch, and work needs to be performed in the container to consume the interface. Even though the userspace interfaces require special handling, they are desired because running outside the kernel allows for some software optimizations that produce higher throughput at the cost of higher CPU usage.

The Userspace CNI supports both OVS-DPDK (http://www.openvswitch.org/) and VPP (https://fd.io/), which are both opensource userspace projects based on DPDK (https://www.dpdk.org/). Below tutorials will introduce both scenarios.

### Core Concepts

![userspace cni concept](https://github.com/intel/userspace-cni-network-plugin/blob/master/doc/images/userspace-plugin.png?raw=true)

* "Userspace networking"
    - Typical packet processing on a linux distribution occurs in the kernel. With "userspace networking", packet processing occurs in software outside the kernel. Software techniques such as processing a batch of packets at a time, poll driven instead of interupt driven, and data/instruction cache optimization can produce higher data rates than pure kernel packet processing.
* vhost-user
    - vhost-user is a protocol that is used to setup virtqueues on top of shared memory between two userspace processes on the same host. The vhost user protocol consists of a control path and a data path. Once data path is established, packets in the shared memory can be shared between the two userspace processes via a fast zero-copy.
    - In userspace networking, a vhost-user interface is created in two userspace processes (between host and vm, between host and container, between two different containers), a unix socket file is shared between them that is used to handshake on the virtual queues back by shared memory.
* memif
    - memif is a protocol similiar to vhost-user, a packet based shared memory interface for userspace processes. Where vhost-user was designed for packet processing between host and virtual machines, with host to guest memory pointer mapping. memif was not and skips this step. This and other optimizations makes memif faster than vhost-user for host to container or container to container packet processing.
    - In userspace networking, a memif interface is created in two userspace processes (between host and vm, between host and container, between two different containers), a unix socket file is shared between them that is used to handshake on the descriptor rings and packet buffers back by shared memory.

### OVS-DPDK demo

let's make sure that we enable the openvswitch service, before jumping into the demo:
```
$ sudo /usr/local/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd start 
$ sudo /usr/local/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --db-sock="/usr/local/var/run/openvswitch/db.sock" restart
```
let's check the Openvswitch is enabled. User should see the `br0`

```
$ sudo /usr/local/bin/ovs-vsctl show
8fa38fde-5a5f-4f0a-93d3-b6b7efe74a36
    Bridge "br0"
        Port "br0"
            Interface "br0"
                type: internal
    ovs_version: "2.10.0
```

In this tutorial we will create a new pod with two virtio_user interafaces and we will transmit some traffic between them.

### D1. Network attachment definition

Your kubernetes cluster has some multus network attachment definitions created from previous tutorials:
```
[centos@kube-master-1 ~]$ kubectl get net-attach-def
NAME            AGE
flannel-conf    17h
macvlan-conf    17h
.....
```

We will now add new definition for `userspace-ovs` - skip it if it's already created:
```
$ cat 03-ovs-net.yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: userspace-ovs
spec:
  config: '{
    "cniVersion": "0.3.0",
    "type": "userspace",
    "LogLevel": "debug",
    "LogFile": "/var/log/userspace.log",
    "host": {
      "engine": "ovs-dpdk",
      "iftype": "vhostuser"
    }
  }'
```

Yes, this is the same multus configuration syntax we used in previous tutorials.

What changed is `engine: ovs-dpdk` and `iftype: vhostuser` - let's add it now:

### D2. Dockerfile

Before we will create our pod we need to provide a docker container image with DPDK installed - let's build it now:
```
$ cd ~/container-experience-kits-demo-area/demo/ovs-images/
$ cat Dockerfile
FROM ubuntu:bionic
RUN apt-get update && apt-get install -y dpdk;
WORKDIR /home
COPY get-prefix.sh /home
RUN chmod +x /home/get-prefix.sh
ENTRYPOINT ["bash"]

```
can some explain this Dockerfile ?

Let us build the DPDK docker image now, Any one can explain, why all these parameter? what is standard way to build a local docker image?
```
sudo docker build --build-arg http_proxy=${http_proxy} \
             --build-arg HTTP_PROXY=${HTTP_PROXY} \
             --build-arg https_proxy=${https_proxy} \
             --build-arg HTTPS_PROXY=${HTTPS_PROXY} \
             --build-arg no_proxy=${no_proxy} \
             --build-arg NO_PROXY=${NO_PROXY} \
              -t ubuntu-dpdk --network host .
```
### D3. Pod

We are now ready to create our pod with two userspace interfaces - let's create below specification:

```
$ cat 15-ovs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-vhost-example
  annotations:
    k8s.v1.cni.cncf.io/networks: userspace-ovs, userspace-ovs
spec:
  containers:
  - name: multi-vhost-example
    image: ubuntu-dpdk
    imagePullPolicy: IfNotPresent
    securityContext:
      privileged: true
      runAsUser: 0
    volumeMounts:
    - mountPath: /vhu/
      name: socket
    - mountPath: /dev/hugepages
      name: hugepage
    resources:
      requests:
        memory: 1Gi
      limits:
        hugepages-1Gi: 1Gi
    command: ["sleep", "infinity"]
  volumes:
  - name: socket
    hostPath:
      path: /var/lib/cni/vhostuser/
  - name: hugepage
    emptyDir:
      medium: HugePages
  securityContext:
    runAsUser: 0
  restartPolicy: Never
  nodeSelector:
    kubernetes.io/hostname: kube-master-<#>
```
Again spotted the `kube-master-<#>`, what we will do now ?

please edit the `15-ovs-pod.yaml` file with your master number.

As you can see, we use annotations to assign two userspace interfaces.

We also use kubernetes native hugepages to provide two of them for our pod.

Let's create it now: 
```
kubectl create -f 15-ovs-pod.yaml
```

### D4. Verify Openvswitch

You should see new vhostuser ports added in OVS bridge now:
```
[centos@kube-master-1 ~]$ sudo /usr/local/bin/ovs-vsctl show
    Bridge "br0"
        Port "1f8b7066a427-net2"
            Interface "1f8b7066a427-net2"
                type: dpdkvhostuser
        Port "br0"
            Interface "br0"
                type: internal
        Port "1f8b7066a427-net1"
            Interface "1f8b7066a427-net1"
                type: dpdkvhostuser
    ovs_version: "2.10.0"
```

### D5. Launch testpmd

We will now jump inside the pod and transmit some traffic using DPDK testing tool `testpmd`:
```
[centos@kube-master-1 ~]$ kubectl exec -it multi-vhost-example bash
root@multi-vhost-example:/home# export ID=$(/home/get-prefix.sh)
root@multi-vhost-example:/home# testpmd \
    -d librte_pmd_virtio.so.17.11 \
    -l 2,3 \
    --file-prefix=testpmd_ \
    --vdev=net_virtio_user0,path=/vhu/${ID}/${ID:0:12}-net1 \
    --vdev=net_virtio_user1,path=/vhu/${ID}/${ID:0:12}-net2 \
    --no-pci \
    -- \
    --no-lsc-interrupt \
    --auto-start \
    --tx-first \
    --stats-period 1 \
    --disable-hw-vlan;

```
Depending on server's performance below testpmd results can vary:
```
Port statistics ====================================
  ######################## NIC statistics for port 0  ########################
  RX-packets: 8308640    RX-missed: 0          RX-bytes:  531752960
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 8276896    TX-errors: 0          TX-bytes:  529721344
 
  Throughput (since last show)
  Rx-pps:      2126428
  Tx-pps:      2123518
  ############################################################################
 
  ######################## NIC statistics for port 1  ########################
  RX-packets: 8276896    RX-missed: 0          RX-bytes:  529721344
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 8308672    TX-errors: 0          TX-bytes:  531755008
 
  Throughput (since last show)
  Rx-pps:      2123552
  Tx-pps:      2126429
  ############################################################################
```
Well done! You have successfully verified userspace cni plugin using OVS-DPDK interfaces.

***Tutorial session end here***

### VPP demo (Sorry, it is not included for this session)

In this tutorial, we will create the following:

![VPP Demo](images/Userspace_CNI_Demo.png)


On the host, the configuration for the Userspace CNI is as follows:
```
# cat /etc/alternate.net.d/90-userspace.conf
{
       "cniVersion": "0.3.1",
       "type": "userspace",
       "name": "memif-network",
       "host": {
               "engine": "vpp",
               "iftype": "memif",
               "netType": "bridge",
               "memif": {
                       "role": "master",
                       "mode": "ethernet"
               },
               "bridge": {
                       "bridgeId": 4
               }
       },
       "container": {
               "engine": "vpp",
               "iftype": "memif",
               "netType": "interface",
               "memif": {
                       "role": "slave",
                       "mode": "ethernet"
               }
       },
       "ipam": {
               "type": "host-local",
               "subnet": "192.168.210.0/24",
               "routes": [
                       { "dst": "0.0.0.0/0" }
               ]
       }
}
```

Based on this configuration data, the Userspace CNI will perform the following steps for each container that is spun up:
* Create a memif interface on the VPP instance on the host (which is a VM in this tutorial). 
* Create a bridge (if it doesn't already exist) on the VPP instance on the host and add the newly created memif interface to the bridge.
* Call the IPAM CNI to retrieve the container IP values.
* Write the container configuration and IPAM results structure to DB.

On container boot, an application in the container (vpp-app) will read the DB and create a memif interface in the container and add the IP settings to interface.

**NOTE:** This tutorial is using a local script to call and exercise the Userspace CNI. In a deployment scenario, the Userspace CNI is intended to run with Multus, which can add multiple interfaces into a container. Multus will handle adding the 'default network' in addition to the userspace interface shown here. The Userspace CNI currently works with Multus and Kubernetes but was omitted here for simplicity and keep the focus on Userspace CNI.

### C1. Setup workspace

For this tutorial, we are going to continue using the terminal window from the previous examples. However, for this tutorial we are going to act as root. Let's get that going.

```
sudo -i
```

### C2. Inspect host

Before the containers are started, lets look at the host. VPP is currently running on the host. Let's run a few commands and get the current state.
```
vppctl show interface
vppctl show mode
```

As we see, not much here. Once the containers are started, there should two `memif` interfaces, one for each container.


### C3. Start two containers using userspace CNI

Here we're going to use a helper script that will start each container one at a time.
```
curl -L https://tinyurl.com/ons2018-vppDemo-sh | bash
```

What is this script doing? It is calling `docker run ... docker.io/bmcfall/vpp-centos-userspace-cni:0.4.0` with lots of additional parameters. These parameters are used to map hugepages into the container, volume mount two directories to share socket files and DB files, name our containers `vppDemo_1` and `vppDemo_2`, etc. The script also monitors the `memif` interfaces on the host and makes sure they come up properly.


### C4. Use `vppctl` to show interfaces and properties of `vppDemo_1`

Cool, now we should have two containers running. Let's examine the configuration of the first container with `vppctl` commands.

```
docker exec vppDemo_1 vppctl show interface
docker exec vppDemo_1 vppctl show mode
docker exec vppDemo_1 vppctl show memif
```

You'll see that you have a `memif` available here.

Let's show the IP address here:

```
docker exec vppDemo_1 vppctl show interface addr
```

We will need to remember that IP address, so go ahead and copy that into your paste buffer. 


### C5. Use `vppctl` to show interfaces and properties of `vppDemo_2`

Repeat the same commands for the second container.

```
docker exec vppDemo_2 vppctl show interface
docker exec vppDemo_2 vppctl show mode
docker exec vppDemo_2 vppctl show memif
docker exec vppDemo_2 vppctl show interface addr
```

### C6. Revisit host

Now that the containers are up, lets look at the host again.
```
vppctl show interface
vppctl show mode
```

So we can see that the Userspace CNI created two `memif` interfaces on the host and added them to a local bridge.


### C7. Ping between the two containers

Now let's see if we can get a ping between them. In the container, VPP owns the `memif` interface, not the kernel. Therefore the `ping` needs to be initiated from VPP.
```
docker exec vppDemo_2 vppctl ping PASTE_THE_COPIED_IP_HERE repeat 5
```

On the host, if we show the interfaces again, we see tx and rx counts have incremented.
```
vppctl show interface
```

## Do it yourself!

You can create this own lab environment on your own -- we have instructions on how to create it available in [kube-ansible](https://github.com/redhat-nfvpe/kube-ansible/tree/dev/ons-tutorial/contrib) -- a suite of ansible playbooks to create a Kubernetes lab environment, and with steps that were used to create the lab which you've been using for this tutorial.

## Additional & Reference Materials
    * [Multus](https://github.com/Intel-Corp/multus-cni)
    * [Userspace CNI](https://github.com/intel/userspace-cni-network-plugin/)
    * [SRIOV Network Device Plugin](https://github.com/intel/sriov-network-device-plugin)
    * [SRIOV - DPDK CNI](https://github.com/intel/sriov-cni)
