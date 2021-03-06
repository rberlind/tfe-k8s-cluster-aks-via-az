terraform {
  required_version = ">= 0.11.0"
}

# Set Azure environment variables
provider "azurerm" {}

# Azure Resource Group
resource "azurerm_resource_group" "k8sexample" {
  name     = "${var.resource_group_name}"
  location = "${var.azure_location}"
}

resource "null_resource" "install_az" {
  provisioner "local-exec" {
    command = "sudo apt-get update"
  }
  provisioner "local-exec" {
    command = "sudo apt-get -y install apt-transport-https"
  }
  provisioner "local-exec" {
    command = "echo \"deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ xenial main\" | sudo tee /etc/apt/sources.list.d/azure-cli.list"
  }
  provisioner "local-exec" {
    command = "curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -"
  }
  provisioner "local-exec" {
    command = "sudo apt-get update && sudo apt-get -y install azure-cli"
  }
  provisioner "local-exec" {
    command = "az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID"
  }
}

# Create new AKS cluster
# The Azure Provider does not yet have a resource for this
resource "null_resource" "aks_cluster" {
  provisioner "local-exec" {
    command = "az aks create --resource-group ${var.resource_group_name} --name ${var.cluster_name} --dns-name-prefix ${var.dns_prefix} --node-count ${var.agent_count} --node-vm-size ${var.vm_size} --admin-username ${var.admin_user} --kubernetes-version ${var.kubernetes_version} --service-principal $ARM_CLIENT_ID --client-secret $ARM_CLIENT_SECRET --ssh-key-value \"${var.public_key}\" --tags 'Environment=${var.environment}' > aks_cluster.json"
  }
  depends_on = ["null_resource.install_az"]
}

data "null_data_source" "aks_cluster_json" {
  inputs = {
    json = "${file("aks_cluster.json")}"
  }
  depends_on = ["null_resource.aks_cluster"]
}
