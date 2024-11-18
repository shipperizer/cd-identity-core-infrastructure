resource "openstack_compute_keypair_v2" "keypair" {
  name = "dev-keypair"
}


resource "local_sensitive_file" "keypair" {
  content         = nonsensitive(openstack_compute_keypair_v2.keypair.private_key)
  filename        = "${path.module}/keypair"
  file_permission = "0600"
}