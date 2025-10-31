# Format all Terraform files
# This script requires Terraform to be installed and available in PATH

Write-Host "Formatting Terraform files..." -ForegroundColor Cyan

# Check if terraform is available
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Terraform from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Get current location
$rootPath = Split-Path -Parent $PSScriptRoot

# Change to root directory
Push-Location $rootPath

try {
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
    
    # Run terraform fmt
    Write-Host "`nRunning terraform fmt -recursive..." -ForegroundColor Cyan
    terraform fmt -recursive
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ All Terraform files formatted successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Terraform fmt failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
    # Check for any remaining issues
    Write-Host "`nChecking for formatting issues..." -ForegroundColor Cyan
    $checkResult = terraform fmt -check -recursive
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ No formatting issues found!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some files still need formatting:" -ForegroundColor Yellow
        Write-Host $checkResult
    }
}
finally {
    # Return to original location
    Pop-Location
}

Write-Host "`nDone! You can now commit the formatted files." -ForegroundColor Cyan
