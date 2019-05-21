resource "exoscale_ssh_keypair" "kubernetes-cluster-ssh-key" {
  name       = "kubernetes-cluster-ssh-key"
  public_key = "${file("~/.ssh/kubernetes-cluster-ssh-key-rsa.pub")}"
}

resource "exoscale_affinity" "kubernetes-nodes" {
  name        = "kubernetes-nodes"
  description = "Up to 8 kubernetes nodes are placed on different hypervisors"
  type        = "host anti-affinity"
}

# Create security group for ssh access nodes
resource "exoscale_security_group" "kubernetes-cluster-ssh-access-security-group" {
  name        = "kubernetes-cluster-ssh-access-security-group"
  description = "Security Group for ssh access."
}

# Create security group for master nodes
resource "exoscale_security_group" "kubernetes-master-nodes-security-group" {
  name        = "kubernetes-master-nodes-security-group"
  description = "Security Group for kubernetes master nodes."
}

# Create a security group for worker nodes
resource "exoscale_security_group" "kubernetes-worker-nodes-security-group" {
  name        = "kubernetes-worker-nodes-security-group"
  description = "Security Group for kubernetes worker nodes."
}

# Create a security group for etcd nodes
resource "exoscale_security_group" "etcd-nodes-security-group" {
  name        = "etcd-nodes-security-group"
  description = "Allow access to etcd nodes."
}

resource "exoscale_security_group_rule" "kubernetes-cluster-ssh-access-security-group-nodeports" {
  security_group_id = "${exoscale_security_group.kubernetes-cluster-ssh-access-security-group.id}"
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 22
  end_port          = 22
}

# Check ports are needed for master nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-master-nodes-security-group-api-server" {
  security_group_id = "${exoscale_security_group.kubernetes-master-nodes-security-group.id}"
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 6443
  end_port          = 6443
}

# Check ports are needed for master nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-master-nodes-security-group-master-services" {
  security_group_id = "${exoscale_security_group.kubernetes-master-nodes-security-group.id}"
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 10250
  end_port          = 10252
}

# Check ports are needed for worker nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-worker-nodes-security-group-kubelet-api" {
  security_group_id = "${exoscale_security_group.kubernetes-worker-nodes-security-group.id}"
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 10250
  end_port          = 10250
}

# Check ports are needed for worker nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "kubernetes-worker-nodes-security-group-nodeports" {
  security_group_id = "${exoscale_security_group.kubernetes-worker-nodes-security-group.id}"
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 30000
  end_port          = 32767
}

# Check ports are needed for etcd nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "exoscale_security_group_rule" "etcd-nodes-security-group-client-api" {
  security_group_id = "${exoscale_security_group.etcd-nodes-security-group.id}"
  protocol          = "TCP"
  type              = "INGRESS"
  cidr              = "0.0.0.0/0"
  start_port        = 2379
  end_port          = 2380
}

# Create 3 Kubernetes master nodes (using ubuntu template)
resource "exoscale_compute" "kubernetes-master-nodes" {
  display_name    = "kubernetes-master-node0${count.index}"
  zone            = "at-vie-1"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Small"
  disk_size       = 20
  ip6             = false
  key_pair        = "${exoscale_ssh_keypair.kubernetes-cluster-ssh-key.id}"
  security_groups = ["${exoscale_security_group.kubernetes-cluster-ssh-access-security-group.name}", "${exoscale_security_group.kubernetes-master-nodes-security-group.name}"]
  affinity_groups = ["${exoscale_affinity.kubernetes-nodes.name}"]

  state = "Running"

  tags {
    env                = "production"
    kubernetes-cluster = "kubernetes-master"
  }

  count = 1
}

# Create 3 Kubernetes worker nodes (using ubuntu template)
resource "exoscale_compute" "kubernetes-worker-nodes" {
  display_name    = "kubernetes-worker-node0${count.index}"
  zone            = "at-vie-1"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Small"
  disk_size       = 20
  ip6             = false
  key_pair        = "${exoscale_ssh_keypair.kubernetes-cluster-ssh-key.id}"
  security_groups = ["${exoscale_security_group.kubernetes-cluster-ssh-access-security-group.name}", "${exoscale_security_group.kubernetes-worker-nodes-security-group.name}"]
  affinity_groups = ["${exoscale_affinity.kubernetes-nodes.name}"]
  state           = "Running"

  tags {
    env                = "production"
    kubernetes-cluster = "kubernetes-worker"
  }

  count = 3
}

# Create 3 etcd nodes (using ubuntu template)
resource "exoscale_compute" "kubernetes-etcd-nodes" {
  display_name    = "kubernetes-etcd-node0${count.index}"
  zone            = "at-vie-1"
  template        = "Linux Ubuntu 18.04 LTS 64-bit"
  size            = "Small"
  disk_size       = 10
  ip6             = false
  key_pair        = "${exoscale_ssh_keypair.kubernetes-cluster-ssh-key.id}"
  security_groups = ["${exoscale_security_group.kubernetes-cluster-ssh-access-security-group.name}", "${exoscale_security_group.etcd-nodes-security-group.name}"]
  state           = "Running"

  tags {
    env                = "production"
    kubernetes-cluster = "kubernetes-worker"
  }

  count = 3
}

# Template for ansible inventory
data "template_file" "ansible-inventory" {
  template = "${file("ansible-inventory.tpl")}"

  vars {
    kubernetes_master_node00_ip = "${exoscale_compute.kubernetes-master-nodes.*.ip_address[0]}"
    kubernetes_worker_node00_ip = "${exoscale_compute.kubernetes-worker-nodes.*.ip_address[0]}"
    kubernetes_worker_node01_ip = "${exoscale_compute.kubernetes-worker-nodes.*.ip_address[1]}"
    kubernetes_worker_node02_ip = "${exoscale_compute.kubernetes-worker-nodes.*.ip_address[2]}"
    etcd_node00_ip              = "${exoscale_compute.kubernetes-etcd-nodes.*.ip_address[0]}"
    etcd_node01_ip              = "${exoscale_compute.kubernetes-etcd-nodes.*.ip_address[1]}"
    etcd_node02_ip              = "${exoscale_compute.kubernetes-etcd-nodes.*.ip_address[2]}"
  }
}

# Create inventory file
resource "null_resource" "create-ansible-inventory" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    template = "${data.template_file.ansible-inventory.rendered}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.ansible-inventory.rendered}\" > inventory"
  }
}
