Preparing Kubernetes cluster using Kube-ansible
===================================================
`kube-ansible` is a set of Ansible playbooks and roles that allows
you to instantiate a vanilla Kubernetes cluster on (primarily) CentOS virtual
machines or baremetal.

Additionally, kube-ansible includes CNI pod networking (defaulting to Flannel,
with an ability to deploy Weave and Multus).

The purpose of kube-ansible is to provide a simpler lab environment that allows
prototyping and proof of concepts. For staging and production deployments, we
recommend that you utilize
[OpenShift-Ansible](https://github.com/openshift/openshift-ansible)

`kube-ansible` is developed by the [Red Hat NFVPE team](https://github.com/redhat-nfvpe), and customized ONS software setup is done by Red Hat NFVPE team - [ONS - Tutorial](https://github.com/redhat-nfvpe/kube-ansible/tree/dev/ons-tutorial)

**Users don't need to install any components, all work has been done by lab coordinator**
