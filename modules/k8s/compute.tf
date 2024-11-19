data "openstack_compute_flavor_v2" "small" {
  vcpus = 1
  ram   = 2048
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "auto-sync/ubuntu-noble-24.04-amd64-server-20241106-disk1.img"
  most_recent = true
}

resource "openstack_compute_instance_v2" "leader" {
  name      = "k8s-leader"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id

  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.k8s.name]

  metadata = {
    k8s         = "leader"
    environment = "dev"
  }

  user_data = data.template_cloudinit_config.k8s_leader.rendered

  network {
    uuid = data.openstack_networking_network_v2.network.id
  }

  connection {
    user        = "ubuntu"
    host        = self.access_ip_v4
    private_key = openstack_compute_keypair_v2.keypair.private_key
  }

  provisioner "file" {
    source      = local_sensitive_file.keypair.filename
    destination = "/tmp/keypair"
  }
}




resource "openstack_compute_instance_v2" "control" {
  depends_on = [openstack_compute_instance_v2.leader]

  count     = var.controls
  name      = "k8s-control-${count.index}"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id

  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.k8s.name]

  network {
    uuid           = data.openstack_networking_network_v2.network.id
    access_network = true
  }

  metadata = {
    k8s         = "control"
    environment = "dev"
  }

  user_data = data.template_cloudinit_config.k8s.rendered

}


resource "openstack_compute_instance_v2" "worker" {
  depends_on = [openstack_compute_instance_v2.leader]

  count     = var.workers
  name      = "k8s-worker-${count.index}"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id

  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.k8s.name]

  network {
    uuid           = data.openstack_networking_network_v2.network.id
    access_network = true
  }

  metadata = {
    k8s         = "worker"
    environment = "dev"
  }

  user_data = data.template_cloudinit_config.k8s.rendered
}



# resource "terraform_data" "join_controls" {
#   count = var.controls

#   depends_on = [local_sensitive_file.keypair]

#   # Replacement of any instance of the cluster requires re-provisioning
#   triggers_replace = openstack_compute_instance_v2.control[*].id

#   provisioner "local-exec" {
#     command = <<EOT
#       ssh -oStrictHostKeyChecking=no -i ${local_sensitive_file.keypair.filename} ubuntu@${openstack_compute_instance_v2.leader.access_ip_v4} sudo cloud-init status --wait
#       TOKEN=$(ssh -oStrictHostKeyChecking=no -i ${local_sensitive_file.keypair.filename} ubuntu@${openstack_compute_instance_v2.leader.access_ip_v4} sudo k8s get-join-token ${openstack_compute_instance_v2.control[count.index].name})
#       echo $TOKEN
#       ssh -oStrictHostKeyChecking=no -i ${local_sensitive_file.keypair.filename} ubuntu@${openstack_compute_instance_v2.control[count.index].access_ip_v4} sudo k8s join-cluster $TOKEN
#     EOT
#   }
# }


# resource "terraform_data" "join_workers" {
#   count = var.workers

#   depends_on = [local_sensitive_file.keypair]

#   # Replacement of any instance of the cluster requires re-provisioning
#   triggers_replace = openstack_compute_instance_v2.worker[*].id

#   provisioner "local-exec" {
#     command = <<EOT
#       ssh -oStrictHostKeyChecking=no -i ${local_sensitive_file.keypair.filename} ubuntu@${openstack_compute_instance_v2.leader.access_ip_v4} sudo cloud-init status --wait
#       TOKEN=$(ssh -oStrictHostKeyChecking=no -i ${local_sensitive_file.keypair.filename} ubuntu@${openstack_compute_instance_v2.leader.access_ip_v4} sudo k8s get-join-token ${openstack_compute_instance_v2.worker[count.index].name} --worker)
#       echo $TOKEN
#       ssh -oStrictHostKeyChecking=no -i ${local_sensitive_file.keypair.filename} ubuntu@${openstack_compute_instance_v2.worker[count.index].access_ip_v4} sudo k8s join-cluster $TOKEN
#     EOT
#   }
# }


resource "terraform_data" "join_controls" {
  count = var.workers

  # Replacement of any instance of the cluster requires re-provisioning
  triggers_replace = openstack_compute_instance_v2.control[*].id

  connection {
    user        = "ubuntu"
    host        = openstack_compute_instance_v2.leader.access_ip_v4
    private_key = openstack_compute_keypair_v2.keypair.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "TOKEN=$(sudo k8s get-join-token ${openstack_compute_instance_v2.control[count.index].name})",
      "echo $TOKEN",
      "ssh -oStrictHostKeyChecking=no -i /tmp/keypair ubuntu@${openstack_compute_instance_v2.control[count.index].access_ip_v4} sudo cloud-init status --wait",
      "ssh -oStrictHostKeyChecking=no -i /tmp/keypair ubuntu@${openstack_compute_instance_v2.control[count.index].access_ip_v4} sudo k8s join-cluster $TOKEN"
    ]
  }
}

resource "terraform_data" "join_workers" {
  count = var.workers

  # Replacement of any instance of the cluster requires re-provisioning
  triggers_replace = openstack_compute_instance_v2.worker[*].id

  connection {
    user        = "ubuntu"
    host        = openstack_compute_instance_v2.leader.access_ip_v4
    private_key = openstack_compute_keypair_v2.keypair.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "TOKEN=$(sudo k8s get-join-token ${openstack_compute_instance_v2.worker[count.index].name} --worker)",
      "echo $TOKEN",
      "ssh -oStrictHostKeyChecking=no -i /tmp/keypair ubuntu@${openstack_compute_instance_v2.worker[count.index].access_ip_v4} sudo cloud-init status --wait",
      "ssh -oStrictHostKeyChecking=no -i /tmp/keypair ubuntu@${openstack_compute_instance_v2.worker[count.index].access_ip_v4} sudo k8s join-cluster $TOKEN"
    ]
  }
}