# Standalone Concourse on k3s
![Alt text](https://github.com/mestredelpino/standalone-vms/blob/main/concourse/concourse.png?raw=true "Concourse")

This terraform scripts allows you to deploy a Concourse virtual machine on your vSphere environment. 



## Create a standalone Concourse virtual machine (DHCP)

1. Create a terraform.tfvars file in the "concourse" directory, containing the following:

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

vm-folder              = "" # The name of the vSphere folder which will contain the Concourse virtual machine
vm-name                = "" # The name of the concourse VM

concourse-fqdn         = "" # The FQDN of your Concourse deployment
dhcp-concourse         = true # Deploy Concourse with dynamic IP address allocation
```
2. Navigate to the *"concourse"* directory
3. Execute `terraform init`
4. Execute `terraform apply`

## Create a standalone Concourse virtual machine (Static IP)


1. Download the [ubuntu server cloud image OVA](https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova) (used for the jumpbox VM) and paste it in the /concourse folder. A template VM will be created, which can then be cloned and assigned a static IP address.
3. Create a terraform.tfvars, file and fill in these values:

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

vm-folder              = "" # The name of the vSphere folder which will contain the Concourse virtual machine
vm-name                = "" # The name of the concourse VM

concourse-fqdn         = "" # The FQDN of your Concourse deployment

# Variables for static Concourse deployment 
concourse-static-ip    = "" # The Static IP address to be used by Concourse (not available yet)
focal-ova              = "" # The full path to the focal cloud-server image you downloaded
focal-cloudserver-name = "" # The name of the focal cloud server virtual machine that will be deployed
dhcp-concourse         = false # Deploy Concourse with a static IP address
```
3. Navigate to the *"concourse"* directory
4. Execute `terraform init`
5. Execute `terraform apply`