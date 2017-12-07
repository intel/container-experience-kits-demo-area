## Node Feature Discovery

Node Feature Discovery (NFD), a project in the Kubernetes incubator, discovers and advertises the hardware capabilities of a platform that are, in turn, used to facilitate intelligent scheduling of a workload. More information is in the NFD GitHub: https://github.com/kubernetes-incubator/node-feature-discovery

The current deployment mechanism of NFD is as a Kubernetes job, which spins up an NFD pod on all nodes of the cluster. This NFD pod discovers hardware capabilities on the node and advertises them through Kubernetes constructs called labels. More information on label structure used in NFD along with examples can be found later in this section.
NFD can currently detect features from a set of feature sources:
*	CPUID for Intel Architecture (IA) CPU details
*	Intel P-State driver
*	Network
One of the key capabilities detected by NFD is SR-IOV through the network feature source mentioned above.


### Demo Installation with ansible script
1. Look the current node labels
```
# sudo kubectl get nodes -o json | jq .items[].metadata.labels
{
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/os": "linux",
  "cmk.intel.com/cmk-node": "true",
  "kubernetes.io/hostname": "localhost",
  "node-role.kubernetes.io/master": ""
}
```
2. Install NFD with ansible script ```k8s_run_nfd.yml``` in the folder [demo/software](https://github.com/intel/container-experience-kits-demo-area/blob/master/software)
```
sudo ansible-playbook -b -i inventory.ini run_nfd.yml
```
Developer's interested in manual installation for NFD, please refer the section [Manual Installation](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace/nfd/README.md#manual-installation-not-the-part-of-the-demo)

### Example usage
1. Look the current node labels
```
# sudo kubectl get nodes -o json | jq .items[].metadata.labels
{
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/os": "linux",
  "kubernetes.io/hostname": "localhost",
  "node-role.kubernetes.io/master": "",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-AESNI": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-AVX": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-AVX2": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-CLMUL": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-CMOV": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-CX16": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-LZCNT": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-MMX": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-MMXEXT": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-NX": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-POPCNT": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-RDRAND": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-RDSEED": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-RDTSCP": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE2": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE3": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE4.1": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE4.2": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSSE3": "true",
  "node.alpha.kubernetes-incubator.io/node-feature-discovery.version": "v0.1.0"
}
```
2. Node affinity was introduced as alpha in Kubernetes 1.2. Node affinity is conceptually similar to nodeSelector – it allows you to constrain which nodes your pod is eligible to schedule on, based on labels on the node. Based on the NFD node labels `node.alpha.kubernetes-incubator.io/nfd-cpuid-AVX` schedule the pod. Since it is a single node, simple AVX feature is used for the example. The `with-node-affinity` pod should be scheduled in the single node
```
# cd ~/demo/workspace/nfd/
# sudo kubectl create -f ./nfd-affinity.yaml
# sudo kubectl get pods
NAME                 READY     STATUS    RESTARTS   AGE
with-node-affinity   1/1       Running   0          1m
```
3. There is no explicit “node anti-affinity” concept, but `NotIn` and `DoesNotExist` give that behavior. Use the same NFD node label `node.alpha.kubernetes-incubator.io/nfd-cpuid-AVX` and operator `DoesNotExist` to achieve the node anti-affinity. Pod should end up in the pending state with message `No nodes are available that match all of the predicates: MatchNodeSelector (1)`
```
# sudo kubectl get pods --show-all
NAME                           READY     STATUS      RESTARTS   AGE
node-feature-discovery-mztmc   0/1       Completed   0          16m
with-node-affinity             1/1       Running     0          9m
with-node-anti-affinity        0/1       Pending     0          13s
# sudo kubectl describe pod with-node-anti-affinity
Name:         with-node-anti-affinity
Namespace:    default
Node:         <none>
Labels:       <none>
Annotations:  <none>
Status:       Pending
IP:
Containers:
  with-node-anti-affinity:
    Image:        gcr.io/google_containers/pause:2.0
    Port:         <none>
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-wvszz (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  default-token-wvszz:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-wvszz
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.alpha.kubernetes.io/notReady:NoExecute for 300s
                 node.alpha.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  13s (x6 over 28s)  default-scheduler  No nodes are available that match all of the predicates: MatchNodeSelector (1).
```
4. Clean up NFD installation in K8s Cluster
``$ ansible-playbook -b -i inventory.ini clean_nfd.yml``

### Manual Installation (not the part of the demo)
1.	The steps involved in installing NFD by cloning the following GitHub link: 
```
https://github.com/kubernetes-incubator/node-feature-discovery
```
2.	Next, the directory should be changed to node-feature-discovery followed by running the make command to build the docker image which is subsequently used in the file node-feature-discovery-job.json.template:
```
# cd <project-root>
make
```
3.	Obtain the name of the image built in the previous step using:
```
# docker images 
```
4.	Push NFD image to the Docker Registry. In the commands below <docker registry> is the docker registry used in the Kubernetes cluster:
```
#docker tag <image name> <docker registry>/<image name> 
#docker push <docker registry>/<image name> 
```
5.	Edit the node-feature-discovery-job.json.template to change image node. To use the built image from the step above, run the following command:
```
...
"image": "<docker registry>/<image name>"..
```
6. With the set up done, NFD can now be run. Currently, NFD is deployed as a Kubernetes job and can be deployed using the script label-nodes.sh, which can be obtained from the aforementioned NFD GitHub repo. This script identifies the number of nodes in the Kubernetes cluster and creates the “node-feature discovery-job.json” file.  This file contains the Kubernetes job configuration and replaces placeholder variables from the template file with the number of discovered nodes. 
7.	Running this script automatically creates a “node-feature-discovery” job.
 ```
 # ./label-nodes.sh
  ```
The “node-feature-discovery” job runs pods on each node, and discovers the hardware capabilities of the node it is running on and assigns the proper labels to the node. 
8.	For verifying the correct execution of NFD, the labels assigned to the nodes can be viewed using the following command:
```
# kubectl get nodes -o json | jq .items[].metadata.labels
```
Example output of this command for single node looks like this:
```
{
  "node.alpha.kubernetes-incubator.io/node-feature-discovery.version": "a9af7ff-dirty",
  "node.alpha.kubernetes-incubator.io/nfd-pstate-turbo": "true",
  "node.alpha.kubernetes-incubator.io/nfd-network-SRIOV": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSSE3": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE4.2": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE4.1": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-SSE3": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-ERMS": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-F16C": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-HTT": "true",
  "node.alpha.kubernetes-incubator.io/nfd-cpuid-MMX": "true",
  }
```

