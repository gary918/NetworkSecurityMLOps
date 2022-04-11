# Network Security for MLOps Solutions on Azure
## Abstract
After being first highlighted in a paper entitled “Hidden Technical Debt in Machine Learning Systems” in 2015, Machine Learning DevOps (MLOps)'s been growing fast and its market is expected to reach $4 billion by 2025. In the meantime, how to secure MLOps solutions is becoming more and more important.

In this article, we'll talk about how to leverage Azure network security capabilities such as Azure Virtual Network(VNet), Azure Private Link, Azure Private DNS Zone, Azure VNet Peering to protect MLOps solutions. After listing the choices of accessing resources in VNet, we'll introduce how to use Azure Pipelines to access resources in the VNet, required configurations of using an Azure Container Registry and Azure Machine Learning compute instances/clusters in VNet environment as well. Additionally, the description of the cost brought by the network security services are also provided for your reference.

- [Network Security for MLOps Solutions on Azure](#network-security-for-mlops-solutions-on-azure)
  - [Abstract](#abstract)
  - [About MLOps Security](#about-mlops-security)
    - [What is MLOps](#what-is-mlops)
    - [How to Secure Your MLOps Environment](#how-to-secure-your-mlops-environment)
  - [Network Security for MLOps](#network-security-for-mlops)
    - [Secure Azure Machine Learning Workspace and Its Associated Resources](#secure-azure-machine-learning-workspace-and-its-associated-resources)
      - [Azure Virtual Network](#azure-virtual-network)
      - [Azure Private Link and Azure Private Endpoint](#azure-private-link-and-azure-private-endpoint)
      - [Private Azure DNS Zone](#private-azure-dns-zone)
      - [Azure Virtual Network Peering](#azure-virtual-network-peering)
      - [About the Cost](#about-the-cost)
    - [Access Resources in the VNet](#access-resources-in-the-vnet)
    - [Azure Pipeline](#azure-pipeline)
      - [Microsoft-hosted Agents vs Self-hosted Agents](#microsoft-hosted-agents-vs-self-hosted-agents)
      - [Use Azure Container Registry in VNet](#use-azure-container-registry-in-vnet)
      - [Use Compute Cluster/Instance in VNet](#use-compute-clusterinstance-in-vnet)
  - [Summary](#summary)
  - [References](#references)

## About MLOps Security
### What is MLOps
Machine Learning DevOps (MLOps) is a set of practices at the intersection of Machine Learning, DevOps and Data Engineering, aiming to deploy and maintain machine learning models in production reliably and efficiently.  
![MLOps](./images/ns_what_is_mlops.png)
*Figure 1. What is MLOps*

The diagram below shows a simplified MLOps process model, which offers a solution that automates the process of machine learning data preparation, model training, model evaluation, model registration, model deployment and monitoring. 

![MLOps process](./images/ns_mlops_process.png)
*Figure 2. MLOps Process*

### How to Secure Your MLOps Environment
When implementing a MLOps solution, you may have the challenges of securing the following resources:
* Devops pipelines
* Machine learning training data
* Machine learning pipelines
* Machine learning models

In order to address the challenges above, you need to consider the following aspects to protect the MLOps solution:
* Authentication and Authorization
  * Use Azure service principals or managed identities instead of interactive authentication
  * Use RBAC to define the user's access scope of the resources 
* **Network Security**
  * Use Azure Virtual Network (VNet) to partially or fully isolate the environment from the public internet to reduce the attack surface and data exfiltration
* Data Encryption
  * Encrypt training data in transit and at rest, by using Microsoft-managed or customer-managed keys
* Policy and Monitoring
  * Use Azure Policy and the Azure Security Center to enforce policies
  * Use Azure Monitor to collect and aggregate data (metrics, logs) from variety of sources into a common data platform where it can be used for analysis, visualization and alerting.

In this article, we'll be focusing on how to leverage Azure Network Security mechanism to protect the MLOps environment.

## Network Security for MLOps
The diagram below shows the architecture of a sample MLOps solution, which is built on the following Azure services:
* Data storage: Azure Blob Storage
* Model training/validation/registration: Azure Machine Learning workspace
* Model deployment: Azure Kubernetes Service
* Model monitor: Azure Monitor/Application Insights

![Architecture](./images/ns_architecture.png)
*Figure 3. System Architecture*

As you can see, as the core of MLOps solution, Azure Machine Learning workspace and its associated resources are protected by the virtual network, AML VNET. 
The jump host, Azure Bastion and self-hosted agents are in another virtual network, BASTION VNET which simulates another solution that need to access the resources within AML VNET. 
With the support of VNet peering and private DNS zones, Azure Pipelines can be executed on self-host agents and then trigger Azure Machine Learning pipelines to train/evaluate/register the machine learning models.
Finally, the model will be deployed as a web service on Azure Kubernetes Cluster.
This is how the Azure Pipelines and Azure Machine Learning pipelines work in this MLOps solution.
### Secure Azure Machine Learning Workspace and Its Associated Resources
As the core component of a MLOps solution, the Azure Machine Learning Workspace is the top-level resource for Azure Machine Learning that provides a centralized place to work with all the artifacts you create when you use Azure Machine Learning.

When you create a new workspace, it automatically creates several Azure resources that are used by the workspace: 
* Azure Application Insights
* Azure Container Registry
* Azure Key Vault
* Azure Storage Account

The first step of securing the MLOps environment is to protect Azure Machine Learning workspace and its associated resources. One of the effective ways of achieving this is to use Azure Virtual Network.

#### Azure Virtual Network
Azure Virtual Network (VNet) is the fundamental building block for your private network in Azure. VNet enables many types of Azure resources, such as Azure Virtual Machines (VM), to securely communicate with each other, the internet, and on-premises networks. 

By putting Azure Machine Learning workspace and its associated resources into a VNet, we can ensure that each components are able to communicate with each other without exposing them in the public internet. In this way, we can significantly reduce our MLOps solution' attack surface and data exfiltration.

The following Terraform snippet shows how to create an AML compute cluster, attach it to an AML workspace and put it into a subnet of a virtual network.
```
resource "azurerm_machine_learning_compute_cluster" "compute_cluster" {
  name                          = "my_compute_cluster"
  location                      = "eastasia"
  vm_priority                   = "LowPriority"
  vm_size                       = "Standard_NC6s_v3"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.my_workspace.id
  subnet_resource_id            = azurerm_subnet.compute_subnet.id
  ssh_public_access_enabled     = false
  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 3
    scale_down_nodes_after_idle_duration = "PT30S"
  }
  identity {
    type = "SystemAssigned"
  }
}
```
#### Azure Private Link and Azure Private Endpoint
Azure Private Link enables you to access Azure PaaS Services (for example, Azure Machine Learning Workspace, Azure Storage etc.) and Azure hosted customer-owned/partner services over a private endpoint in your virtual network. A private endpoint is a network interface which only tied to the specific chosen Azure resources thereby protecting data exfiltration. 

In Figure 3, there are four private endpoints tied to the corresponding Azure PaaS services (Azure Machine Learning workspace, Azure Blob Storage, Azure Container Registry and Azure Key Vault) that are managed by a subnet in AML VNET. Therefore, these Azure PaaS services are only accessible to the resources within the same virtual network, i.e. AML VNET. 

The following Terraform script snippet shows how to use private endpoint to link to an Azure Machine Learning workspace thus it can be protected by the virtual network. About the usage of the private DNS zones, you may refer to the next section for the details.

```
resource "azurerm_machine_learning_workspace" "aml_ws" {
  name                    = "my_aml_workspace"
  friendly_name           = "my_aml_workspace"
  location                = "eastasia"
  resource_group_name     = "my_resource_group"
  application_insights_id = azurerm_application_insights.my_ai.id
  key_vault_id            = azurerm_key_vault.my_kv.id
  storage_account_id      = azurerm_storage_account.my_sa.id
  container_registry_id   = azurerm_container_registry.my_acr_aml.id

  identity {
    type = "SystemAssigned"
  }
}

# Private DNS Zones

resource "azurerm_private_dns_zone" "ws_zone_api" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_private_dns_zone" "ws_zone_notebooks" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.RESOURCE_GROUP
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_api_link" {
  name                  = "ws_zone_link_api"
  resource_group_name   = "my_resource_group"
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_api.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_notebooks_link" {
  name                  = "ws_zone_link_notebooks"
  resource_group_name   = "my_resource_group"
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_notebooks.name
  virtual_network_id    = azurerm_virtual_network.aml_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "ws_pe" {
  name                = "my_aml_ws_pe"
  location            = "eastasia"
  resource_group_name = "my_resource_group"
  subnet_id           = azurerm_subnet.my_subnet.id

  private_service_connection {
    name                           = "my_aml_ws_psc"
    private_connection_resource_id = azurerm_machine_learning_workspace.aml_ws.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-ws"
    private_dns_zone_ids = [azurerm_private_dns_zone.ws_zone_api.id, azurerm_private_dns_zone.ws_zone_notebooks.id]
  }

  # Add Private Link after we configured the workspace
  depends_on = [azurerm_machine_learning_compute_instance.compute_instance, azurerm_machine_learning_compute_cluster.compute_cluster]
}
```

#### Private Azure DNS Zone
In the sample solution, the private endpoints are used for not only Azure Machine Learning workspace, but also its associated resources such as Azure Storage, Azure Key Vault, or Azure Container Registry. For this reason, you must correctly configure your DNS settings to resolve the private endpoint IP address to the fully qualified domain name (FQDN) of the connection string. 

You can use Azure private DNS zones to override the DNS resolution for a private endpoint. A private DNS zone can be linked to your virtual network to resolve specific domains.

Azure Private DNS provides a reliable, secure DNS service to manage and resolve domain names in a virtual network without the need to add a custom DNS solution. By using private DNS zones, you can use your own custom domain names rather than the Azure-provided names available today. Please note that the DNS resolution against a private DNS zone works only from virtual networks that are linked to it.

As you can see in the Terraform script snippet above, we created two private DNS zones by using the [recommended zone names for Azure services](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration):
* privatelink.api.azureml.ms
* privatelink.notebooks.azure.net

#### Azure Virtual Network Peering
In Figure 3, in order to enable the jump host VM or self-hosted agent VMs ( in BASTION VNET)'s access to the resources in AML VNET, we use virtual network peering to seamlessly connect these two virtual networks. Thus the two virtual networks appear as one for connectivity purposes. The traffic between VMs and Azure Machine Learning resources in peered virtual networks uses the Microsoft backbone infrastructure. Like traffic between them in the same network, traffic is routed through Microsoft's private network only.

The following Terraform script sets up the VNet peering between AML VNET and BASTION VNET.
```
# Virtual network peering for amlvnet and basvnet
resource "azurerm_virtual_network_peering" "vp_amlvnet_basvnet" {
  name                      = "vp_amlvnet_basvnet"
  resource_group_name       = "my_resource_group"
  virtual_network_name      = azurerm_virtual_network.amlvnet.name
  remote_virtual_network_id = azurerm_virtual_network.basvnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "vp_basvnet_amlvnet" {
  name                      = "vp_basvnet_amlvnet"
  resource_group_name       = "my_resource_group"
  virtual_network_name      = azurerm_virtual_network.basvnet.name
  remote_virtual_network_id = azurerm_virtual_network.amlvnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
```
#### About the Cost
Will leveraging Azure network security capabilities add more cost to your solution? Let's take a look at them one by one:

|Azure Service|Pricing|
|--|--|
|Azure Virtual Network|Free of charge|
|Azure Private Link|Pay only for private endpoint resource hours and the data processed through your private endpoint|
|Azure Private Azure DNS Zone|Billing is based on the number of DNS zones hosted in Azure and the number of DNS queries received|
|Azure VNet Peering|Inbound and outbound traffic is charged at both ends of the peered networks|

Therefore, even though setting up Azure Virtual Networks is free of charge, you still need to pay for private links, DNS zones or VNet peering if these services are needed to protect your solution.

### Access Resources in the VNet
As Azure Machine Learning workspace's been put into AML VNET, how could data scientists or data engineers access it? You can use one of the following methods:

* Azure VPN gateway - Connects on-premises networks to the VNet over a private connection. Connection is made over the public internet. There are two types of VPN gateways that you might use:
  * Point-to-site: Each client computer uses a VPN client to connect to the VNet (as shown in Figure 3.)
  * Site-to-site: A VPN device connects the VNet to your on-premises network.
* ExpressRoute - Connects on-premises networks into the cloud over a private connection. Connection is made using a connectivity provider.
* Azure Bastion - In this scenario, as shown in Figure 3, you create an Azure Virtual Machine (the jump host) inside the VNet. You then connect to the VM using Azure Bastion. Bastion allows you to connect to the VM using either an RDP or SSH session from your local web browser. You then use the jump host as your development environment. Since it is inside the VNet, it can directly access the workspace.

Please note that Azure Bastion may not work properly for your company's accounts if there are any specific conditional access policies defined. Therefore, Azure VPN Gateway or ExpressRoute are recommended ways to access the resources secured behind a VNet.

Moreover, you need to take the cost into account per your actual business requirements:
|Azure Service|Pricing|
|--|--|
|Azure VPN gateway|Charged based on the amount of time that gateway is provisioned and available|
|Azure ExpressRoute|Charged for Azure ExpressRoute and ExpressRoute Gateways|
|Azure Bastion|Billing involves a combination of hourly pricing based on SKU, scale units, and data transfer rates|

### Azure Pipeline
Azure Pipelines automatically builds and tests code projects to make them available to others. Azure Pipelines combines continuous integration (CI) and continuous delivery (CD) to test and build your code and ship it to any target.

#### Microsoft-hosted Agents vs Self-hosted Agents
As mentioned in the previous section, the MLOps solution consists of a couple of Azure Pipelines which can trigger Azure Machine Learning pipelines and access associated resources. Since the Azure Machine Learning workspace and its associated resource are behind a VNet, we need to figure out a way for a Azure Pipeline Agent(the computing infrastructure with installed agent software that runs one job of the Azure Pipeline at a time) to access them. There are a couple of ways to implement it:
* Use self-hosted agents in the same VNet or the peering VNet(as shown in Figure 3.)
* Use Microsoft-hosted agents and whitelist its IP ranges in the firewall settings of target Azure services
* Use Microsoft-hosted agents (as VPN clients) and Azure VPN Gateway

Each of the choices above has its pros and cons. First, let's compare Microsoft-hosted agents with self-hosted agents in the following perspectives:
||Microsoft-hosted Agent|Self-hosted Agent|
|--|--|--|
|Cost|Start free for one parallel job with 1,800 minutes per month, $40 per extra Microsoft-hosted CI/CD parallel job|Start free for one parallel job with unlimited minutes per month, $15 per extra self-hosted CI/CD parallel job with unlimited minutes (offering a cheaper solution when adding parallel jobs is needed)|
|Maintainance and control|Maintenance and upgrades are taken care of for you|Maintained by yourself with more control of installing any software you like on the Azure Virtual Machine|
|Build time|More time consuming since it completely freshes every time you start a build and you always start from scratch|Save you some build time because it keeps all your files and caches (npm, NuGet etc.)|

Based on the comparison above, plus the consideration of security and complexity, we choose to use a self-hosted agent for the Azure Pipeline to trigger AML pipelines in the VNet. To set up a self-hosted agent, we have the following options:
* To install the agent on Azure Virtual Machines
* To install the agents on Azure Virtual Machine scale set that can be auto-scaled to meet the customer's demands
* To install the agent on Docker container. This is not feasible as we may need run Docker container within the agent for machine learning model training.

Here's a sample for provisioning two self-hosted agents. The following is the snippet for creating Azure virtual machines and extensions:
```
resource "azurerm_linux_virtual_machine" "agent" {
  ...
}

resource "azurerm_virtual_machine_extension" "update-vm" {
  count                = 2
  name                 = "update-vm${format("%02d", count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  virtual_machine_id   = element(azurerm_linux_virtual_machine.agent.*.id, count.index)

  settings = <<SETTINGS
    {
        "script": "${base64encode(templatefile("../scripts/terraform/agent_init.sh", {
          AGENT_USERNAME      = "${var.AGENT_USERNAME}",
          ADO_PAT             = "${var.ADO_PAT}",
          ADO_ORG_SERVICE_URL = "${var.ADO_ORG_SERVICE_URL}",
          AGENT_POOL          = "${var.AGENT_POOL}"
        }))}"
    }
SETTINGS
}
```
As shown in the code above, the Terraform script calls agent_init.sh to install agent software and needed libraries on the agent VM per the customer's requirements. The shell script looks like the following:

```
#!/bin/sh
# Install other needed libraries 
...

# Creates directory & download ADO agent install files
sudo mkdir /myagent 
cd /myagent
sudo wget https://vstsagentpackage.azureedge.net/agent/2.194.0/vsts-agent-linux-x64-2.194.0.tar.gz
sudo tar zxvf ./vsts-agent-linux-x64-2.194.0.tar.gz
sudo chmod -R 777 /myagent

# Unattended install
sudo runuser -l ${AGENT_USERNAME} -c '/myagent/config.sh --unattended  --url ${ADO_ORG_SERVICE_URL} --auth pat --token ${ADO_PAT} --pool ${AGENT_POOL}'

cd /myagent
#Configure as a service
sudo ./svc.sh install ${AGENT_USERNAME}
#Start svc
sudo ./svc.sh start
```

#### Use Azure Container Registry in VNet
Azure Container Registry is a required service when you use Azure Machine Learning workspace to train and deploy the models.

While securing the Azure Machine Learning workspace with virtual networks, there are some prerequisites about Azure Container Registry:
* Your Azure Container Registry must be Premium version.
* Your Azure Container Registry must be in the same virtual network as the storage account and compute targets used for training or inference.
* Your Azure Machine Learning workspace must contain an Azure Machine Learning compute cluster.

In the sample solution, to ensure the self-hosted agent can access the Azure Container Registry in the VNet, you need to use VNet peering, and add virtual network link to link the private DNS zone (privatelink.azurecr.io) to BASTION VNET. Refer to the Terraform script snippet below for the implementation:
```
# AML ACR is for private access by AML WS
resource "azurerm_container_registry" "acr" {
  name                     = "my_acr"
  resource_group_name      = "my_resource_group"
  location                 = "eastasia"
  sku                      = "Premium"
  admin_enabled            = true
  public_network_access_enabled = false
}

resource "azurerm_private_dns_zone" "acr_zone" {
  name                     = "privatelink.azurecr.io"
  resource_group_name      = "my_resource_group"
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_zone_link" {
  name                  = "link_acr"
  resource_group_name   = "my_resource_group"
  private_dns_zone_name = azurerm_private_dns_zone.acr_zone.name
  virtual_network_id    = azurerm_virtual_network.amlvnet.id
}

resource "azurerm_private_endpoint" "acr_ep" {
  name                = "acr_pe"
  resource_group_name = "my_resource_group"
  location            = "eastasia"
  subnet_id           = azurerm_subnet.aml_subnet.id

  private_service_connection {
    name                           = "acr_psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-app-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_zone.id]
  }
}
```

In the meantime, you should ensure that the Azure Container Registry has a contributor role for the system assigned managed identity of Azure Machine Learning workspace.

#### Use Compute Cluster/Instance in VNet
When putting an Azure Machine Learning compute cluster/instance into a VNet, you need to create network security group (NSG) for its subnet. This NSG contains the following rules, which are specific to the compute cluster/instance:
* Allow inbound TCP traffic on ports 29876-29877 from the BatchNodeManagement service tag.
* Allow inbound TCP traffic on port 44224 from the AzureMachineLearning service tag.

The screen shot of 'Inbound Security Rules' of the NSG of the AML computer cluster's subnet should look like:
![Compute Cluster NSG](./images/ns_comp_nsg.png)

Please also note that for the compute cluster or instance, it is now possible to remove the public IP address (a preview feature). This provides better protection of your compute resources in the MLOps solution.

## Summary
This article introduces how to use the Azure services and technologies including Azure Virtual Network, Azure Private Link, VNet Peering to protect a MLOps solution. And then it illustrates how to access the resources protected by the VNet. The article also covers the topics of how to use Azure Pipeline, Azure Container Registry and compute cluster/instances in the MLOps solution.

## References
* [MLOps](https://en.wikipedia.org/wiki/MLOps)
* [Machine learning operations (MLOps) framework to upscale machine learning lifecycle with Azure Machine Learning](https://docs.microsoft.com/en-us/azure/architecture/example-scenario/mlops/mlops-technical-paper)
* [Secure an Azure Machine Learning workspace with virtual networks](https://docs.microsoft.com/en-us/azure/machine-learning/how-to-secure-workspace-vnet?tabs=pe)
* [Azure Machine Learning Enterprise Terraform Example
](https://github.com/csiebler/azure-machine-learning-terraform)
* [Azure Virtual Network Pricing](https://azure.microsoft.com/en-us/pricing/details/virtual-network/)
* [Azure Pipelines agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser)
* [Azure DevOps Pricing](https://azure.microsoft.com/en-us/pricing/details/devops/azure-devops-services)
