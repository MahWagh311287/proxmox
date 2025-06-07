variable "vms" {
  type = map(object({
    vmid     : number
    iso_file : string
    memory   : number
    cores    : number
    desc     : string
  }))
  default = {
    "rhel-server" = {
      vmid     = 201
      iso_file = "iso/rhel-9.2-x86_64-dvd.iso"
      memory   = 4096
      cores    = 2
      desc     = "RHEL Server created by Terraform"
    }
    "ubuntu-server" = {
      vmid     = 202
      iso_file = "iso/ubuntu-22.04.4-live-server-amd64.iso"
      memory   = 4096
      cores    = 2
      desc     = "Ubuntu Server created by Terraform"
    }
  }
}

resource "proxmox_vm_qemu" "multi_vm" {
  for_each    = var.vms
  name        = each.key
  target_node = "pve"
  vmid        = each.value.vmid
  desc        = each.value.desc

  cores    = each.value.cores
  sockets  = 1
  memory   = each.value.memory
  agent    = 1

  disk {
    slot     = 0
    size     = "40G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  disk {
    type    = "cdrom"
    storage = "local"
    media   = "cdrom"
    file    = each.value.iso_file
    size    = "1M"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  boot    = "order=scsi0;ide2;net0"
  scsihw  = "virtio-scsi-pci"

  ciuser     = "admin"
  cipassword = "securepassword"
  sshkeys    = <<EOF
  ssh-rsa AAAAB3NzaC1y... user@example.com
  EOF

  # RHEL ke liye kickstart, Ubuntu ke liye hata sakte hain ya customize kar sakte hain
  args = contains(each.key, "rhel") ? "-args 'inst.ks=https://your-server.com/rhel-ks.cfg'" : null

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
