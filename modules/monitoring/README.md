# Monitoring Module

This module creates a Log Analytics Workspace and Application Insights for centralized monitoring.

## Features

- Log Analytics Workspace with configurable retention
- Container Insights solution for AKS monitoring
- Security solutions for threat detection
- Application Insights for application telemetry
- Diagnostic settings for NSG flow logs

## Usage

```hcl
module "monitoring" {
  source              = "../../modules/monitoring"
  prefix              = "dev"
  location            = "eastus"
  resource_group_name = "rg-hub"
  retention_in_days   = 30
  
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Outputs

- `log_analytics_workspace_id` - Workspace ID for diagnostic settings
- `application_insights_instrumentation_key` - For application integration
