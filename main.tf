# ---------------------------------------------------------------------------------------------------------------------
# SET UP PROVIDERS AND REQUIRED VERSIONS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
  version = "2.1.1"
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  dhcp-vms = {
    for name, vm in var.dhcp_vms : vm.vm_name => vm
  }
  static-vms = {
    for name, vm in var.static_vms : vm.vm_name => vm
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Deploy VMs with an ip address assigned via DHCP
# ---------------------------------------------------------------------------------------------------------------------

resource "vsphere_folder" "vm-folder" {
  path          = var.vsphere_vm_folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}



resource "vsphere_virtual_machine" "service-vm-dhcp" {
  for_each =  { for index, vm in local.dhcp-vms: vm.vm_name => vm }
  name                       = each.value.vm_name
  resource_pool_id           = data.vsphere_resource_pool.resource_pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  datacenter_id              = data.vsphere_datacenter.dc.id
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = 2
  num_cpus                   = each.value.cpu
  memory                     = each.value.memory
  host_system_id             = data.vsphere_host.host.id
  folder                     = vsphere_folder.vm-folder.path
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label            = "disk0"
    thin_provisioned = false // true
    size             = each.value.disk
  }
  ovf_deploy {
    remote_ovf_url = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova"
    ovf_network_map = {"VM Network": data.vsphere_network.network.id
    }
    ip_protocol               = "IPV4"
    ip_allocation_policy      = "STATIC_MANUAL"
  }
  cdrom {
    client_device = true
  }
  vapp {
    properties = {
      "instance-id" = each.key
      "hostname"    = each.key
      "public-keys" = file("~/.ssh/id_rsa.pub")
    }
  }
  connection {
    host        = self.default_ip_address
    timeout     = "30s"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    # Copy install scripts.
    source      = "./setup-scripts/${each.value.startup_script}"
    destination = "/home/ubuntu/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${self.default_ip_address} ${each.key} | sudo tee -a /etc/hosts",
      "sudo apt update && sudo apt install -y jq & sudo snap install yq",
      "echo '${jsonencode(each.value.environment_variables[*])}'  |  sed 's/^.//;s/.$//' | yq -P '.'  | sed 's/:/=/' | sed -e 's/[\t ]//g;/^$/d' > .env",
      "sed -i -e 's/\r$//' /home/ubuntu/setup.sh",
      "chmod +x /home/ubuntu/setup.sh",
      "sh /home/ubuntu/setup.sh",
      "rm /home/ubuntu/setup.sh && rm /home/ubuntu/snap/ -rf",
      "echo ${self.default_ip_address}"
    ]
    on_failure = continue
  }
}

//# ---------------------------------------------------------------------------------------------------------------------
//# Deploy VMs with a static IP
//# ---------------------------------------------------------------------------------------------------------------------

resource "vsphere_virtual_machine" "focal-cloudserver" {
  count                      = length(local.static-vms) > 0 ? 1:0
  name                       = var.focal_cloudserver_name
  resource_pool_id           = data.vsphere_resource_pool.resource_pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  host_system_id             = data.vsphere_host.host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  datacenter_id              = data.vsphere_datacenter.dc.id
  folder                     = vsphere_folder.vm-folder.path
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  ovf_deploy {
    remote_ovf_url = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova"
    ovf_network_map = {"VM Network": data.vsphere_network.network.id
    }
  }
  cdrom {
    client_device = true
  }
  depends_on = [local.static-vms]
}

data "vsphere_virtual_machine" "ubuntu_template" {
  count                      = length(local.static-vms) > 0 ? 1:0
  name          = vsphere_virtual_machine.focal-cloudserver[0].name
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on = [
    vsphere_virtual_machine.focal-cloudserver[0]
  ]
}

resource "vsphere_virtual_machine" "service-vm-static" {
  for_each =  { for index, vm in local.static-vms: vm.vm_name => vm }
  name                       = each.value.vm_name
  resource_pool_id           = data.vsphere_resource_pool.resource_pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = 2
  num_cpus                   = each.value.cpu
  memory                     = each.value.memory
  guest_id                   = "ubuntu64Guest"
  folder                     = vsphere_folder.vm-folder.path
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label            = "disk0"
    thin_provisioned = false // true
    size             = each.value.disk
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.ubuntu_template[0].id
       customize {
        linux_options {
          host_name = each.key
          domain = ""
        }
      network_interface {
        ipv4_address = each.value.ip_address
        ipv4_netmask = 24# CHANGE REGEX
      }
      dns_server_list = [ cidrhost(var.vsphere_network_cidr, 1) ]
      ipv4_gateway = cidrhost(var.vsphere_network_cidr, 1)
    }
  }
  cdrom {
    client_device = true
  }
  vapp {
    properties = {
      "instance-id" = each.key
      "hostname"    = each.key
      "public-keys" = file("~/.ssh/id_rsa.pub")
    }
  }
  connection {
    host        = self.default_ip_address
    timeout     = "30s"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    # Copy install scripts.
    source      = "./setup-scripts/${each.value.startup_script}"
    destination = "/home/ubuntu/setup.sh"
  }

# Provide environment variables to the VM and run the setup script
  provisioner "remote-exec" {
    inline = [
      "echo ${self.default_ip_address} ${each.key} | sudo tee -a /etc/hosts",
      "sudo apt update && sudo apt install -y jq & sudo snap install yq",
      "echo '${jsonencode(each.value.environment_variables[*])}'  |  sed 's/^.//;s/.$//' | yq -P '.'  | sed 's/:/=/' | sed -e 's/[\t ]//g;/^$/d' > .env",
      "sed -i -e 's/\r$//' /home/ubuntu/setup.sh",
      "chmod +x /home/ubuntu/setup.sh",
      "sh /home/ubuntu/setup.sh",
      "rm /home/ubuntu/setup.sh && rm /home/ubuntu/snap/ -rf",
      "echo ${self.default_ip_address}"
    ]
  }
  depends_on = [
    vsphere_virtual_machine.focal-cloudserver[0]
  ]
}
