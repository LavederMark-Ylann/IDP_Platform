locals {
  name         = "Kubernetes"
  distribution = "Ubuntu"
  environment  = "dev"
}

resource "terraform_data" "ubuntu_kubernetes" {
  provisioner "local-exec" {
    when    = destroy
    command = "wsl.exe --unregister Kubernetes"
  }
  provisioner "local-exec" {
    # Locally runs wsl to download and install a new ubuntu to host a kubernetes single-node cluster
    command = <<-EOT
    wsl.exe --install --no-launch -d "${local.distribution}" --name "${local.name}" &&
    wsl.exe -d "${local.name}" -u root useradd -m -s /bin/bash "${var.username}" &&
    wsl.exe -d "${local.name}" -u root bash -c 'echo "${var.username}:${var.password}" | chpasswd' &&
    wsl.exe -d "${local.name}" -u root bash -c 'usermod -aG sudo ${var.username}'
  EOT
  }
}