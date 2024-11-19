
data "template_file" "proxy" {
  template = file("${path.module}/scripts/http-proxy.conf")

  vars = {
    https_proxy  = var.https_proxy
    http_proxy   = var.http_proxy
    no_proxy     = data.openstack_networking_subnet_v2.subnet.cidr
    service_cidr = "10.152.183.0/24"
    pod_cidr     = "10.1.0.0/16"
  }
}


data "template_file" "nodes" {
  template = file("${path.module}/scripts/nodes.yaml")

  vars = {
    http_proxy_file = data.template_file.proxy.rendered
  }
}

data "template_cloudinit_config" "k8s" {
  gzip          = false
  base64_encode = false

  part {
    filename   = "nodes.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"

    content_type = "text/cloud-config"
    content      = data.template_file.nodes.rendered
  }
}


data "template_cloudinit_config" "k8s_leader" {
  gzip          = false
  base64_encode = false

  part {
    filename   = "nodes.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"

    content_type = "text/cloud-config"
    content      = data.template_file.nodes.rendered
  }
  
  part {
    filename   = "leader.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"

    content_type = "text/cloud-config"
    content      = file("${path.module}/scripts/leader.yaml")
  }
}



