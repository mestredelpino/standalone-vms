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
variable "vsphere-resource_pool" {}
variable "vsphere-host" {
  description = "The desired IP address of the ESXi host, where the VM will be created"
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

variable "vm-folder" {
  description = "The name of the new vSphere folder where the concourse virtual machine will be located" 
  type = string
}

variable "vm-name" {
  description = "The name of the concourse VM" 
  type = string
}

variable "concourse-fqdn" {
  description = "The fqdn for your Concourse deployment"
  type = string
}

variable "concourse-username" {
  description = "User to create"
  type = string
  default = "test"
}

variable "concourse-password" {
  description = "Password for the new user"
  type = string
  default = "test"
  sensitive = true
}

variable "focal-ova" {
    description = "The path of the focal cloud server OVA file"
    type = string
    default = ""
}

variable "concourse-static-ip" {
  description = "The static IP used by the Concourse VM"
  type = string
  default = "192.168.1.150"
}

variable "dhcp-concourse" {
  default = false
}