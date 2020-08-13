resource "exoscale_ssh_keypair" "kubernetes-cluster-runbook-ssh-key" {
  name       = "kubernetes-cluster-runbook-ssh-key"
  public_key = file("~/.ssh/kubernetes-cluster-ssh-key-rsa.pub")
}

resource "exoscale_affinity" "kubernetes-cluster-runbook-kubernetes-nodes" {
  name        = "kubernetes-cluster-runbook-kubernetes-nodes"
  description = "created by kubernetes-cluster-runbook - up to 8 kubernetes nodes are placed on different hypervisors"
  type        = "host anti-affinity"
}

# Create security group for ssh access nodes
resource "exoscale_security_group" "kubernetes-cluster-runbook-ssh-access-security-group" {
  name        = "kubernetes-cluster-runbook-ssh-access-security-group"
  description = "created by kubernetes-cluster-runbook - security group to access machines over ssh"
}

# Create security group for master nodes
resource "exoscale_security_group" "kubernetes-cluster-runbook-master-nodes-security-group" {
  name        = "kubernetes-cluster-runbook-master-nodes-security-group"
  description = "created by kubernetes-cluster-runbook - opens necessary ports for kubernetes master nodes"
}

# Create a security group for worker nodes
resource "exoscale_security_group" "kubernetes-cluster-runbook-worker-nodes-security-group" {
  name        = "kubernetes-cluster-runbook-worker-nodes-security-group"
  description = "created by kubernetes-cluster-runbook - opens necessary ports for kubernetes worker nodes"
}

# Create a security group for etcd nodes
resource "exoscale_security_group" "kubernetes-cluster-runbook-etcd-nodes-security-group" {
  name        = "kubernetes-cluster-runbook-etcd-nodes-security-group"
  description = "created by kubernetes-cluster-runbook - opens necessary ports for etcd nodes"
}

# Create a security group for calico network
resource "exoscale_security_group" "kubernetes-cluster-runbook-calico-network-security-group" {
  name        = "kubernetes-cluster-runbook-calico-network-security-group"
  description = "created by kubernetes-cluster-runbook - opens necessary ports to enable calico networking"
}

# Create a security group for http(s) access
resource "exoscale_security_group" "kubernetes-cluster-runbook-http-security-group" {
  name        = "kubernetes-cluster-runbook-http-security-group"
  description = "created by kubernetes-cluster-runbook - allow http/s access"
}

resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-ssh-access-security-group-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-ssh-access-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 22
  end_port          = 22
}

# Check ports are needed for master nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-master-nodes-security-group-api-server-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-master-nodes-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 6443
  end_port          = 6443
}

# Check ports are needed for master nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-master-nodes-security-group-master-service-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-master-nodes-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 10250
  end_port          = 10252
}

# Check ports are needed for worker nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-worker-nodes-security-group-kubelet-api-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-worker-nodes-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 10250
  end_port          = 10250
}

# Check ports are needed for worker nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-worker-nodes-security-group-nodeports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-worker-nodes-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 30000
  end_port          = 32767
}

# Check ports are needed for etcd nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-etcd-nodes-security-group-client-api-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-etcd-nodes-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 2379
  end_port          = 2380
}

# Check ports are needed for calico network: 
# https://docs.projectcalico.org/v3.5/getting-started/kubernetes/requirements
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-calico-network-security-group-bgp-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-calico-network-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 179
  end_port          = 179
}

# Check ports are needed for calico network: 
# https://docs.projectcalico.org/v3.5/getting-started/kubernetes/requirements
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-calico-network-security-group-ipip-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-calico-network-security-group.id
  protocol          = "IPIP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
}

# Check ports are needed for calico network: 
# https://docs.projectcalico.org/v3.5/getting-started/kubernetes/requirements
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-calico-network-security-group-typha-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-calico-network-security-group.id
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 5473
  end_port          = 5473
}

# Check ports are needed for calico network: 
# https://docs.projectcalico.org/v3.5/getting-started/kubernetes/requirements
resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-calico-network-security-group-flannel-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-calico-network-security-group.id
  protocol          = "UDP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 4789
  end_port          = 4789
}

resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-http-security-group-http-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-http-security-group.id
  protocol          = "UDP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

resource "exoscale_security_group_rule" "kubernetes-cluster-runbook-http-security-group-https-ports" {
  security_group_id = exoscale_security_group.kubernetes-cluster-runbook-http-security-group.id
  protocol          = "UDP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 443
  end_port          = 443
}

# Creates 1 Kubernetes master nodes (using ubuntu template)
resource "exoscale_compute" "kubernetes-cluster-runbook-master-nodes" {
  display_name    = "kubernetes-cluster-runbook-master-node0${count.index}"
  zone            = "at-vie-1"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Large"
  disk_size       = 50
  ip6             = false
  key_pair        = exoscale_ssh_keypair.kubernetes-cluster-runbook-ssh-key.id
  security_groups = ["${exoscale_security_group.kubernetes-cluster-runbook-calico-network-security-group.name}", "${exoscale_security_group.kubernetes-cluster-runbook-etcd-nodes-security-group.name}", "${exoscale_security_group.kubernetes-cluster-runbook-http-security-group.name}", "${exoscale_security_group.kubernetes-cluster-runbook-master-nodes-security-group.name}", "${exoscale_security_group.kubernetes-cluster-runbook-ssh-access-security-group.name}"]
  affinity_groups = ["${exoscale_affinity.kubernetes-cluster-runbook-kubernetes-nodes.name}"]
  state           = "Running"

  tags {
    env                        = "production"
    kubernetes-cluster-runbook = "kubernetes-master"
  }

  count = 1
}

# Create 3 Kubernetes worker nodes (using ubuntu template)
resource "exoscale_compute" "kubernetes-cluster-runbook-worker-nodes" {
  display_name    = "kubernetes-cluster-runbook-worker-node0${count.index}"
  zone            = "at-vie-1"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Large"
  disk_size       = 50
  ip6             = false
  key_pair        = exoscale_ssh_keypair.kubernetes-cluster-runbook-ssh-key.id
  security_groups = ["${exoscale_security_group.kubernetes-cluster-runbook-calico-network-security-group.name}", "${exoscale_security_group.kubernetes-cluster-runbook-worker-nodes-security-group.name}", "${exoscale_security_group.kubernetes-cluster-runbook-ssh-access-security-group.name}"]
  affinity_groups = ["${exoscale_affinity.kubernetes-cluster-runbook-kubernetes-nodes.name}"]
  state           = "Running"

  tags {
    env                        = "production"
    kubernetes-cluster-runbook = "kubernetes-worker"
  }

  count = 3
}

# Template for ansible inventory
data "template_file" "kubernetes-cluster-runbook-ansible-inventory" {
  template = "${file("ansible-inventory.tpl")}"

  vars {
    kubernetes_master_node00_ip = "${exoscale_compute.kubernetes-cluster-runbook-master-nodes.*.ip_address[0]}"
    kubernetes_worker_node00_ip = "${exoscale_compute.kubernetes-cluster-runbook-worker-nodes.*.ip_address[0]}"
    kubernetes_worker_node01_ip = "${exoscale_compute.kubernetes-cluster-runbook-worker-nodes.*.ip_address[1]}"
    kubernetes_worker_node02_ip = "${exoscale_compute.kubernetes-cluster-runbook-worker-nodes.*.ip_address[2]}"
  }
}

# Create inventory file
resource "null_resource" "kubernetes-cluster-runbook-create-ansible-inventory" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    template = data.template_file.kubernetes-cluster-runbook-ansible-inventory.rendered
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.kubernetes-cluster-runbook-ansible-inventory.rendered}\" > inventory"
  }
}
