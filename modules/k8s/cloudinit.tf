data "template_file" "proxy" {
  template = file("${path.module}/scripts/proxy.sh")

  vars = {
    https_proxy = "${var.https_proxy}"
  }
}

data "template_cloudinit_config" "k8s" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "install.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/scripts/install.sh")
  }
}


data "template_cloudinit_config" "k8s_leader" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "install.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/scripts/install.sh")
  }

  part {
    filename     = "proxy.sh"
    content_type = "text/x-shellscript"

    content = data.template_file.proxy.rendered
  }



  part {
    filename     = "bootstrap.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/scripts/bootstrap.sh")
  }
}



