# GitHub Secrets Configuration Guide

This document explains how to configure GitHub Secrets for the Terraform CI/CD pipeline.

## 🔒 Required Repository Secrets

These secrets must be configured at the **repository level** (Settings → Secrets and variables → Actions → Repository secrets):

| Secret Name | Description | How to Get It | Example Value |
|------------|-------------|---------------|---------------|
| `AZURE_CLIENT_ID` | Service Principal Application ID | Azure Portal → App Registrations → Your SP → Application (client) ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_CLIENT_SECRET` | Service Principal Secret | Azure Portal → App Registrations → Your SP → Certificates & secrets → New client secret | `ABC~1234567890abcdefghijklmnop` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | Azure Portal → Subscriptions → Subscription ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | Azure Portal → Azure Active Directory → Properties → Directory ID | `11111111-2222-3333-4444-555555555555` |

### How to Create Service Principal

```bash
# Login to Azure
az login

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "terraform-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID> \
  --sdk-auth

# Output will be JSON - use the values to populate secrets:
# {
#   "clientId": "<AZURE_CLIENT_ID>",
#   "clientSecret": "<AZURE_CLIENT_SECRET>",
#   "subscriptionId": "<AZURE_SUBSCRIPTION_ID>",
#   "tenantId": "<AZURE_TENANT_ID>"
# }
```

## 🌍 Required Environment Secrets

These secrets must be configured per **GitHub Environment** (Settings → Environments → Select environment → Add secret):

### For Each Environment (dev, qa, stg, prod)

| Secret Name | Type | Description | Example Value |
|------------|------|-------------|---------------|
| `TF_VAR_sql_administrator_password` | String | SQL Server admin password | `MySecureP@ssw0rd123!` |
| `TF_VAR_aks_admin_group_object_ids` | JSON Array | Azure AD group IDs for AKS admin access | `["12345678-abcd-1234-abcd-123456789012"]` |
| `TF_VAR_keyvault_admin_object_ids` | JSON Array | Azure AD object IDs for Key Vault administrators | `["87654321-dcba-4321-dcba-210987654321"]` |

### Important Notes

1. **JSON Array Format**: For list variables, use JSON array syntax:
   ```json
   ["guid-1", "guid-2", "guid-3"]
   ```

2. **Password Requirements**: SQL Server passwords must meet complexity requirements:
   - At least 8 characters
   - Contains uppercase letters
   - Contains lowercase letters
   - Contains numbers
   - Contains special characters

3. **Getting Azure AD Object IDs**:
   ```bash
   # For a user
   az ad user show --id user@domain.com --query objectId -o tsv
   
   # For a group
   az ad group show --group "AKS Admins" --query objectId -o tsv
   
   # For your current user
   az ad signed-in-user show --query objectId -o tsv
   ```

## 📝 Step-by-Step Setup

### 1. Configure Repository Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each of the 4 Azure authentication secrets

### 2. Create GitHub Environments

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Create environments: `dev`, `qa`, `stg`, `prod`
4. For `prod`, enable **Required reviewers** and add approvers

### 3. Configure Environment Secrets

For **each environment** (dev, qa, stg, prod):

1. Click on the environment name
2. Click **Add secret**
3. Add the three `TF_VAR_*` secrets with appropriate values for that environment

Example for `dev` environment:
- `TF_VAR_sql_administrator_password` = `Dev-SecureP@ss123!`
- `TF_VAR_aks_admin_group_object_ids` = `["<your-dev-admin-group-id>"]`
- `TF_VAR_keyvault_admin_object_ids` = `["<your-user-object-id>"]`

### 4. Verify Configuration

Run the GitHub Actions workflow manually:
1. Go to **Actions** tab
2. Select **Terraform CI/CD - Multi-Environment Deployment**
3. Click **Run workflow**
4. Select environment: `dev`
5. Select action: `plan`
6. Click **Run workflow**

The workflow should successfully authenticate and create a plan without errors.

## 🔐 Security Best Practices

✅ **Never commit secrets to Git** - All sensitive values are in GitHub Secrets  
✅ **Use different passwords per environment** - Minimize blast radius  
✅ **Rotate secrets regularly** - Update every 90 days  
✅ **Use strong passwords** - Minimum 16 characters with complexity  
✅ **Enable MFA** - On all Azure AD accounts with elevated permissions  
✅ **Audit access** - Regularly review who has access to secrets  
✅ **Use managed identities** - Where possible instead of service principals  

## 🆘 Troubleshooting

### Error: "sql_administrator_password" is required
**Cause**: Environment secret not set or has wrong name  
**Solution**: Verify the secret name is exactly `TF_VAR_sql_administrator_password`

### Error: Invalid value for aks_admin_group_object_ids
**Cause**: Invalid JSON array format  
**Solution**: Use proper JSON syntax: `["guid1","guid2"]` (no spaces after commas)

### Error: Failed to authenticate with Azure
**Cause**: Repository secrets are incorrect or expired  
**Solution**: Recreate the service principal and update all 4 Azure secrets

### Error: Access denied to Key Vault
**Cause**: Object IDs are incorrect or user doesn't exist  
**Solution**: Verify object IDs with `az ad user show` or `az ad group show`

## 📚 Additional Resources

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Azure Service Principals](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Terraform Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)

---

**Last Updated:** October 2025  
**Maintainer:** DevOps Team
