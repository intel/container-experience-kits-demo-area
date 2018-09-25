## MULTUS CNI plugin

- *Multus* is the latin word for “Multi”
- Multus is a container network interface (CNI) plugin specifically designed to provide support for multiple networking interfaces in a Kubernetes environment.

<p align="center">
   <img src="../../docs/images/multus-workflow.JPG" width="1008" />
</p>

- Figure above shows the network control flow with Multus. 
- When Multus is invoked, it recovers pod annotations related to Multus, in turn, then it uses these annotations to recover a Kubernetes custom resource definition (CRD), which is an object that informs which plugins to invoke and the configuration needing to be passed to them. The order of plugin invocation is important as is the identity of the master plugin.
- In the figure, we see the benefit in a virtual firewall (vFW) use case.
-- By using the [SRIOV CNI plugin](https://github.com/intel/sriov-cni) in DPDK mode, the vFW can get full-speed line rate packet interfaces to the networks on which it is expected to perform its function. Additionally, there exists the management and control eth0 interface, which is available for control of the vFW itself and also possibly other functions, such as logging whose job may be to scrape the vFW logs and export via the management network interface to a centralized logging service. 

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
