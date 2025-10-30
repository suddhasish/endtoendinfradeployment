
resource "azurerm_private_endpoint" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.rg.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = var.private_service_connection["name"]
    is_manual_connection           = false
    private_connection_resource_id = var.private_service_connection["resource_id"]
    subresource_names              = var.private_service_connection["subresource_names"]
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}
