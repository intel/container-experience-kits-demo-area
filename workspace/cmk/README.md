## CPU Core Manager for Kubernetes (CMK)

CPU Manager for Kubernetes (CMK) performs a variety of operations to enable core pinning and isolation on a container or a thread level. These include
*	Discovering the CPU topology of the machine.
*	Advertising, via Kubernetes constructs, the resources available.
*	Placing workloads according to their requests. 
*	Keeping track of the current CPU allocations of the pods, ensuring that an application will receive the requested resources provided they are available

### Demo Installation with ansible script
1. Install CMK with ansible script ```k8s_run_cmk.yml``` in the folder [demo/software](https://github.com/intel/container-experience-kits-demo-area/blob/master/software)
```
sudo ansible-playbook -b -i inventory.ini run_cmk.yml
```
Developer's interested in manual installation for CMK, please refer the section [Manual Installation](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace/cmk/README.md#manual-installation-not-the-part-of-the-demo)

### Example usage
1. Get the CMK node report ```localhost```
```
# sudo kubectl get cmk-nodereport localhost -o yaml
apiVersion: intel.com/v1
kind: Cmk-nodereport
metadata:
  clusterName: ""
  creationTimestamp: 2017-12-03T23:52:19Z
  deletionGracePeriodSeconds: null
  deletionTimestamp: null
  name: localhost
  namespace: default
  resourceVersion: "2254"
  selfLink: /apis/intel.com/v1/namespaces/default/cmk-nodereports/localhost
  uid: ff6ac4c3-d884-11e7-bee7-080027e90f8a
spec:
  report:
    checks:
      configDirectory:
        errors: []
        ok: true
    description:
      path: /etc/cmk
      pools:
        controlplane:
          cpuLists:
            "1":
              cpus: "1"
              tasks: []
          exclusive: false
          name: controlplane
        dataplane:
          cpuLists:
            "0":
              cpus: "0"
              tasks: []
          exclusive: true
          name: dataplane
        infra:
          cpuLists:
            "2":
              cpus: "2"
              tasks:
              - 8858
              - 8914
          exclusive: false
          name: infra
    topology:
      sockets:
        "0":
          cores:
          - cpus:
            - id: 0
              isolated: false
            id: 0
          - cpus:
            - id: 1
              isolated: false
            id: 1
          - cpus:
            - id: 2
              isolated: false
            id: 2
          id: 0
```
2. Create the ng-stress docker image
```
# cd ~/demo/workspace/cmk/ng-stress/
# docker build -t stress-ng .
```
3. Run the ng-stress pod withoug CMK CPU isolation and check the CPU utilization in the htop
```
# sudo kubectl create -f ./ng-stress-pod.yaml
pod "cpupodstress" created
# htop
```
* The ```htop``` show 100 % utilization in all CPUs.
3. Run the ng-stress pod with CMK CPU isolation and check the CPU utilization in the htop
```
# sudo kubectl create -f ./cmk-ng-stress-pod.yaml
```
4.  The ```htop``` show only 100 % utilization in one CPU.
5. Checking the isolated CPU pinning PID
```
# sudo kubectl get cmk-nodereport localhost -o yaml
apiVersion: intel.com/v1
kind: Cmk-nodereport
metadata:
  clusterName: ""
  creationTimestamp: 2017-12-03T23:59:28Z
  deletionGracePeriodSeconds: null
  deletionTimestamp: null
  name: localhost
  namespace: default
  resourceVersion: "3087"
  selfLink: /apis/intel.com/v1/namespaces/default/cmk-nodereports/localhost
  uid: ff64b506-d885-11e7-bee7-080027e90f8a
spec:
  report:
    checks:
      configDirectory:
        errors: []
        ok: true
    description:
      path: /etc/cmk
      pools:
        controlplane:
          cpuLists:
            "1":
              cpus: "1"
              tasks: []
          exclusive: false
          name: controlplane
        dataplane:
          cpuLists:
            "0":
              cpus: "0"
              tasks:
              - 12258
          exclusive: true
          name: dataplane
        infra:
          cpuLists:
            "2":
              cpus: "2"
              tasks:
              - 8858
              - 8914
          exclusive: false
          name: infra
    topology:
      sockets:
        "0":
          cores:
          - cpus:
            - id: 0
              isolated: false
            id: 0
          - cpus:
            - id: 1
              isolated: false
            id: 1
          - cpus:
            - id: 2
              isolated: false
            id: 2
          id: 0
```
```
# ps aux | grep 12258
root     12258  0.0  1.7 192072 36312 ?        S    Dec03   0:00 /opt/bin/cmk isolate --conf-dir=/etc/cmk --pool=dataplane stress-ng --matrix 0 --matrix-size 512
```
4. Clean up CMK installation in K8s Cluster
``$ ansible-playbook -b -i inventory.ini clean_cmk.yml``

## Troubleshooting

1. To clean the taint, please run the following command.
```
sudo kubectl taint nodes --all cmk-
```

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
