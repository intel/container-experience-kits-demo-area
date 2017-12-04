## CPU Core Manager for Kubernetes (CMK)

CPU Manager for Kubernetes (CMK) performs a variety of operations to enable core pinning and isolation on a container or a thread level. These include
*	Discovering the CPU topology of the machine.
*	Advertising, via Kubernetes constructs, the resources available.
*	Placing workloads according to their requests. 
*	Keeping track of the current CPU allocations of the pods, ensuring that an application will receive the requested resources provided they are available

### Demo Installation with ansible script
1. Install CMK with ansible script ```k8s_run_cmk.yml``` in the folder [demo/software](https://github.com/intel/container-experience-kits-demo-area/blob/master/software)
```
sudo ansible-playbook -i inventory.ini k8s_run_cmk.yml
```
Developer's interested in manual installation for CMK, please refer the section [Manual Installation](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace/cmk/README.md#manual-installation-not-the-part-of-the-demo)

### Example usage

### Manual Installation (not the part of the demo)
1.	Installing CMK starts with cloning the following Intel GitHub link:
```
# git clone https://github.com/Intel-Corp/CPU-Manager-for-Kubernetes
```
2.	From inside the cloned repository the CMK Docker image is built:
```
# make
```
a.	Note: The CMK image needs to be available on each node in the Kubernetes cluster that will be consuming CMK 	
3.	CMK uses RBAC and service accounts for authorization. Deploy the following yaml files:
```
# kubectl create –f cmk-rbac-rules.yaml
# kubectl create –f cmk-serviceaccount.yaml
```
4.	Use the isolcpus boot parameter to ensure exclusive cores in CMK are not affected by other system tasks:
```
# isolcpus=0,1,2,3
```
*	On a hyper threaded system, fully isolate a core by isolating the hyper-thread siblings.
*	At a minimum, the number of fully isolated cores should be equal to the desired number of cores in the data plane pool.
*	CMK will work without the isolcpus set but does not guarantee isolation from system processes being scheduled on the exclusive data plane cores. 
5.	The recommended way to install CMK is through the cluster-init command deployed as part of a Kubernetes pod. Cluster-init creates two additional pods on each node where CMK is to be deployed. The first pod executes the init, install and discover CMK commands and the second deploys a daemonset to execute and keep alive the nodereport and reconcile CMK commands.

*	Cluster-init accepts a variety of command line configurations. An example cluster-init command:
```
# kubectl create –f resources/pods/cmk-cluster-init.yaml
# /cmk/cmk.py cluster-init --all-hosts
```
*	An example cluster-init pod specification can be found at: https://github.com/Intel-Corp/CPU-Manager-for-Kubernetes/blob/master/resources/pods/cmk-cluster-init-pod.yaml 
*	CMK can be deployed through calling the CMK commands individually if cluster-init fails. Information on this can be found at: https://github.com/Intel-Corp/CPU-Manager-for-Kubernetes/blob/master/docs/cli.md