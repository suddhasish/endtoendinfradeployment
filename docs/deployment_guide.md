# Terraform Azure Hub-Spoke Deployment Guide

This guide provides step-by-step instructions for deploying enterprise-grade Azure infrastructure using Terraform with industry best practices.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Deployment Steps](#deployment-steps)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Post-Deployment](#post-deployment)
7. [Troubleshooting](#troubleshooting)

## Architecture Overview

This infrastructure deploys a hub-spoke network topology on Azure with the following components:

### Hub Resources
- **Virtual Network (Hub)**: Central connectivity point
- **Application Gateway**: WAF-enabled ingress with AGIC integration
- **Azure Bastion**: Secure VM access (optional)
- **Azure Firewall**: Network security (optional)
- **Key Vault**: Centralized secrets management with RBAC
- **Log Analytics Workspace**: Centralized monitoring and logging
- **Application Insights**: Application telemetry
- **Front Door**: Global load balancing and WAF

### Spoke Resources (per environment)
- **Virtual Network (Spoke)**: Isolated workload network
- **AKS Cluster**: Kubernetes with private endpoints, AGIC, and Azure Policy
- **SQL Database**: Private endpoint-enabled with TDE and auditing
- **Storage Account**: Private endpoints for blob and file
- **Private DNS Zones**: For private endpoint resolution

### Network Security
- **NSGs**: Applied to all subnets
- **Private Endpoints**: For all PaaS services
- **Service Endpoints**: Where applicable
- **VNet Peering**: Hub-to-spoke connectivity

## Prerequisites

### Required Tools
```bash
# Terraform >= 1.6.0
terraform version

# Azure CLI >= 2.50.0
az version

# Git
git --version

# (Optional) Go >= 1.21 for Terratest
go version
```

### Azure Requirements
1. **Azure Subscription** with appropriate permissions
2. **Service Principal** with Contributor role:
```bash
az ad sp create-for-rbac --name "terraform-sp" --role Contributor --scopes /subscriptions/{subscription-id}
```

3. **Azure AD Groups** for AKS RBAC (recommended)

### GitHub Setup
1. Fork or clone this repository
2. Configure GitHub Secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`

## Initial Setup

### Step 1: Configure Backend Storage

Run the backend setup script for each environment:

```bash
# For development environment
./scripts/setup-backend.sh dev eastus

# For QA environment
./scripts/setup-backend.sh qa eastus

# For staging environment
./scripts/setup-backend.sh stg eastus

# For production environment
./scripts/setup-backend.sh prod eastus
```

This creates:
- Resource Group: `rg-tfstate-{env}`
- Storage Account: `sttfstate{env}`
- Container: `tfstate`
- CanNotDelete lock on the resource group

### Step 2: Update Environment Variables

Edit the `terraform.tfvars` file for each environment:

```bash
# environments/dev/terraform.tfvars
prefix                     = "dev"
location                   = "eastus"
project_name               = "azureapp"
cost_center                = "IT-Development"
random_suffix              = "dev01"
aks_node_count             = 2
sql_administrator_login    = "sqladmin"
sql_administrator_password = "YourSecurePassword123!"  # Change this!
sql_database_name          = "appdb"

# Add your Azure AD group/user object IDs
aks_admin_group_object_ids    = ["your-aad-group-object-id"]
keyvault_admin_object_ids     = ["your-aad-user-object-id"]
```

**Important:** Never commit passwords to Git! Use Azure Key Vault or GitHub Secrets for sensitive values.

### Step 3: Initialize Terraform

```bash
cd environments/dev
terraform init
terraform validate
terraform fmt
```

## Deployment Steps

### Local Deployment

#### Development Environment

```bash
cd environments/dev

# Initialize
terraform init

# Review plan
terraform plan -var-file=terraform.tfvars -out=tfplan

# Apply
terraform apply tfplan

# View outputs
terraform output
```

#### Production Environment

⚠️ **Warning:** Always use CI/CD for production deployments!

```bash
cd environments/prod
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
# Review plan carefully
terraform apply tfplan
```

### Deployment Order

The modules are deployed in this dependency order:
1. **Networking** - Hub/spoke VNets, subnets, NSGs, DNS zones
2. **Monitoring** - Log Analytics, Application Insights
3. **Storage** - Storage accounts with private endpoints
4. **Key Vault** - With RBAC and CMK keys
5. **Application Gateway** - With WAF policies
6. **AKS** - With AGIC, private cluster, monitoring
7. **SQL Database** - With private endpoint and TDE
8. **Front Door** - With WAF and routing

## CI/CD Pipeline

### GitHub Actions Workflow

The repository includes a comprehensive GitHub Actions workflow:

**Workflow File:** `.github/workflows/terraform-deploy.yml`

#### Trigger Events
- **Push to main**: Deploys to production
- **Push to develop**: Deploys to development
- **Push to release/***: Deploys to staging
- **Pull Request**: Runs plan and validation only
- **Manual Dispatch**: Deploy any environment with plan/apply/destroy

#### Pipeline Stages

1. **Security Scanning**
   - Trivy (vulnerability scanning)
   - Checkov (policy compliance)
   - TFSec (Terraform security)

2. **Validation**
   - Terraform fmt check
   - TFLint
   - Terraform validate (all environments)

3. **Planning**
   - Parallel plans for all environments
   - Plan artifacts uploaded
   - PR comments with plan summary

4. **Testing**
   - Terratest integration tests
   - Module validation

5. **Apply**
   - Environment-specific deployment
   - Requires manual approval for prod
   - Outputs captured

6. **Post-Deployment**
   - Health checks
   - Validation
   - Notifications

#### Manual Deployment via GitHub Actions

1. Go to **Actions** tab
2. Select **Terraform CI/CD - Multi-Environment Deployment**
3. Click **Run workflow**
4. Select:
   - Environment (dev/qa/stg/prod)
   - Action (plan/apply/destroy)
5. Click **Run workflow**

### Branch Strategy

```
main              → Production (requires PR + approval)
  ↑
release/v1.0     → Staging (automated)
  ↑
develop          → Development (automated)
  ↑
feature/*        → Feature branches (plan only)
```

## Post-Deployment

### Access AKS Cluster

```bash
# Get credentials
az aks get-credentials --resource-group dev-rg-workload --name dev-aks

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### Configure AGIC

The Application Gateway Ingress Controller is pre-configured. Deploy an application:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

### Access SQL Database

Connection string is available in Key Vault:

```bash
# Get SQL password from Key Vault
az keyvault secret show --vault-name dev-kv-dev01 --name sql-admin-password-dev --query value -o tsv

# Connect using Azure Data Studio or SSMS
Server: dev-sql.database.windows.net
Database: appdb
Authentication: SQL Server Authentication or Azure AD
```

### Monitor Resources

- **Azure Portal**: Navigate to Log Analytics Workspace
- **Kusto Queries**: Use pre-built queries for AKS, AppGW, SQL
- **Application Insights**: View application telemetry
- **Azure Monitor**: Configure alerts and dashboards

### Verify Private Endpoints

```bash
# Check private endpoint connections
az network private-endpoint list --resource-group dev-rg-hub --output table

# Verify DNS resolution
nslookup dev-kv-dev01.vault.azure.net
# Should resolve to private IP (10.0.1.x)
```

## Troubleshooting

### Common Issues

#### Issue: Backend initialization fails
```
Error: Failed to get existing workspaces: containers.Client#ListBlobs: Failure responding to request
```

**Solution:**
```bash
# Verify backend storage exists
az storage account show --name sttfstatedev --resource-group rg-tfstate-dev

# Re-run setup script
./scripts/setup-backend.sh dev eastus
```

#### Issue: AKS creation fails with quota error
```
Error: Code="QuotaExceeded" Message="Operation could not be completed as it results in exceeding approved Total Regional Cores quota"
```

**Solution:**
```bash
# Check quota
az vm list-usage --location eastus --output table

# Request quota increase via Azure Portal
# Or use smaller VM sizes in terraform.tfvars
```

#### Issue: Private DNS resolution not working
```
Error: dial tcp: lookup xxx.database.windows.net: no such host
```

**Solution:**
```bash
# Verify private DNS zone links
az network private-dns link vnet list --resource-group dev-rg-hub --zone-name privatelink.database.windows.net

# Check private endpoint
az network private-endpoint show --name pe-dev-sql --resource-group dev-rg-workload
```

#### Issue: Application Gateway backend unhealthy
```
All backend instances are unhealthy
```

**Solution:**
```bash
# Check health probe settings
# Verify backend pool has correct IPs/FQDNs
# Check NSG rules allow traffic from AppGW subnet
# Verify application is responding on health probe path
```

### Validation Scripts

```bash
# Validate Terraform configuration
./scripts/validate.sh

# Test connectivity
./scripts/test-connectivity.sh dev

# View all outputs
cd environments/dev && terraform output
```

### Getting Help

1. Check [Terraform AzureRM Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
2. Review [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)
3. Check GitHub Issues
4. Contact DevOps team

## Security Best Practices

✅ All PaaS services use private endpoints  
✅ NSGs applied to all subnets  
✅ WAF enabled on Application Gateway and Front Door  
✅ TLS 1.2 minimum for all services  
✅ RBAC enabled on AKS and Key Vault  
✅ Diagnostic logging enabled for all resources  
✅ Secrets stored in Key Vault  
✅ CMK encryption available for data at rest  
✅ Private AKS cluster  
✅ Managed identities for authentication  

## Cost Optimization

- Use auto-scaling for AKS and App Gateway
- Enable lifecycle policies on storage accounts
- Use Azure Hybrid Benefit for VMs if applicable
- Schedule dev/qa resources to stop after hours
- Monitor with Azure Cost Management

## Maintenance

### Regular Tasks
- Review and rotate secrets monthly
- Apply Terraform and provider updates quarterly
- Review and update AKS version
- Monitor security advisories
- Backup Terraform state
- Review and optimize costs

### Update Procedure
1. Create feature branch
2. Update code
3. Run plan in dev
4. Test in dev/qa
5. Create PR
6. Review and approve
7. Merge to develop (auto-deploys to dev)
8. Test in staging
9. Merge to main (requires approval for prod)

---

**Last Updated:** January 2025  
**Version:** 2.0  
**Maintainer:** DevOps Team
