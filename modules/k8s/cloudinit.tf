data "template_cloudinit_config" "k8s" {
  gzip          = false
  base64_encode = false

  part {
    filename   = "nodes.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"

    content_type = "text/cloud-config"
    content      = file("${path.module}/scripts/nodes.yaml")
  }
}


data "template_cloudinit_config" "k8s_leader" {
  gzip          = false
  base64_encode = false

  part {
    filename   = "nodes.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"

    content_type = "text/cloud-config"
    content      = file("${path.module}/scripts/nodes.yaml")
  }

  part {
    filename   = "leader.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"

    content_type = "text/cloud-config"
    content      = file("${path.module}/scripts/leader.yaml")
  }
}



