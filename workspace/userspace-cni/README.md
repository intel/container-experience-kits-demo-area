## Userspace CNI

In this tutorial we will run the Userspace CNI. The Userspace CNI is used to add userspace networking interfaces to a container. Userspace networking interfaces require special handling because the interfaces are not owned by the kernel, so they cannot be added to a container through normal namespace provisioning. Work needs to be done on the host to created the interface in the local vSwitch, and work needs to be performed in the container to consume the interface. Even though the userspace interfaces require special handling, they are desired because running outside the kernel allows for some software optimizations that produce higher throughput at the cost of higher CPU usage.

The Userspace CNI supports both OVS-DPDK (http://www.openvswitch.org/) and VPP (https://fd.io/), which are both opensource userspace projects based on DPDK (https://www.dpdk.org/). This tutorial uses VPP as the vSwitch (see configuration below, Line 6), but Userspace CNI also supports OVS-DPDK.


In this tutorial, we will create the following:

![VPP Demo](../../demo/images/Userspace_CNI_Demo.png)


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
curl https://tinyurl.com/ons2018-vppDemo-sh | bash
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
