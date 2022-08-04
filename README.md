DISCONTINUATION OF PROJECT.

This project will no longer be maintained by Intel.

Intel has ceased development and contributions including, but not limited to, maintenance, bug fixes, new releases, or updates, to this project. 

Intel no longer accepts patches to this project.

If you have an ongoing need to use this project, are interested in independently developing it, or would like to maintain patches for the open source software community, please create your own fork of this project. 
# Introduction

This tutorial will be a demo for a number of technologies for enabling NFV features in Kubernetes. 

For all requirements for the hands-on session checks the table of contents below. The audience will be provided with a SSH connection to work on the virutal env. Please check with the lab co-ordinators during the session for the assistances.

Abstract details as follows:

> _*"In this tutorial, you will get to put your hands on the keyboard and spin up a Kubernetes environment and enable some NFV features that can be used today. This includes Kubernetes Networking and computing features.
The Kubernetes world is often focused on web-scale problems -- in the NFV world (and the high performance networking world-at-large) we have a lot of problems to solve that aren’t just simply “a single interface with HTTPS traffic”. You'll have a walkthrough to get a Kubernetes cluster up, and look into attaching multiple network interfaces to pods using Multus CNI, - a CNI plugin that allows you to attach multiple network interfaces to your Kubernetes pods and have an introduction on using SR-IOV from pods. You'll be introduced to a number of tools to get you equipped enough to get involved in the open source community in which these tools are being developed."*_

Through this hands-on lab session,  you will learn about Intel’s Container Bare Metal Experience Kits, and Kubernetes features that will enable you to develop NFV use cases in Container-bare-metal deployments

Get the presentation [slide - deck](https://www.slideshare.net/KuralamudhanRamakris/enabling-nfv-features-in-kubernetes-83923352)


Table of Contents
=================

   * [Demo Instruction](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace#demo-instruction)
   * [Baremetal container model](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#baremetal-container-model)
   * [NFV Features in Kubernetes](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#introduction)
   * Kubernetes Network
      * [Multus CNI](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace/multus#multus-cni-plugin)
      * [Userspace CNI](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace/userspace-cni#userspace-cni)
      * [SRIOV Network Device plugin(Emulated)](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace/sriov-network-dp#sr-iov-network-device-plugin)
        * [SRIOV CNI](https://github.com/intel/container-experience-kits-demo-area/tree/master/docs/nfv-features-in-k8s#sriov---cni-and-dpdk-sriov-cni)
   * Kubernetes Compute(Will not be covered in the session)
      * [CPU Manager for K8s](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#cmk)
      * [NUMA Manager](https://github.com/kubernetes/community/pull/1680)
      * [QAT](https://github.com/intel/intel-device-plugins-for-kubernetes/blob/master/cmd/qat_plugin/README.md#build-and-test-intel-quickassist-technology-qat-device-plugin-for-kubernetes)
      * [Node features Discovery](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#node-feature-discovery)
      * [Performance Benchmarking Result](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#performance-figures)
   * [Container Exp kits details](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/exp-kits/README.md#introduction)
   * [Kube Ansible Script](https://github.com/intel/container-experience-kits-demo-area/blob/master/software/README.md#introduction)
   * [Contacts](#contacts)

## <a name="help"></a>Need assistance

If you have any questions about, feedback on Intel's container exp kit:

- Read [Containers Experience Kits - will be updated soon](https://networkbuilders.intel.com/network-technologies/container-experience-kits).
- Invite yourself to the <a href="https://intel-corp.herokuapp.com/" target="_blank"> #intel-corp-slack</a> slack channel.
- Ask a question on the <a href="https://intel-corp-team.slack.com/messages/C4C5RSEER"> #general-discussion</a> slack channel.
- Need more assistant<a href="mailto:kuralamudhan.ramakrishnan@intel.com"> email us</a>
- Feel free to <a href="https://github.com/intel/container-experience-kits-demo-area/issues/new">file an issue.</a>

Please fill in the Questions/feedback -  [google-form](https://goo.gl/forms/iMAvaq8wDY33azlh1)!

## Further Information

* Feature brief
    * [Multiple Network Interface Support in Kubernetes ](https://builders.intel.com/docs/networkbuilders/multiple-network-interfaces-support-in-kubernetes-feature-brief.pdf)
    * [Enhanced Platform Awareness in Kubernetes](https://builders.intel.com/docs/networkbuilders/enhanced-platform-awareness-feature-brief.pdf)
* Application note
    * [Multiple Network Interfaces in Kubernetes and Container Bare Metal ](https://builders.intel.com/docs/networkbuilders/multiple-network-interfaces-in-kubernetes-application-note.pdf)
    * [Enhanced Platform Awareness Features in Kubernetes ](https://builders.intel.com/docs/networkbuilders/enhanced-platform-awareness-in-kubernetes-application-note.pdf)
* Project github pages
    * [Multus](https://github.com/Intel-Corp/multus-cni)
    * [Userspace CNI](https://github.com/intel/userspace-cni-network-plugin/)
    * [SRIOV Network Device Plugin](https://github.com/intel/sriov-network-device-plugin)
    * [SRIOV - DPDK CNI](https://github.com/intel/sriov-cni)
    * [Node Feature Discovery](https://github.com/kubernetes-incubator/node-feature-discovery)
    * [CPU Manager for Kubernetes](https://github.com/Intel-Corp/CPU-Manager-for-Kubernetes)

## Contacts
For any questions, please reach out on github issue or feel free to contact @ivan and @kural in our [Intel-Corp Slack](https://intel-corp.herokuapp.com/)

