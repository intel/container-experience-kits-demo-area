# Welcome to NFV Features in Kubernetes: A hands-on Tutorial!

Thanks for joining us at ONS Europe 2018 to try out some NFV features in Kubernetes. 

Agenda:

* Workstation setup
* Multus CNI
* SR-IOV Device Plugin (emulated)
* Userspace CNI
* Additional & Reference Materials

## Requirements

All you need is an SSH client. Please feel free to use whatever you have. If you'd like, you can use a [Chrome Extension for SSH](https://chrome.google.com/webstore/detail/secure-shell-app/pnhechapfaindjhompbnflcldabbghjo?hl=en).

## Workstation setup

Let's get setup to use our workstation! At each of your desks, you'll have a number. The speakers will provide you with a link to visit. Visit that link.

Here you'll be presented with a table with a number, use the SSH connection string as provided and you'll wind up on the machine. Do you notice that there's 2 SSH links? One is a backup in case you type `exit` -- generally, don't type `exit`! If you do by accident (or, more likely, out of habit), you can use the second one. 

First things first! Let's make a new tmux window.

```
ctrl+b [release the keys, then hit] c
```

This provides us a layer of redundancy in case someone types `exit`. Need more help with tmux? Try the [tmuxcheatsheet.com](https://tmuxcheatsheet.com/).

Now! Let's make sure that no one else is accidentally using our instance! We'll use the `wall` command to announce our name.

```
wall Hello this is My Name
```

Make sure to type your own name. If you see someone else's name appear -- let's figure out who used the wrong link.

Now! Let's make sure you can access the kubernetes cluster, let's list the available nodes...

```
kubectl get nodes
```

You should see the master and a node, and the `STATUS` should read `NotReady` -- this is where we want it, these nodes won't be ready until we install our pod-to-pod network. That's what's we're going to do next, let's roll!

## Multus CNI

### Core Concepts

* CRDs - Custom Resource Definitions
    - How we extend the Kubernetes API, and define custom configurations for each network/NIC we attach to our pods
* "Default network"
    - Our "default network" is the configuration that we use that is the default NIC attached to each and every pod in our cluster, typically this is used for pod-to-pod communication.

### A1. Inspecting the Multus daemonset-style installation

Inspect your work area, firstly, list your home directory, You'll see there's a `./multus-cni`. Move into that directory

```
ls -l
cd multus-cni
```

Typically, by default we setup using the "quick start guide" method, which deploys a YAML file with a daemonset and some CRDs.

Let's look at that file.

```
cat images/multus-daemonset.yml
```

Taking a look around, you'll see this is comprised of a few parts -- each between the `---` YAML delimiter.

* A CRD (Custom Resource Definition)
    - This defines how we'll extend the Kubernetes API with our custom configurations for how we'll setup each NIC attached to our pods.
* A cluster role, cluster role binding and service account
    - to give Multus permissions to access the Kubernetes API
* A config map
    - Currently unused, but to allow you to customize how Multus is configured
* A Daemonset
    - A way to define a pod that runs on each host in our cluster, in this case it is used to place our Multus binary and flat file configuration on each machine in the cluster.

### A2. Install Multus and the default network

Let's take this for a spin -- we'll deploy both the Multus Daemonset, and Flannel, which will be used for our "default network" -- 

```
cat ./images/{multus-daemonset.yml,flannel-daemonset.yml} | kubectl apply -f -
```

This is going to spin up a number of pods, let's watch it come up...

```
kubectl get pods --all-namespaces -w
```

Or if you don't like that format, you can use `watch` itself...

```
watch -n1 kubectl get pods --all-namespaces -o wide
```

### A3. Verify the installation of Multus & default network

Next, we can check that state of our nodes, once everything is running we should see that `STATUS` changes from `NotReady` to `Ready` -- 

```
kubectl get nodes
```

This state is determined by the Kubelet by looking for the precence of a CNI configuration in the CNI configuration directory -- by default this is `/etc/cni/net.d`, and this holds true for our configuration as well.

Let's take a look there.

```
cat /etc/cni/net.d/70-multus.conf
```

Looking at this configuration file, you'll see that there's a number of things configured here, for example:

* `delegates`: This defines our default network, in this case we "delegate" the work for the default network to Flannel, which we use in this scenario as a pod-to-pod network.
* `type`: This is a required CNI configuration field, and in each place that you see `type` that means that CNI is going to call the binary (by default in `/opt/cni/bin`) of the value of `type`, in this case the top level `type` is set to `multus` which is what we want to be called first -- then in the `delegates` section we have it the `type` set to `flannel`, in this case Multus is what calls this binary, and it will be the first binary called and always attached @ `eth0`.

### A4. Run a pod without additional interfaces

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

### A5. Create a new CNI configuration stored as a custom resource

Now, let's setup a custom network we'll attach as a second interface to a different pod.

```
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
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
    }'
EOF
```

What did we just do here? Remember how we looked at the `/etc/cni/net.d/70-multus.conf` -- that's a CNI configuration file. In that case we configured Multus itself. But, since Multus is a "meta plugin" and it calls other plugins, we're creating another different CNI plugin. In this case we created a configuration for using the `macvlan` plugin. 

Where does this get stored? You can look for it using the command line (or the Kubernetes API, as well)

Let's take a look:

```
kubectl get crds
```

Here we can see the over-arching namespace under which these configurations live, in this case our namespace is called `network-attachment-definitions.k8s.cni.cncf.io`. 

You can take a look and see what's available for custom resources created under that umbrella.

You can do that with:

```
kubectl get network-attachment-definitions.k8s.cni.cncf.io
```

Here we can see that `macvlan-conf` has been created. That's the name we gave it above. 

We can implement an attachment to this `macvlan-conf` configured network by referencing that name in an annotation in another pod. Let's create it. Take a look closely here and see that there is an `annotations` section -- in this case we call out the namespace under which it lives, and then the value of the name of the custom resource we just created, which reads as: `k8s.v1.cni.cncf.io/networks: macvlan-conf`

### A6. Create a pod with an additional interface

Let's move forward and create that pod:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: multipod
  annotations:
    k8s.v1.cni.cncf.io/networks: macvlan-conf
spec:
  containers:
  - name: multipod
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: dougbtv/centos-network
EOF
```

Watch the pod come up again...

```
kubectl get pods -w
```

### A7. Verify the interfaces available in the pod

And when it comes up, now we can take a look at the interfaces that were created and attached to that pod:

```
kubectl exec -it multipod -- ip -d a
```

Now we can see that there are three interfaces!

* A loopback
* `eth0` attached to our default network (flannel)
* `net1` attached to our macvlan network we just created.

## SR-IOV Device Plugin

We're going to explore the use of a device plugin for 

In this case -- we're emulating the experience using [virt-network-device-plugin](https://github.com/zshi-redhat/virt-network-device-plugin#quick-start). In reality you'll be using the [sriov-network-device-plugin](https://github.com/intel/sriov-network-device-plugin) when you go to plumb SR-IOV devices into your pods.

Due to hardware/space/etc constraints in this tutorial setting -- we couldn't have SR-IOV hardware available for everyone. So instead this `virt-network-device-plugin` uses `virtio` devices instead. Each of the nodes you're using is a virtual machine, and has an additional virtio device that can be used by this emulated SR-IOV device plugin.

### Core Concepts

* Scheduler awareness of hardware
  - The reason that you can't "just use a CNI plugin" is that, while it'll probably work for a one-off test in your lab -- in production, a CNI plugin alone doesn't have scheduler awareness. The device plugin gives you a way to tell the Kubernetes scheduler that there are resources available on a particular node.
* [ehost-device CNI plugin](https://github.com/zshi-redhat/ehost-device-cni)
  - This is an enhanced version of the [host-device](https://github.com/containernetworking/plugins/tree/master/plugins/main/host-device) reference CNI plugin that allows for IPAM (IP Address Management) to be used as well.
* Custom Kubernetes Build
  - This currently requires a patch that's in progress for Kubernetes. 
  - The cluster that you're currently using is based on a custom build of Kubernetes using this patch.
  - The patch is avaible [on GitHub](https://github.com/kubernetes/kubernetes/compare/master...dashpole:device_id#diff-bf28da68f62a8df6e99e447c4351122).
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

### B2. Setup pod affinity to run device plugin on master

```
kubectl taint node $HOSTNAME node-role.kubernetes.io/master:NoSchedule-
kubectl label nodes $HOSTNAME dedicated=master
```

Note that we're doing two things here:

1. We've removed a taint, this taint originally said: "Hey, please don't schedule pods on the Master".
2. We've added a label on the master.

Before you run the next command, take a close look at a couple lines here... It says: 

```
  nodeSelector:
    dedicated: master
```

This means that we're saying "Hey, choose a node that has this label `dedicated` and has the value `master`". This will let the virt-device-plugin run on the Master with the above removal of the taint.

### B3. Starting the device plugin

Now let's spin up the device plugin itself...

```
cat <<EOF | kubectl create -f -
kind: Pod
apiVersion: v1
metadata:
        name: virt-device-plugin
spec:
  nodeSelector:
    dedicated: master
  tolerations:
    - key: node-role.kubernetes.io/master
      operator: Equal
      value: master
      effect: NoSchedule
  containers:
  - name: virt-device-plugin
    image: virt-device-plugin
    imagePullPolicy: IfNotPresent
    command: [ "/usr/bin/virtdp", "-logtostderr", "-v", "10" ]
    # command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 300000; done;" ]
    #securityContext:
        #privileged: true
    volumeMounts:
    - mountPath: /var/lib/kubelet/device-plugins/
      name: devicesock
      readOnly: false
    - mountPath: /sys/class/net
      name: net
      readOnly: true
  volumes:
  - name: devicesock
    hostPath:
     # directory location on host
     path: /var/lib/kubelet/device-plugins/
  - name: net
    hostPath:
      path: /sys/class/net
  hostNetwork: true
  hostPID: true
EOF
```

Go ahead and list the pods on your cluster, we'll show which nodes they're running on...

```
kubectl get pods -o wide
```

You'll notice that there's a `NODE` value of `kube-master-1` for the `virt-device-plugin`. This means that our device plugin is only running on the master, and is only aware of hardware that's on the master.

### B4. Inspecting the discovered devices from the device plugin

Let's look at the logs of that pod...

```
kubectl logs virt-device-plugin
```

Look near the bottom of the logs for a line that reads `ListAndWatch` -- you'll see it picked up on two devices for us. Those devices will match what we see in `/sys/class/net`. Let's go ahead and list that for us, too.

```
ls -lathr /sys/class/net/
```

You'll notice that the PCI address in the `ListAndWatch` section matches the `eth1` listed above. In this case the `virt-network-device-plugin` has logic that says "Hey, by the way -- don't pick the default interface here".

Before you spin up this pod in this next command -- let's note that it *does not* have a `NodeSelector` -- this means that it could be scheduled to any node. Now with that in mind...

### B5. Creating a pod to use the device plugin

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

### B6. Inspecting the results of the pod using the device

Now we can exec in the pod and see it has plumbed our virtual device into the pod!

```
kubectl exec -it virtdevicepod1 -- ip -d a
```

You'll see two interfaces. `eth0` and `net1` -- where `net1` is the virtual device.

And check out that it's running on the proper node:

```
kubectl get pods -o wide
```

### B7. Review the resources available on the node

And you can find out more about the resources used with:

```
kubectl describe node $HOSTNAME | less
```

### B9. Create a pod that doesn't have a way to get scheduled.

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

## Userspace CNI

In this tutorial we will run the Userspace CNI. The Userspace CNI is used to add userspace networking interfaces to a container. Userspace networking interfaces require special handling because the interfaces are not owned by the kernel, so they cannot be added to a container through normal namespace provisioning. Work needs to be done on the host to created the interface in the local vSwitch, and work needs to be performed in the container to consume the interface. Even though the userspace interfaces require special handling, they are desired because running outside the kernel allows for some software optimizations that produce higher throughput at the cost of higher CPU usage.

The Userspace CNI supports both OVS-DPDK (http://www.openvswitch.org/) and VPP (https://fd.io/), which are both opensource userspace projects based on DPDK (https://www.dpdk.org/). This tutorial uses VPP as the vSwitch (see configuration below, Line 6), but Userspace CNI also supports OVS-DPDK.

![VPP Demo](images/Userspace_CNI_Demo.png)

On the host, the configuration for the Userspace CNI is as follows:
```
# cat /etc/alternate.net.d/90-userspace.conf
01 {
02        "cniVersion": "0.3.1",
03        "type": "userspace",
04        "name": "memif-network",
05        "host": {
06                "engine": "vpp",
07                "iftype": "memif",
08                "netType": "bridge",
09                "memif": {
10                        "role": "master",
11                        "mode": "ethernet"
12                },
13                "bridge": {
14                        "bridgeId": 4
15                }
16        },
17        "container": {
18                "engine": "vpp",
19                "iftype": "memif",
20                "netType": "interface",
21                "memif": {
22                        "role": "slave",
23                        "mode": "ethernet"
24                }
25        },
26        "ipam": {
27                "type": "host-local",
28                "subnet": "192.168.210.0/24",
29                "routes": [
30                        { "dst": "0.0.0.0/0" }
31                ]
32        }
33 }
```

Based on this configuration data, the Userspace CNI will perform the following steps for each container that is spun up:
* Create a memif interface on the VPP instance on the host (which is a VM in this tutorial). {Lines 7, 9-12}
* Create a bridge (if it doesn't already exist) on the VPP instance on the host and add the newly created memif interface to the bridge. {Lines 8,13-15}
* Call the IPAM CNI to retrieve the container IP values. {Lines 26-32}
* Write the container configuration and IPAM results structure to DB. {Lines 17-25, plus results from previous IPAM call}

On container boot, an application in the container (vpp-app) will read the DB and create a memif interface in the container and add the IP settings to interface.

NOTE: This tutorial is using a local script to call and exercise the Userspace CNI. In a deployment scenario, the Userspace CNI is intended to run with Multus, which can add multiple interfaces into a container. Multus will handle adding the 'default network' in addition to the userspace interface shown here. The Userspace CNI currently works with Multus and Kubernetes but was omitted here for simplicity and keep the focus on Userspace CNI.

### Core Concepts

* "Userspace networking"
    - Typical packet processing on a linux distribution occurs in the kernel. With "userspace networking", packet processing occurs in software outside the kernel. Software techniques such as processing a batch of packets at a time, poll driven instead of interupt driven, and data/instruction cache optimization can produce higher data rates than pure kernel packet processing.
* vhost-user
    - vhost-user is a protocol that is used to setup virtqueues on top of shared memory between two userspace processes on the same host. The vhost user protocol consists of a control path and a data path. Once data path is established, packets in the shared memory can be shared between the two userspace processes via a fast zero-copy.
    - In userspace networking, a vhost-user interface is created in two userspace processes (between host and vm, between host and container, between two different containers), a unix socket file is shared between them that is used to handshake on the virtual queues back by shared memory.
* memif
    - memif is a protocol similiar to vhost-user, a packet based shared memory interface for userspace processes. Where vhost-user was designed for packet processing between host and virtual machines, with host to guest memory pointer mapping. memif was not and skips this step. This and other optimizations makes memif faster than vhost-user for host to container or container to container packet processing.
    - In userspace networking, a memif interface is created in two userspace processes (between host and vm, between host and container, between two different containers), a unix socket file is shared between them that is used to handshake on the decriptor rings and packet buffers back by shared memory.

### C1. Setup workspace

First up, *let's open up two SSH connections to the same host*, use the backup SSH connection string -- or, even better -- If you want, use `tmux` to make a new screen (if you created a new screen in the beginning with `ctrl+b, c` then you can use `ctrl+b, p` to go to the preview screen, and keep using that to switch between them).

For this tutorial, we're going to act as root. Let's get that going.

```
sudo -i
```

Now, we'll move into our clone of the userspace CNI

```
cd src/go/src/github.com/Billy99/user-space-net-plugin/
```

Here we're going to use a helper script that is used during CNI development. Let's call it and get a container going.

### C2. Create the first container using userspace CNI

```
export CNI_PATH=/opt/cni/bin; \
  export NETCONFPATH=/etc/alternate.net.d/; \
  export GOPATH=/root/src/go/; \
  ./scripts/vpp-docker-run.sh -it --privileged docker.io/bmcfall/vpp-centos-userspace-cni:0.2.0
```

*NO PROMPT?* This will create a bunch of output -- go ahead an hit `enter` a few times to get a prompt.

*NOTE*: Having trouble? If you run into a situation where you have an error reported, try running the `vppctl show interface addr` command if an IP address is shown, you're good to go. If not -- you should just type `exit` to exit the container, and then run the above `vpp-docker-run.sh` script again.

```
[root@c25985f1fe78 /]# ERROR returned: failed to read Remote config: <nil>
[root@c25985f1fe78 /]# vppctl show interface addr
local0 (dn):
```

### C3. Use `vppctl` to show interfaces and properties

Cool, now you're in a running container -- let's list what we're seeing with `vppctl`.

```
vppctl show interface
vppctl show mode
vppctl show memif
```

You'll see that you have a `memif` available here.

Let's show the IP address here:

```
vppctl show interface addr
```

Go ahead and copy that into your paste buffer.

### C4. Create secondary container

**IN THE SECOND SCREEN** -- Now, let's create another container -- use the same method as before.

Make sure you're root, and in the proper directory:

```
cd src/go/src/github.com/Billy99/user-space-net-plugin/
```

Then create the container same as we did before:

```
export CNI_PATH=/opt/cni/bin; \
  export NETCONFPATH=/etc/alternate.net.d/; \
  export GOPATH=/root/src/go/; \
  ./scripts/vpp-docker-run.sh -it --privileged docker.io/bmcfall/vpp-centos-userspace-cni:0.2.0
```

Now get the IPs for each of the containers you have running in open windows, you can do so with:

```
vppctl show interface addr
```

Get them for both containers, and then ping one from another. Note that we're using `vppctl ping ...` because we're in userspace -- we can't just use plain old `ping`.

### C5. Ping between the two containers

Now let's see if we can get a ping between them:

```
vppctl ping PASTE_THE_COPIED_IP_HERE repeat 5
```

## Do it yourself!

You can create this own lab environment on your own -- we have instructions on how to create it available in [kube-ansible](https://github.com/redhat-nfvpe/kube-ansible/tree/dev/ons-tutorial/contrib) -- a suite of ansible playbooks to create a Kubernetes lab environment, and with steps that were used to create the lab which you've been using for this tutorial.

## Additional & Reference Materials

```
[ stub ]
```
