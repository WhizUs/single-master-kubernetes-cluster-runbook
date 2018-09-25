#ansible-playbook ./ansible-playbook/etcd-provisioning.yml -i ./inventory
#ansible-playbook ./ansible-playbook/kubernetes-master-provisioning.yml -i ./inventory -v
ansible-playbook ./ansible-playbook/kubernetes-worker-provisioning.yml -i ./inventory
