output "concourse-fqdn" {
    value = var.concourse-fqdn
    description = "The fqdn for your Concourse deployment"  
}
output "concourse-ip-address" {
    value = vsphere_virtual_machine.concourse-cp.default_ip_address
    description = "The IP address of your newly deployed Concourse"
}