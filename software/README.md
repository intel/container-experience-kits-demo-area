Preparing Kubernetes bare-metal nodes using Ansible
===================================================

Ansible is a configuration management utility. 
Instructions in this readme have been tested with Ansible version 2.3.2.

Deploying Kubernetes without Proxy
----------------------------------
   1. Execute ansible-playbook: (IMPORTANT: Use ``-b`` switch to allow ansble to ``become user root``)

      ``$ sudo ansible-playbook -b -i inventory.ini allinone.yml``

Deploying Kubernetes with Proxy
-------------------------------
   1. Under ``examples/`` there are two proxy files that can be utilized.

      1a. ``examples/proxy_example.yml`` extra_vars file which ansible will consume during deployment
        - copy to ansible directory as ``proxy.yml`` and modify accordingly

      2b. ``examples/proxy_env`` for local shell environment
        - copy to ansible directory as ``proxy_env`` and modify accordingly
          - ``no_proxy`` will be auto-populated with local sytem IP address

   2.  Execute ansible-playbook either: (IMPORTANT: Use ``-b`` switch to allow ansble to ``become user root``)

       2a. With proxy already configured in environment

         ``$ sudo ansible-playbook -b -i inventory.ini -e @proxy.yml allinone.yml``

       2b. Sourcing *proxy.env* file

         ``$ source proxy.env && sudo -E ansible-playbook -b -i inventory.ini -e @proxy.yml allinone.yml``

Running Node Feature Discovery and CPU Manager for Kubernetes
-------------------------------------------------------------
   1. Running Node Feature Discovery (NFD): (IMPORTANT: Use ``-b`` switch to allow ansble to ``become user root``)

      1a. As shown in example above, without proxy:

      ``$ sudo ansible-playbook -b -i inventory.ini run_nfd.yml``

      1b. As shown in example above, with proxy

      ``$ source proxy.env && sudo -E ansible-playbook -b -i inventory.ini -e @proxy.yml run_nfd.yml``

   2. Running CPU Manager for Kubernetes (CMK): (IMPORTANT: Use ``-b`` switch to allow ansble to ``become user root``)

      2a. As shown in example above, without proxy:

      ``$ sudo ansible-playbook -b -i inventory.ini run_cmk.yml``

      2b. As shown in example above, with proxy:

      ``$ source proxy.env && sudo -E ansible-playbook -b -i inventory.ini -e @proxy.yml run_cmk.yml``


Misc
----

   1. If missing, set **kubeconfig** environment variable

      ``$ export KUBECONFIG=/etc/kubernetes/admin.conf``

   2. Kubernetes status

      ``$ sudo kubectl get pods --all-namespaces -o wide``

   3. Kubernetes pod stuck in ContainerCreating

      **note:** kube-dns can take a while to go into running state but if needed, delete the pod and kubernetes will recreate it

      ``$ sudo kubectl delete -n kube-system pods {name of pod}``
      
      ``$ sudo kubectl delete -n kube-system pods kube-dns-545bc4bfd4-jh2xb``

   4. Clean up NFD and CMK pods

      ``$ ansible-playbook -b -i inventory.ini clean_cmk.yml``

      ``$ ansible-playbook -b -i inventory.ini clean_nfd.yml``
