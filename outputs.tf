output "static-vms-names" {
  value = {
  for eachVM, service-vm-static in vsphere_virtual_machine.service-vm-static : eachVM => service-vm-static.name
  }
}

output "dhcp-vms-names" {
  value = {
  for eachVM, service-vm-dhcp in vsphere_virtual_machine.service-vm-dhcp : eachVM => service-vm-dhcp.name
  }
}

output "static-vms-ip_addresses" {
  value = {
  for eachVM, service-vm-static in vsphere_virtual_machine.service-vm-static : eachVM => service-vm-static.default_ip_address
  }
}

output "dhcp-vms-ip_addresses" {
  value = {
  for eachVM, service-vm-dhcp in vsphere_virtual_machine.service-vm-dhcp : eachVM => service-vm-dhcp.default_ip_address
  }
}