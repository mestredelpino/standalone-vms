# ---------------------------------------------------------------------------------------------------------------------
# SET UP PROVIDERS AND REQUIRED VERSIONS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"
}

provider "vsphere" {
  user                 = var.vsphere-user
  password             = var.vsphere-password
  vsphere_server       = var.vsphere-server
  allow_unverified_ssl = true
}

data "vsphere_network" "network" {
  name          = var.vsphere-network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere-datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere-datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.vsphere-resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.vsphere-host  
  datacenter_id = data.vsphere_datacenter.dc.id
}

# resource "vsphere_folder" "vm_folder" {
#   path          = var.vm-folder
#   type          = "vm"
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

resource "local_file" "env_file" {
  content = templatefile("env.tpl", {
    concourse-fqdn = var.concourse-fqdn
    concourse-username = var.concourse-username
    concourse-password = var.concourse-password
  })
  filename        = "env"
  file_permission = "0644"
}

resource "local_file" "ingress_file" {
  content = templatefile("ingress.tpl", {
    concourse-fqdn = var.concourse-fqdn
 
  })
  filename        = "ingress.yaml"
  file_permission = "0644"
}

# ---------------------------------------------------------------------------------------------------------------------
# Deploy Concourse (DHCP)
# ---------------------------------------------------------------------------------------------------------------------


resource "vsphere_virtual_machine" "concourse-cp-dhcp" {
  count = var.dhcp-concourse ? 1 : 0
  name                       = var.vm-name
  resource_pool_id           = data.vsphere_resource_pool.resource_pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  datacenter_id              = data.vsphere_datacenter.dc.id
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = 2
  num_cpus                   = 2
  memory                     = 6000
  host_system_id   = data.vsphere_host.host.id

  network_interface {
    network_id = data.vsphere_network.network.id
  }
  
  disk {
    label            = "disk0"
    thin_provisioned = false // true
    size             = 20
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
      "instance-id" = var.vm-name
      "hostname"    = var.vm-name
      "public-keys" = file("~/.ssh/id_rsa.pub")
    }
  }

  connection {
    host        = vsphere_virtual_machine.concourse-cp-dhcp[0].default_ip_address
    timeout     = "30s"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    # Copy additional configuration file.
    source      = "ingress.yaml"
    destination = "/home/ubuntu/ingress.yaml"
  }
  provisioner "file" {
    # Copy additional configuration file.
    source      = "env"
    destination = "/home/ubuntu/.env"
  }

  provisioner "file" {
    # Copy install scripts.
    source      = "./concourse-setup-k3s.sh"
    destination = "/home/ubuntu/concourse-setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${vsphere_virtual_machine.concourse-cp-dhcp[0].default_ip_address} concourse | sudo tee -a /etc/hosts",
      "chmod +x /home/ubuntu/concourse-setup.sh",
      "sh /home/ubuntu/concourse-setup.sh",
      # "rm /home/ubuntu/concourse-setup.sh",
    ]
    on_failure = continue
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Deploy Concourse (Static IP)
# ---------------------------------------------------------------------------------------------------------------------



resource "vsphere_virtual_machine" "focal-cloudserver" {
  count = var.dhcp-concourse ? 0 : 1
  name                       = "focal-cloudserver-template"
  resource_pool_id           = data.vsphere_resource_pool.resource_pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  host_system_id             = data.vsphere_host.host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  datacenter_id              = data.vsphere_datacenter.dc.id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  ovf_deploy {
    ovf_network_map = {"VM Network": data.vsphere_network.network.id
    }
    local_ovf_path = var.focal-ova
  }
  cdrom {
    client_device = true
  }
}


data "vsphere_virtual_machine" "ubuntu_template" {
  count = var.dhcp-concourse ? 0 : 1
  name          = vsphere_virtual_machine.focal-cloudserver[0].name
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on = [
    vsphere_virtual_machine.focal-cloudserver
  ]
}



resource "vsphere_virtual_machine" "concourse-cp-static" {
  count = var.dhcp-concourse ? 0 : 1
  name                       = "concourse-cp"
  resource_pool_id           = data.vsphere_resource_pool.resource_pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = 2
  num_cpus                   = 2
  memory                     = 6000
  guest_id                   = "ubuntu64Guest"
  # folder                     = vsphere_folder.vm_folder.path

  network_interface {
    network_id = data.vsphere_network.network.id
  }
  
  disk {
    label            = "disk0"
    thin_provisioned = false // true
    size             = 20
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.ubuntu_template[0].id
       customize {

      linux_options {
        host_name = "concourse"
        domain = "magrathea.lab"      
      }

      network_interface {
        ipv4_address = var.concourse-static-ip
        ipv4_netmask = 24# cidrnetmask("${var.vsphere-network-cidr}")
      }
      dns_server_list = [ cidrhost(var.vsphere-network-cidr, 1) ]
      ipv4_gateway = cidrhost(var.vsphere-network-cidr, 1)
    }
  } 
  cdrom {
    client_device = true
  }


  vapp {
    properties = {
      "instance-id" = "concourse-cp"
      "hostname"    = "concourse-cp"
      "public-keys" = file("~/.ssh/id_rsa.pub")      
    }
  }

  connection {
    host        = vsphere_virtual_machine.concourse-cp-static[0].default_ip_address
    timeout     = "30s"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    # Copy additional configuration file.
    source      = "env"
    destination = "/home/ubuntu/.env"
  }

  provisioner "file" {
    # Copy install scripts.
    source      = "./concourse-setup-k3s.sh"
    destination = "/home/ubuntu/concourse-setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${vsphere_virtual_machine.concourse-cp-static[0].default_ip_address} concourse | sudo tee -a /etc/hosts",
      "chmod +x /home/ubuntu/concourse-setup.sh",
      "sh /home/ubuntu/concourse-setup.sh",
      "rm /home/ubuntu/concourse-setup.sh",
    ]
    on_failure = continue
  }
  depends_on = [
    vsphere_virtual_machine.focal-cloudserver
  ]
}
