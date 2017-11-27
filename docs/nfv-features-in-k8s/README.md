## Introduction
Intel has been working with partners and with open source communities to address networking-related  barriers in the adoption of commercial containers, and to uncover the power of Intel Architecture-based servers to improve configuration, manageability, performance, service-assurance, and resilience of container deployments.

Kubernetes is one of the leading open source container orchestration engines. However, native Kubernetes deployment provides only limited networking and platform awareness capabilities. Intel has made contributions to Kubernetes ecosystem by introducing new capabilities such as  multiple network interfaces support, Single Root Input Output Virtualization (SR-IOV) support to enhance the applicability towards Network Function Virtualization (NFV) based deployments. These were conceived to make Kubernetes-based deployments ready for high performance Virtual Network Functions (VNF) and to be production ready for cloud and communications service providers.

New Networking capabilities contributions include :
*	MULTUS-CNI provides multiple network interfaces to pods
*	SRIOV-CNI and DPDK-SRIOV-CNI introducing idea of physical and virtual functions
*	Huge page support, added to be native in Kubernetes 1.8, that enables the discovery, scheduling and allocation of huge pages as a native first-class resource
*	CPU Manager for Kubernetes (CMK) provides a mechanism for CPU pinning and isolation of containerized workloads
*	Node Feature Discovery (NFD) enables Xeon server hardware capability discovery in Kubernetes
*	Vhostuser CNI plugin enabled with Mutus-CNI plugin enhancing networking and dataplane acceleration.

## Baremetal Container Model
To help developers adopt and utilize these advanced networking technologies, Intel integrated all the new features on Intel platform.  The integrated solution is refered as  container bare-metal reference architecture. This  reference architecture represents a baseline configuration of components that are optimized to achieve optimal system performance for Software-Defined Networking/Network Functions Virtualization (SDN/NFV)  for containe based applications

The intended audience of this demo is system architects, developers and engineers that are involved in developing, testing or deploying NFV workloads in a Kubernetes environment. The aim of this demo is showcase a hardware and software combination on a bare metal configuration. The content includes a high-level overview on the architecture, setup, configuration,  provisioning procedures, and a set of baseline performance data.

This demo kit identifies those scripts and the hardware and software needed for correct operation. The summarizes the software configuration and data flows explored in this repo[link]. MULTUS, NFD, and CMK are deployed in one node using the Ansible scripts provided in this [link]. 

**Using the USB stick you can install the Kubernetes with Mutlus, NFD and CMK in your laptop**
**In order to overcome the hardware limitation during the demo, we provided the SRIOV - DPDK CNI features as a video demo here**

### Bare metal container Set up details

Kubernetes pods, testpmd in this case, can now take advantage of multiple network interfaces, bound by DPDK associated with SR-IOV physical functions (PFs) on the host for dedicated bi-directional data traffic, all while Flannel manages the primary pod network interface (eno2). CMK then provides deterministic performance by isolating cores and pinning high piority (testpmd) workloads to those isolated cores.
 

#### Kubernetes

Kubernetes is an open source platform that automates, deploys, maintains, scales Linux container operations. Kubernetes gives you the orchestation and scaling capabilities between multiple nodes. The default pod network utilized is Flannel with Virtual Extensible LAN (VXLAN), which is a layer 3 IPv4 network that provides networking between multiples nodes in a cluster.  More information on Kubernetes can be found at Kubernetes site https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/.

More information on Flannel can be found at the Flannel site https://github.com/coreos/flannel.

#### Kubeadm – Creating a Kubernetes Cluster
Kubeadm is an experimental multi-node Kubernetes installer. Currently Kubeadm is limited to a single master, but supports multiple minions. Kubeadm helps simplify installing a secure Kubernetes cluster on your system along with deploying a pod network for application component communication. Ansible utilizes Kubeadm to deploy a Kubernetes cluster. All kubectl commands are run on the Kubernetes Master.

More information on Kubeadm can be found at the Kubernetes site https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/.

#### Container Networking Interface (CNI)
Container Networking Interface (CNI) consists of specifications and libraries for writing plugins to configure network interfaces in Linux containers. For this Reference Architecture, Kubernetes will utilize two key CNI plugins, SR-IOV-CNI & MULTUS-CNI (sections below), enhancing the pod’s network capabilities in additional to the default flannel. 
Kubernetes also requires the standard CNI lo plugin and any required plugins referenced by configuration –cni-confi-dir (/etc/cni/net.d) must be present in –cni-bin-dir (/opt/cni/bin).

More information on CNIs can be found at the container networking Github: https://github.com/containernetworking/cni.

#### Data Plane Development Kit (DPDK)
DPDK is a set of open source libraries and drivers for fast packet processing. It was first designed to run on Intel Architecture processors, but is now an open source standard that supports other processors including IBM POWER and ARM. DPDK is an Open Source BSD licensed project. The most recent patches and enhancements, provided by the community, are available in the master branch (http://dpdk.org/browse/dpdk/log/). 

More information on DPDK can be found on the DPDK website: http://dpdk.org.

## Multus CNI

Kubernetes natively supports only a single network interface, however it's possible to implement multiple network interfaces using Multus. With Multus, other CNI plugins can create network connections. Multus is a CNI proxy and arbiter of other CNI plugins. It invokes other CNI plugins for network interface creation. When Multus is used, a master plugin (flannel, Calico, weave) is identified to manage the primary network interface (eno2) for the pod and it is returned to Kubernetes. Other CNI minion plugins (SR-IOV, vHost CNI, etc.) can create additional pod interfaces (net0, net1, etc.) during their normal instantiation process. 

More information can be found in Application Note #3

Source code for MULTUS-CNI: https://github.com/Intel-Corp/multus-cni. 

## SRIOV - CNI and DPDK-SRIOV CNI

SR-IOV introduces the concept of virtual functions (VFs) that represent a regular PCIe physical function (PF) to a VNF.   In Kubernetes, SR-IOV is implemented by utilizing an SR-IOV CNI plugin that lets the pod attach directly to the VF. Now, multiple containers within a Kubernetes pod can each have access to their own Ethernet VF. Each VFs can be treated as a separate physical NIC and configured with separate MAC, VLAN and IP, etc. That VF gets mapped to a specific physical Ethernet port. Additional capabilities with SRIOV allows binding the VF to DPDK bound driver i.e vfio_pci when a pod is instantiated. As a result, performance is vastly improved as packets move directly between the NIC and the pod.

More information can be found in Application Note #3

Source code for SRIOV-CNI: https://github.com/Intel-Corp/sriov-cni.

## Node feature discovery

Node Feature Discovery (NFD), a project in the Kubernetes incubator, discovers and advertises hardware capabilities of a platform which are, in turn, used to facilitate intelligent scheduling of a workload. The NFD script launches a job that deploys a single pod on each node (labeled or unlabeled) in the cluster. NFD can be run on labeled nodes to detect additional features that might have been introduced at a later stage e.g. introduction of an SR-IOV capable NIC to the node. When each pod runs, it connects the Kubernetes API server to add labels to the node.

More information can be found in Application Note #2

Source code for NFD: https://github.com/Intel-Corp/node-feature-discovery

## CMK

CMK is a tool for managing core pinning and isolation in Kubernetes. CMK creates core isolation by applying CPU masks, which represent cores on which the workload can be executed. The core availability state is maintained in a host file system that incorporates a system lock to avoid any conflicts. This core state is structured as a directory hierarchy where pools are represented as directories where workloads can acquire slots. These slots represent physical allocable cores in the form of a list of their logical core IDs. These pools can be exclusive, where only one workload can run per slot, or shared. The slot directory keeps track of the processes that have acquired the slot through process IDs. When a workload has completed its task, CMK will enforce the directory system lock and remove that workload's process ID from the relevant slot in order to free the core for another workload to use. In a case when the CMK program is unable to clean up the process IDs due to being killed or terminated unexpectedly, a periodic process is run to act as garbage collection. This process removes process IDs of workloads no longer running from slots to free up cores. 

# Performance figures
