data "openstack_networking_network_v2" "network" {
  name = "net_stg-cd-identity"
}

data "openstack_networking_subnet_v2" "subnet" {
  network_id = data.openstack_networking_network_v2.network.id
}

resource "openstack_networking_secgroup_v2" "k8s" {
  name        = "k8s"
  description = "Security group to allow ssh into each k8s node"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_gossip" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6400
  port_range_max    = 6400
  remote_ip_prefix  = data.openstack_networking_subnet_v2.subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.k8s.id
}