# Enterprise Azure Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Production-ready Terraform infrastructure for deploying enterprise-grade Azure resources following the **Azure Well-Architected Framework** with hub-spoke network topology, comprehensive security, and multi-environment support.

## 🏗️ Architecture

This repository implements a **hub-spoke network topology** with the following components:

### Core Infrastructure
- **Hub Virtual Network** - Central connectivity hub with shared services
- **Spoke Virtual Networks** - Isolated workload networks per environment
- **VNet Peering** - Hub-to-spoke connectivity with gateway transit
- **Private DNS Zones** - For all Azure PaaS services

### Compute & Containers
- **Azure Kubernetes Service (AKS)** - Private cluster with:
  - Application Gateway Ingress Controller (AGIC)
  - Azure Policy Add-on
  - Microsoft Defender for Containers
  - Workload Identity (OIDC)
  - Auto-scaling node pools
  - Container Insights monitoring

### Networking & Security
- **Application Gateway v2** - WAF-enabled ingress with:
  - OWASP 3.2 ruleset
  - Bot Manager rules
  - Auto-scaling (2-10 instances)
  - Custom health probes
- **Azure Front Door Standard/Premium** - Global load balancer with WAF
- **Network Security Groups (NSGs)** - Applied to all subnets
- **Private Endpoints** - For all PaaS services (Storage, SQL, Key Vault, AKS)

### Data & Storage
- **Azure SQL Database** - With:
  - Transparent Data Encryption (TDE) with CMK
  - Private endpoint
  - Azure AD authentication
  - Auditing and threat detection
  - Vulnerability assessment
- **Storage Accounts** - With:
  - Customer-Managed Keys (CMK) encryption
  - Blob versioning and soft delete
  - Lifecycle management policies
  - Private endpoints (blob & file)

### Security & Governance
- **Azure Key Vault** - With:
  - RBAC authorization model
  - Private endpoint
  - Purge protection and soft delete
  - Diagnostic logging
  - CMK key generation with auto-rotation

### Monitoring & Observability
- **Log Analytics Workspace** - Centralized logging
- **Application Insights** - Application telemetry
- **Container Insights** - AKS monitoring
- **Diagnostic Settings** - On all resources

## 📁 Repository Structure

```
.
├── modules/                          # Reusable Terraform modules
│   ├── networking/                   # Hub-spoke VNets, NSGs, DNS zones
│   ├── monitoring/                   # Log Analytics, App Insights
│   ├── aks/                         # AKS with AGIC and security addons
│   ├── application-gateway/         # App Gateway v2 with WAF
│   ├── frontdoor/                   # Azure Front Door Premium
│   ├── keyvault/                    # Key Vault with RBAC
│   ├── storage/                     # Storage with encryption
│   ├── sql-database/                # SQL Database with private endpoint
│   └── private-endpoint/            # Private endpoint helper module
├── environments/                     # Environment-specific configurations
│   ├── dev/                         # Development
│   ├── qa/                          # Quality Assurance
│   ├── stg/                         # Staging
│   └── prod/                        # Production
├── .github/workflows/               # CI/CD pipelines
│   └── terraform-deploy.yml         # Multi-environment deployment workflow
├── scripts/                         # Helper scripts
│   ├── setup-backend.sh            # Backend storage setup
│   ├── validate.sh                 # Terraform validation
│   └── cleanup.sh                  # Resource cleanup
├── tests/                           # Terratest integration tests
│   ├── integration_test.go         # Full infrastructure tests
│   ├── networking_test.go          # Network module tests
│   └── aks_test.go                 # AKS module tests
└── docs/                            # Documentation
    └── deployment_guide.md          # Detailed deployment guide
```

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.6.0
- **Azure CLI** >= 2.50.0
- **Azure Subscription** with Contributor access
- **Git** for version control
- **(Optional)** Go >= 1.21 for running tests

### 1. Clone Repository

```bash
git clone <repository-url>
cd terraform_project_filled_complete
```

### 2. Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Create service principal for Terraform
az ad sp create-for-rbac --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

### 3. Setup Backend Storage

```bash
# Initialize backend for development
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh dev eastus

# For other environments
./scripts/setup-backend.sh qa eastus
./scripts/setup-backend.sh stg eastus
./scripts/setup-backend.sh prod eastus
```

### 4. Configure Variables

Edit `environments/dev/terraform.tfvars`:

```hcl
prefix                     = "dev"
location                   = "eastus"
project_name               = "myapp"
cost_center                = "IT-Development"
random_suffix              = "dev01"

# AKS Configuration
aks_node_count             = 2
aks_admin_group_object_ids = ["<your-aad-group-id>"]

# SQL Configuration
sql_administrator_login    = "sqladmin"
sql_administrator_password = "<secure-password>"  # Use Key Vault!
sql_database_name          = "appdb"

# Key Vault
keyvault_admin_object_ids  = ["<your-aad-user-id>"]
```

### 5. Deploy Infrastructure

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Review plan
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### 6. Access Resources

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group dev-rg-workload \
  --name dev-aks

# Verify cluster access
kubectl get nodes

# Get SQL connection string (stored in Key Vault)
az keyvault secret show \
  --vault-name dev-kv-dev01 \
  --name sql-admin-password-dev \
  --query value -o tsv
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The repository includes a comprehensive CI/CD pipeline with:

- ✅ **Security Scanning** (Trivy, Checkov, TFSec)
- ✅ **Terraform Validation** (fmt, validate, TFLint)
- ✅ **Multi-Environment Planning** (matrix strategy)
- ✅ **Automated Testing** (Terratest)
- ✅ **Controlled Deployment** (manual approval for prod)
- ✅ **Infrastructure Destroy** (single or all environments)
- ✅ **Post-Deployment Validation**

### Manual Workflow Dispatch

Trigger deployments or destroy operations manually via GitHub Actions:

```
Actions → Terraform CI/CD → Run workflow
  - Environment: DEV, QA, STG, PROD, or all
  - Action: plan, apply, or destroy
```

**Destroy Operations:**
- Single environment: Destroys selected environment with manual approval
- All environments: Sequential destroy (PROD → STG → QA → DEV) for safety

### Required GitHub Secrets

Configure these secrets in your repository:

```
AZURE_CLIENT_ID          # Service Principal Application ID
AZURE_CLIENT_SECRET      # Service Principal Secret
AZURE_SUBSCRIPTION_ID    # Azure Subscription ID
AZURE_TENANT_ID          # Azure AD Tenant ID
```

### Deployment Strategy

```
feature/*  → Plan only (PR validation)
    ↓
develop    → Auto-deploy to DEV
    ↓
release/*  → Auto-deploy to STG
    ↓
main       → Manual approval → PROD
```

## 🧪 Testing

### Run Terratest

```bash
cd tests

# Initialize Go modules
go mod download

# Run all tests
go test -v -timeout 90m

# Run specific test
go test -v -run TestNetworkingModule -timeout 30m

# Run with parallel execution
go test -v -parallel 4 -timeout 120m
```

### Validation Scripts

```bash
# Validate Terraform configuration
./scripts/validate.sh

# Cleanup test resources
./scripts/cleanup.sh test
```

## 📊 Key Features

### Security
✅ All PaaS services with private endpoints  
✅ Network security groups on all subnets  
✅ WAF policies on Application Gateway and Front Door  
✅ TLS 1.2 minimum on all services  
✅ RBAC on AKS and Key Vault  
✅ Customer-Managed Keys (CMK) for encryption  
✅ Private AKS cluster  
✅ Azure Policy enforcement  
✅ Microsoft Defender for Containers  

### Reliability
✅ Multi-region capability (via Front Door)  
✅ Auto-scaling for AKS and Application Gateway  
✅ Availability zones support  
✅ Health probes and monitoring  
✅ Backup and disaster recovery configurations  

### Performance
✅ Azure Front Door for global load balancing  
✅ Application Gateway with auto-scaling  
✅ AKS with multiple node pools  
✅ Premium tier for critical services  

### Cost Optimization
✅ Storage lifecycle policies  
✅ Auto-scaling based on demand  
✅ Dev/QA resources with lower SKUs  
✅ Spot instances support for AKS user pools  

### Operational Excellence
✅ Infrastructure as Code (Terraform)  
✅ GitOps workflow with GitHub Actions  
✅ Centralized logging and monitoring  
✅ Diagnostic settings on all resources  
✅ Comprehensive tagging strategy  

## 📖 Documentation

- [Deployment Guide](docs/deployment_guide.md) - Detailed step-by-step instructions
- [Module READMEs](modules/) - Individual module documentation
- [Terraform Registry Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)

## 🔧 Troubleshooting

### Common Issues

**Backend initialization fails**
```bash
# Verify backend exists
az storage account show --name sttfstatewafdev --resource-group rg-tfstate-dev

# Re-run setup
./scripts/setup-backend.sh dev eastus
```

**AKS quota exceeded**
```bash
# Check quota
az vm list-usage --location eastus --output table

# Request increase via Azure Portal or use smaller VMs
```

**Private DNS not resolving**
```bash
# Verify DNS zone links
az network private-dns link vnet list \
  --resource-group dev-rg-hub \
  --zone-name privatelink.vaultcore.azure.net
```

See [Deployment Guide](docs/deployment_guide.md) for more troubleshooting tips.

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Run validation: `./scripts/validate.sh`
4. Run tests: `cd tests && go test -v`
5. Submit pull request
6. CI/CD will run automatically

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🎯 Roadmap

- [ ] Add Azure Container Registry (ACR) module
- [ ] Implement Azure Firewall with forced tunneling
- [ ] Add Cosmos DB module with private endpoint
- [ ] Integrate Azure DevOps Pipelines alternative
- [ ] Add disaster recovery automation
- [ ] Implement cost tracking and budgets

## 📞 Support

- 📧 Email: devops-team@example.com
- 💬 Teams: Azure Infrastructure Channel
- 🐛 Issues: GitHub Issues

---

**Maintained by:** DevOps Team  
**Last Updated:** January 2025  
**Version:** 2.0  

⭐ If you find this repository helpful, please consider giving it a star!
