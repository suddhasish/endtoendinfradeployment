
#!/usr/bin/env bash
set -euo pipefail

echo "================================================"
echo "Terraform Validation Script"
echo "================================================"

# Default to dev environment
TF_DIR=${1:-environments/dev}

echo "Validating: $TF_DIR"
echo "================================================"

# Format check
echo "1. Checking Terraform formatting..."
if terraform fmt -check -recursive; then
    echo "✅ All files are properly formatted"
else
    echo "❌ Formatting issues found. Run 'terraform fmt -recursive' to fix"
    exit 1
fi

# Initialize
echo ""
echo "2. Initializing Terraform..."
cd "$TF_DIR"
terraform init -backend=false

# Validate
echo ""
echo "3. Validating Terraform configuration..."
terraform validate

echo ""
echo "================================================"
echo "✅ Validation completed successfully!"
echo "================================================"
