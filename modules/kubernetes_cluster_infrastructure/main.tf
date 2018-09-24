resource "cloudstack_ssh_keypair" "kubernetes-cluster-ssh-key" {
  name       = "kubernetes-cluster-ssh-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create security group for master nodes
resource "cloudstack_security_group" "kubernetes-master-nodes-security-group" {
  name        = "kubernetes-master-nodes-security-group"
  description = "Security Group for kubernetes master nodes."
}

# Create a security group for worker nodes
resource "cloudstack_security_group" "kubernetes-worker-nodes-security-group" {
  name        = "kubernetes-worker-nodes-security-group"
  description = "Security Group for kubernetes worker nodes."
}

# Create a security group for etcd nodes
resource "cloudstack_security_group" "etcd-nodes-security-group" {
  name        = "etcd-nodes-security-group"
  description = "Allow access to etcd nodes."
}

# Check ports are needed for master nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "cloudstack_security_group_rule" "kubernetes-master-nodes-security-group-rules" {
  security_group_id = "${cloudstack_security_group.kubernetes-master-nodes-security-group.id}"

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["6443", "10250", "10251", "10252"]
  }

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["22"]
  }
}

# Check ports are needed for worker nodes: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "cloudstack_security_group_rule" "kubernetes-worker-nodes-security-group-rules" {
  security_group_id = "${cloudstack_security_group.kubernetes-worker-nodes-security-group.id}"

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["10250", "30000-32767"]
  }

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["22"]
  }
}

# Check ports are needed for etcd: 
# https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
resource "cloudstack_security_group_rule" "etcd-nodes-security-group-rules" {
  security_group_id = "${cloudstack_security_group.etcd-nodes-security-group.id}"

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["2379-2380"]
  }

  rule {
    cidr_list = ["0.0.0.0/0"]
    protocol  = "tcp"
    ports     = ["22"]
  }
}

# Create 3 Kubernetes master nodes (using ubuntu template)
resource "cloudstack_instance" "kubernetes-master-nodes" {
  name               = "kubernetes-master-node0${count.index}"
  template           = "4c9f5519-730f-46cb-b292-4e73ca578947"
  service_offering   = "Small"
  root_disk_size     = 20
  zone               = "at-vie-1"
  security_group_ids = ["${cloudstack_security_group.kubernetes-master-nodes-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
  count              = 3
}

# Create 3 Kubernetes worker nodes (using ubuntu template)
resource "cloudstack_instance" "kubernetes-worker-nodes" {
  name               = "kubernetes-worker-node0${count.index}"
  template           = "4c9f5519-730f-46cb-b292-4e73ca578947"
  service_offering   = "Small"
  root_disk_size     = 20
  zone               = "at-vie-1"
  security_group_ids = ["${cloudstack_security_group.kubernetes-worker-nodes-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
  count              = 3
}

# Create 3 etcd nodes
resource "cloudstack_instance" "kubernetes-etcd-nodes" {
  name               = "kubernetes-etcd-node0${count.index}"
  template           = "4c9f5519-730f-46cb-b292-4e73ca578947"
  service_offering   = "Small"
  root_disk_size     = 10
  zone               = "at-vie-1"
  security_group_ids = ["${cloudstack_security_group.etcd-nodes-security-group.id}"]
  keypair            = "${cloudstack_ssh_keypair.kubernetes-cluster-ssh-key.id}"
  count              = 3
}

# Template for ansible inventory
data "template_file" "ansible-inventory" {
  template = "${file("ansible-inventory.tpl")}"

  vars {
    kubernetes_master_node00_ip = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[0]}"
    kubernetes_master_node01_ip = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[1]}"
    kubernetes_master_node02_ip = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[2]}"
    kubernetes_worker_node00_ip = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[0]}"
    kubernetes_worker_node01_ip = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[1]}"
    kubernetes_worker_node02_ip = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[2]}"
    etcd_node00_ip              = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[0]}"
    etcd_node01_ip              = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[1]}"
    etcd_node02_ip              = "${cloudstack_instance.kubernetes-etcd-nodes.*.ip_address[2]}"
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
