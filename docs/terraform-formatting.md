# Terraform Formatting Quick Fix

If you encounter formatting errors in the GitHub Actions workflow, follow these steps:

## Option 1: Using PowerShell Script (Windows)

```powershell
# Run the formatting script
.\scripts\format.ps1
```

## Option 2: Manual Terraform Command

```bash
# Format all files recursively
terraform fmt -recursive

# Check if all files are formatted
terraform fmt -check -recursive
```

## Option 3: Format Specific Directory

```bash
# Format only modules
terraform fmt -recursive modules/

# Format only environments
terraform fmt -recursive environments/
```

## Common Formatting Issues

### Extra Spaces After Braces
```hcl
# ❌ Wrong
variable "example" { 
  type = string
}

# ✅ Correct
variable "example" {
  type = string
}
```

### Inconsistent Indentation
```hcl
# ❌ Wrong
resource "azurerm_resource_group" "example" {
name     = "example"
  location = "eastus"
}

# ✅ Correct
resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "eastus"
}
```

### Alignment Issues
```hcl
# ❌ Wrong
variable "location" { type = string, description = "Region" }

# ✅ Correct
variable "location" {
  type        = string
  description = "Region"
}
```

## Pre-Commit Hook (Optional)

Add this to `.git/hooks/pre-commit` to auto-format before commits:

```bash
#!/bin/sh
terraform fmt -recursive
git add -A .
```

Then make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Terraform Format Options

- `-recursive` - Format files in subdirectories
- `-check` - Check if formatting is needed (exit 1 if needed)
- `-diff` - Show formatting changes
- `-write=false` - Don't write changes, just show diff

## After Formatting

1. Review the changes
2. Commit the formatted files:
```bash
git add .
git commit -m "chore: format Terraform files"
git push
```

3. Re-run the GitHub Actions workflow
