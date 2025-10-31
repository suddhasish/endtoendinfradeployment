
# Public IP for Application Gateway
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones

  tags = var.tags
}

# User Assigned Identity for Application Gateway
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${var.prefix}-appgw-uai"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.prefix}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }

    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
    }
  }

  custom_rules {
    name      = "RateLimitRule"
    priority  = 1
    rule_type = "RateLimitRule"
    action    = "Block"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["0.0.0.0/0"]
    }

    rate_limit_duration  = "OneMin"
    rate_limit_threshold = 100
  }

  tags = var.tags
}

# Application Gateway
resource "azurerm_application_gateway" "this" {
  name                = "${var.prefix}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_http2        = true
  zones               = var.availability_zones
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf.id

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  autoscale_configuration {
    min_capacity = var.autoscale_min_capacity
    max_capacity = var.autoscale_max_capacity
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-public"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  frontend_port {
    name = "frontendPort80"
    port = 80
  }

  frontend_port {
    name = "frontendPort443"
    port = 443
  }

  backend_address_pool {
    name = "default-backend"
  }

  backend_http_settings {
    name                  = "default-http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30

    connection_draining {
      enabled           = true
      drain_timeout_sec = 60
    }

    probe_name = "default-health-probe"
  }

  backend_http_settings {
    name                                = "default-https-setting"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true

    connection_draining {
      enabled           = true
      drain_timeout_sec = 60
    }

    probe_name = "default-https-probe"
  }

  probe {
    name                                      = "default-health-probe"
    protocol                                  = "Http"
    path                                      = "/healthz"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    minimum_servers                           = 0
  }

  probe {
    name                                      = "default-https-probe"
    protocol                                  = "Https"
    path                                      = "/healthz"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    minimum_servers                           = 0
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-public"
    frontend_port_name             = "frontendPort80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "default-backend"
    backend_http_settings_name = "default-http-setting"
    priority                   = 100
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = var.waf_mode
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  tags = merge(
    var.tags,
    {
      environment     = var.prefix
      managed_by_agic = "true"
    }
  )

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      request_routing_rule,
      redirect_configuration,
      url_path_map,
      ssl_certificate,
      tags["managed_by_agic"]
    ]
  }
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_application_gateway.this.name}"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

