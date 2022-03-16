# Standalone Concourse on kind
This terraform scripts allows you to deploy a Concourse virtual machine with terraform on your vSphere environment. 

## Set up variables

Create a terraform.tfvars file in the "concourse" directory, containing the following:

```
vsphere-user           = "" # The username of the vSphere user to be used for this deployment
vsphere-password       = "" # The password of the vSphere user to be used for this deployment
vsphere-server         = "" # The vSphere server (IP address or FQDN)
vsphere-datacenter     = "" # The vSphere Datacenter you will deploy this virtual machine to
vsphere-datastore      = "" # The datastore you will deploy this virtual machine to
vsphere-resource_pool  = "" # The resource pool to be used by this virtual machine
vsphere-host           = "" # The ESXi host you will deploy this virtual machine to
vsphere-network        = "" # The network segment to be used by this virtual machine
vsphere-network-cidr   = "" # The CIDR of the "vsphere-network"

focal-ova              = "" # The full path to the focal cloud-server image you downloaded
vm-folder              = "" # The name of the vSphere folder which will contain the Concourse virtual machine

concourse-fqdn         = "" # The FQDN of your Concourse deployment
concourse-username     = "" # The Username of the concourse admin
concourse-password     = "" # The Password of the concourse admin
concourse-static-ip    = "" # The Static IP address to be used by Concourse (not available yet)

```

## Create a standalone Concourse virtual machine

1. Navigate to the *"concourse"* directory
2. Execute `terraform init`
3. Execute `terraform apply`