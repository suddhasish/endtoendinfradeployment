
#!/usr/bin/env bash
set -euo pipefail

# Script to bootstrap Terraform backend storage for all environments
# Usage: ./setup-backend.sh [environment] [location]
# Example: ./setup-backend.sh dev eastus

ENVIRONMENT="${1:-dev}"
LOCATION="${2:-eastus}"
RG_NAME="rg-tfstate-${ENVIRONMENT}"
SA_NAME="sttfstate${ENVIRONMENT}"
CONTAINER_NAME="tfstate"

echo "================================================"
echo "Terraform Backend Setup for ${ENVIRONMENT}"
echo "================================================"
echo "Resource Group: ${RG_NAME}"
echo "Storage Account: ${SA_NAME}"
echo "Location: ${LOCATION}"
echo "Container: ${CONTAINER_NAME}"
echo "================================================"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "✅ Using subscription: ${SUBSCRIPTION_ID}"

# Create resource group
echo "Creating resource group..."
if az group show --name "${RG_NAME}" &> /dev/null; then
    echo "⚠️  Resource group ${RG_NAME} already exists"
else
    az group create --name "${RG_NAME}" --location "${LOCATION}" --tags Environment="${ENVIRONMENT}" ManagedBy="Terraform" Purpose="TerraformState"
    echo "✅ Created resource group: ${RG_NAME}"
fi

# Create storage account
echo "Creating storage account..."
if az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" &> /dev/null; then
    echo "⚠️  Storage account ${SA_NAME} already exists"
else
    az storage account create \
        --name "${SA_NAME}" \
        --resource-group "${RG_NAME}" \
        --location "${LOCATION}" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --https-only true \
        --tags Environment="${ENVIRONMENT}" ManagedBy="Terraform" Purpose="TerraformState"
    echo "✅ Created storage account: ${SA_NAME}"
fi

# Enable versioning
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
    --account-name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --enable-versioning true \
    --enable-change-feed true

# Create container
echo "Creating storage container..."
CONN_STR=$(az storage account show-connection-string --name "${SA_NAME}" --resource-group "${RG_NAME}" -o tsv)
if az storage container exists --name "${CONTAINER_NAME}" --connection-string "${CONN_STR}" --query exists -o tsv | grep -q "true"; then
    echo "⚠️  Container ${CONTAINER_NAME} already exists"
else
    az storage container create \
        --name "${CONTAINER_NAME}" \
        --connection-string "${CONN_STR}" \
        --public-access off
    echo "✅ Created container: ${CONTAINER_NAME}"
fi

# Enable soft delete
echo "Configuring soft delete..."
az storage blob service-properties delete-policy update \
    --account-name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --enable true \
    --days-retained 30

# Lock the resource group
echo "Adding resource group lock..."
if az lock show --name "DoNotDelete" --resource-group "${RG_NAME}" &> /dev/null; then
    echo "⚠️  Lock already exists on ${RG_NAME}"
else
    az lock create \
        --name "DoNotDelete" \
        --resource-group "${RG_NAME}" \
        --lock-type CanNotDelete \
        --notes "Prevent accidental deletion of Terraform state"
    echo "✅ Added CanNotDelete lock to ${RG_NAME}"
fi

echo ""
echo "================================================"
echo "✅ Backend setup complete!"
echo "================================================"
echo ""
echo "Add the following to your backend configuration:"
echo ""
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"${RG_NAME}\""
echo "    storage_account_name = \"${SA_NAME}\""
echo "    container_name       = \"${CONTAINER_NAME}\""
echo "    key                  = \"${ENVIRONMENT}.terraform.tfstate\""
echo "  }"
echo "}"
echo ""
