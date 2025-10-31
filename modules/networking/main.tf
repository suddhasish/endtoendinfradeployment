
resource "azurerm_resource_group" "hub" {
  name     = "${var.prefix}-rg-hub"
  location = var.location
  tags = merge(
    var.tags,
    {
      environment = var.prefix
      tier        = "hub"
    }
  )
}

resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-vnet-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  address_space       = var.hub_address_space
  tags = merge(
    var.tags,
    {
      environment = var.prefix
      tier        = "hub"
    }
  )
}

# hub subnets
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "pe" {
  name                                   = "snet-pe"
  resource_group_name                    = azurerm_resource_group.hub.name
  virtual_network_name                   = azurerm_virtual_network.hub.name
  address_prefixes                       = ["10.0.1.0/24"]
  private_endpoint_network_policies      = "Disabled"
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.3.0/26"]
}

# Network Security Groups
resource "azurerm_network_security_group" "appgw" {
  name                = "${var.prefix}-nsg-appgw"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name

  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

resource "azurerm_network_security_group" "pe" {
  name                = "${var.prefix}-nsg-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

# Link Private DNS Zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "${var.prefix}-keyvault-hub-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_hub" {
  name                  = "${var.prefix}-storage-blob-hub-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_hub" {
  name                  = "${var.prefix}-storage-file-hub-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_hub" {
  name                  = "${var.prefix}-sql-hub-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub" {
  name                  = "${var.prefix}-aks-hub-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

# create spoke resource groups and VNets
resource "azurerm_resource_group" "spoke_rg" {
  for_each = var.spokes
  name     = "${var.prefix}-rg-${each.key}"
  location = var.location
  tags = merge(
    var.tags,
    {
      environment = var.prefix
      tier        = "spoke-${each.key}"
    }
  )
}

resource "azurerm_virtual_network" "spoke" {
  for_each            = var.spokes
  name                = "${var.prefix}-vnet-${each.key}"
  resource_group_name = azurerm_resource_group.spoke_rg[each.key].name
  location            = var.location
  address_space       = each.value.address_space
  tags = merge(
    var.tags,
    {
      environment = var.prefix
      tier        = "spoke-${each.key}"
    }
  )
}

# Link Private DNS Zones to Spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  for_each              = azurerm_virtual_network.spoke
  name                  = "${var.prefix}-keyvault-${each.key}-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = each.value.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_spoke" {
  for_each              = azurerm_virtual_network.spoke
  name                  = "${var.prefix}-storage-blob-${each.key}-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = each.value.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_spoke" {
  for_each              = azurerm_virtual_network.spoke
  name                  = "${var.prefix}-storage-file-${each.key}-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = each.value.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_spoke" {
  for_each              = azurerm_virtual_network.spoke
  name                  = "${var.prefix}-sql-${each.key}-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = each.value.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_spoke" {
  for_each              = azurerm_virtual_network.spoke
  name                  = "${var.prefix}-aks-${each.key}-link"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = each.value.id
  tags                  = var.tags
}

# default subnets for AKS and DB in each spoke
resource "azurerm_subnet" "aks" {
  for_each             = azurerm_virtual_network.spoke
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.spoke_rg[each.key].name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(each.value.address_space[0], 2, 0)]
}

resource "azurerm_subnet" "db" {
  for_each                              = azurerm_virtual_network.spoke
  name                                  = "snet-db"
  resource_group_name                   = azurerm_resource_group.spoke_rg[each.key].name
  virtual_network_name                  = each.value.name
  address_prefixes                      = [cidrsubnet(each.value.address_space[0], 4, 8)]
  private_endpoint_network_policies     = "Disabled"
}

# Network Security Groups for Spoke Subnets
resource "azurerm_network_security_group" "aks" {
  for_each            = azurerm_virtual_network.spoke
  name                = "${var.prefix}-nsg-aks-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg[each.key].name

  security_rule {
    name                       = "AllowLoadBalancer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  for_each                  = azurerm_subnet.aks
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.aks[each.key].id
}

resource "azurerm_network_security_group" "db" {
  for_each            = azurerm_virtual_network.spoke
  name                = "${var.prefix}-nsg-db-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg[each.key].name

  security_rule {
    name                       = "AllowAKS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefixes    = azurerm_subnet.aks[each.key].address_prefixes
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "db" {
  for_each                  = azurerm_subnet.db
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.db[each.key].id
}

# vnet peering hub -> spokes and spokes -> hub
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                     = azurerm_virtual_network.spoke
  name                         = "${azurerm_virtual_network.hub.name}-to-${each.value.name}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = each.value.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                     = azurerm_virtual_network.spoke
  name                         = "${each.value.name}-to-${azurerm_virtual_network.hub.name}"
  resource_group_name          = azurerm_resource_group.spoke_rg[each.key].name
  virtual_network_name         = each.value.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}
