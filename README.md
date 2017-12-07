# Introduction

This tutorial will be a demo for a number of technologies for enabling NFV features in Kubernetes. 

For all requirements for the hands-on session checks the pre-requisites folder. The audience will be provided with a USB stick with all open source software installation in a single script. Please check with the lab co-ordinators during the session to get the USB stick. Else, please follow the instruction in the pre-requisites and download the required software on your own and prepare all of the prerequisites. Co-ordinators will help you with the software installation.

Abstract details as follows:

> _*"Network Orchestration using Containers and Kubernetes, are being considered by Communication Service Providers for next-gen cloud-based network deployments. While these technologies have been around and deployed for years now, more needs to be done in order to allow managed, performant and predictable service delivery, as required by Communication Service Providers. Intel has been working with partners and with open source communities to address those requirements and to deliver consumable capabilities and performance by enabling NFV Features in Kubernetes."*_

Through this hands-on lab session,  you will learn about Intel’s Container Bare Metal Experience Kits, the new capabilities introduced by Intel and Kubernetes features that will enable you to develop NFV use cases in Container-bare-metal deployments

Get the presentation [slide - deck](https://www.slideshare.net/KuralamudhanRamakris/enabling-nfv-features-in-kubernetes-83572884)


Table of Contents
=================

   * [USB Stick content details](https://github.com/intel/container-experience-kits-demo-area/blob/master/usb-stick/README.md#introduction)
      * [VM Set-up](https://github.com/intel/container-experience-kits-demo-area/blob/master/usb-stick/README.md#automated)
   * [Demo Instruction](https://github.com/intel/container-experience-kits-demo-area/tree/master/workspace#demo-instruction)
   * [Ansible Script](https://github.com/intel/container-experience-kits-demo-area/blob/master/software/README.md#introduction)
      * [All in one script](https://github.com/intel/container-experience-kits-demo-area/blob/master/software/README.md#installation)
   * [NFV Features in Kubernetes](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#introduction)
      * [Baremetal container model](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#baremetal-container-model)
      * [Node features Discovery](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#node-feature-discovery)
      * [CMK](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#cmk)
      * [Multus](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#multus-cni)
      * [SRIOV video Demo](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#sriov-cni)
      * [Performance Benchmarking Result](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/nfv-features-in-k8s/README.md#performance-figures)
   * [Container Exp kits details](https://github.com/intel/container-experience-kits-demo-area/blob/master/docs/exp-kits/README.md#introduction)
   * [Contacts](#contacts)

## <a name="help"></a>Need assistance

If you have any questions about, feedback on Intel's container exp kit:

- Read [Containers Experience Kits - will be updated soon](https://networkbuilders.intel.com/network-technologies/container-experience-kits).
- Invite yourself to the <a href="https://intel-corp.herokuapp.com/" target="_blank"> #intel-dnsg-slack</a> slack channel.
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
    * [SRIOV - DPDK CNI](https://github.com/Intel-Corp/sriov-cni)
    * [Vhostuser - VPP & OVS - DPDK CNI](https://github.com/intel/vhost-user-net-plugin)
    * [Node Feature Discovery](https://github.com/kubernetes-incubator/node-feature-discovery)
    * [CPU Manager for Kubernetes](https://github.com/Intel-Corp/CPU-Manager-for-Kubernetes)

## Contacts
For any questions, please reach out on github issue or feel free to contact @ivan and @kural in our [Intel-Corp Slack](https://intel-corp.herokuapp.com/)

