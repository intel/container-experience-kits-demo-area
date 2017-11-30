Preparing Kubernetes bare-metal nodes using Ansible
============================================

Ansible is a configuration management utility. 
Instructions in this readme have been tested with Ansible version 2.3.2.

Deploying Kubernetes without Proxy
--------------------
   1. Execute ansible-playbook

      ``ansible-playbook -i inventory.ini allinone.yml``

Deploying Kubernetes with Proxy
--------------------
   1. Under ``examples/`` there are two proxy files that can be utilized.

      1a. ``examples/proxy_example.yml`` extra_vars file which ansible will consume during deployment
        - copy to ansible directory as ``proxy.yml`` and modify accordingly

      2b. ``examples/proxy_env`` for local shell environment
        - copy to ansible directory as ``proxy_env`` and modify accordingly
          - ``no_proxy`` will be auto-populated with local sytem IP address

   2.  Execute ansible-playbook either:

       2a. With proxy already configured in environment

         ``ansible-playbook -i inventory.ini -e @proxy.yml allinone.yml``

       2b. Sourcing *proxy.env* file

         ``source proxy.env && ansible-playbook -i inventory.ini -e @proxy.yml allinone.yml``

Misc
---

   1. If missing, set **kubeconfig** environment variable

      ``export KUBECONFIG=/etc/kubernetes/admin.conf``

   2. Kubernetes status

      ``kubectl get pods --all-namespaces -o wide``

   3. Kubernetes pod stuck in ContainerCreating

      **note:** kube-dns can take a while to go into running state but if needed, delete the pod and kubernets will recreate it

      ``kubectl delete -n kube-system pods {name of pod}``
      
      ``kubectl delete -n kube-system pods kube-dns-545bc4bfd4-jh2xb``

