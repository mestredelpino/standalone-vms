# Standalone Services

This terraform scripts allow you to deploy vSphere virtual machines (with a static IP or DHCP allocated) and providing them with a custom startup script. 

1. Clone the repo

```
git clone https://github.com/mestredelpino/standalone-vms.git
```

2. Create a file "terraform.tfvars" and paste these variables to deploy a virtual machine called <YOUR_VM_NAME>.

```
vsphere-user           = ""                # The username of the vSphere user to be used for this deployment
vsphere-password       = ""                # The password of the vSphere user to be used for this deployment
vsphere-server         = ""                # The vSphere server (IP address or FQDN)
vsphere-datacenter     = ""                # The vSphere Datacenter you will deploy this virtual machine to
vsphere-datastore      = ""                # The datastore you will deploy this virtual machine to
vsphere-resource_pool  = ""                # The resource pool to be used by this virtual machine (optional)
vsphere-host           = ""                # The ESXi host you will deploy this virtual machine to
vsphere-network        = ""                # The network segment to be used by this virtual machine
vsphere-network-cidr   = ""                # The CIDR of the "vsphere-network"
vsphere-vm-folder      = ""                # The name of the vSphere folder which will contain the deployed virtual machine(s)

dhcp-vms = [
      {
        name: "example"
        disk : 100,
        cpu : 2,
        memory : 4000,
        ip_address : "10.1.1.15",
        vm-name: "example-standalone"
        startup-script: "example-setup.sh",
        environment-variables = {
          variable1           = "dummy"
          variable2           = "dummy2"
        }
      }
]
```

3. Create a file called <YOUR_VM_NAME>-setup.sh in the startup-scripts directory. This will be your startup script, that the VM will run at creation.

## Example usage

In this repository there are shell scripts for deploying both [MinIO](https://min.io/) and [Concourse CI](https://concourse-ci.org/) servers. 
For deploying them with static IP addresses, use these variables:

```
focal-cloudserver-name = ""                         # The name for the ubuntu-server template VM (default is ubuntu-server-template)
static-vms = [
  {                                                 # Deploy MinIO (cloud-native storage, will use setup-scripts/minio-setup.sh as startup script)
    name = "minio"                                  # The VM's hostname (and helm chart to install)
    disk = 100,                                     # The VM's disk storage in GB
    cpu = 2,                                        # The VM's number of vCPUs
    memory = 4000,                                  # The VM's memory in MB
    ip_address : "10.0.0.3",                        # The static IP address for this VM
    vm-name: "minio-standalone",                    # The name of this VM
    startup-script: "minio-setup.sh",               # The startup shell script to run when this VM powers on for the first time
    environment-variables = {                       # Environment variables to be passed to your VM (at ~/.env)
      service_domain           = "yourdomain.com"   # DNS domain to be used by the MinIO service
      service_root             = "admin"            # Root username to be used by the MinIO service
      service_root_password    = "password123"      # Root username to be used by the MinIO service
    }
  },
 {                                                  # Deploy Concourse CI (CI tool, will use setup-scripts/concourse-setup.sh as startup script)
    name: "concourse"                               # The VM's hostname (and helm chart to install)
    disk = 50,                                      # The VM's disk storage in GB
    cpu = 2,                                        # The VM's number of vCPUs
    memory = 4000,                                  # The VM's memory in MB
    ip_address = "10.0.0.4",                        # The static IP address for this VM
    vm-name: "concourse-standalone",                # The name of this VM
    startup-script: "concourse-setup.sh",           # The startup shell script to run when this VM powers on for the first time
    environment-variables = {                       # Environment variables to be passed to your VM (at ~/.env)
      service_domain           = "yourdomain.com"   # DNS domain to be used by the Concourse service
      service_root             = "admin"            # Root username to be used by the Concourse service
      service_root_password    = "password123"      # Root username to be used by the Concourse service
    }
  }
]
```

Create as many virtual machines as you want by reusing the provided templates above, but make sure that VMs you deploy match their startup script name.

### Run the script

In order to execute the script, open a terminal and run:

```
terraform init
terraform apply
```

