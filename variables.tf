variable "vsphere-user" {
  description = "Your vSphere username"
  type = string
}
variable "vsphere-password" {
  description = "Your vSphere password"
  type = string
  sensitive = true
}

variable "vsphere-server" {
  description = "Your vCenter's FQDN"
  type = string
}

variable "vsphere-datacenter" {
  description = "The name of your vSphere datacenter"
  type = string
}

variable "vsphere-datastore" {
  description = "The name of your vSphere datastore"
  type = string
}

variable "vsphere-resource_pool" {
  description = "The name of your vSphere resource pool"
  type = string
}

variable "vsphere-host" {
  description = "The IP address of the ESXi host where the VM will be created"
  type = string
 validation {
    condition = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",var.vsphere-host))
    error_message = "Invalid IP address provided."
  }
}

variable "vsphere-network" {
  description = "The vsphere network to be used by the Concourse VM"
  type = string
}

variable "vsphere-network-cidr" {
  description = "The CIDR of the vSphere Network"
  type = string
}

variable "vsphere-vm-folder" {
  description = "The name of the new vSphere folder where the concourse virtual machine will be located" 
  type = string
  default = ""
}

variable "focal-cloudserver-name" {
  description = "The name of the ubuntu server to be deployed (not required for deployments of VMs with a dynamic IP address)"
  type = string
  default = "ubuntu-server-template"
}

variable "dhcp-vms" {
  description = "The virtual machines to be deployed with a dynamic IP address"
  type = map
  default = {}
}

variable "static-vms" {
  description  = "The virtual machines to be deployed with a static IP address"
  default      = {}
}