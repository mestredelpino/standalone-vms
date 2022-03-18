output "concourse-fqdn" {
    value = var.concourse-fqdn
    description = "The fqdn for your Concourse deployment"  
}
output "concourse-dhcp-ip-address" {
    value = length(vsphere_virtual_machine.concourse-cp-dhcp) > 0 ? vsphere_virtual_machine.concourse-cp-dhcp[0].default_ip_address : null
    description = "The IP address of your newly deployed Concourse"
}

output "concourse-static-ip-address" {
    value = length(vsphere_virtual_machine.concourse-cp-static) > 0 ? vsphere_virtual_machine.concourse-cp-static[0].default_ip_address : null
    description = "The IP address of your newly deployed Concourse"
}