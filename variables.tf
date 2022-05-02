variable "vsphere_user" {
  description = "Your vSphere username"
  type = string
}
variable "vsphere_password" {
  description = "Your vSphere password"
  type = string
  sensitive = true
}

variable "vsphere_server" {
  description = "Your vCenter's FQDN"
  type = string
}

variable "vsphere_datacenter" {
  description = "The name of your vSphere datacenter"
  type = string
}

variable "vsphere_datastore" {
  description = "The name of your vSphere datastore"
  type = string
}

variable "vsphere_resource_pool" {
  description = "The name of your vSphere resource pool"
  type = string
  default = "Resources"
}

variable "vsphere_host" {
  description = "The IP address of the ESXi host where the VM will be created"
  type = string
 validation {
    condition = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",var.vsphere-host))
    error_message = "Invalid IP address provided."
  }
}

variable "vsphere_network" {
  description = "The vsphere network to be used by the Concourse VM"
  type = string
}

variable "vsphere_network_cidr" {
  description = "The CIDR of the vSphere Network"
  type = string
}

variable "vsphere_vm_folder" {
  description = "The name of the new vSphere folder where the concourse virtual machine will be located" 
  type = string
  default = ""
}

variable "focal_cloudserver_name" {
  description = "The name of the ubuntu server to be deployed (not required for deployments of VMs with a dynamic IP address)"
  type = string
  default = "ubuntu-server-template"
}

variable "dhcp_vms" {
  description = "The virtual machines to be deployed with a dynamic IP address"
  default      = []
  type         = list
}

variable "static_vms" {
  description  = "The virtual machines to be deployed with a static IP address"
  default      = []
  type         = list
}