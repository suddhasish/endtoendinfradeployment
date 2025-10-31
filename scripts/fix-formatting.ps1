# Simple Terraform Formatter (Whitespace Only)
# This script fixes common formatting issues without requiring Terraform

$files = @(
    "environments/dev/main.tf",
    "environments/dev/terraform.tfvars",
    "environments/dev/variables.tf",
    "environments/qa/main.tf",
    "environments/qa/terraform.tfvars",
    "environments/qa/variables.tf",
    "environments/stg/main.tf",
    "environments/stg/terraform.tfvars",
    "environments/stg/variables.tf",
    "environments/prod/main.tf",
    "environments/prod/terraform.tfvars",
    "environments/prod/variables.tf",
    "modules/aks/main.tf",
    "modules/aks/variables.tf",
    "modules/application-gateway/main.tf",
    "modules/application-gateway/outputs.tf",
    "modules/application-gateway/variables.tf",
    "modules/frontdoor/main.tf",
    "modules/frontdoor/variables.tf",
    "modules/keyvault/main.tf",
    "modules/keyvault/outputs.tf",
    "modules/keyvault/variables.tf",
    "modules/networking/main.tf",
    "modules/networking/variables.tf",
    "modules/sql-database/main.tf",
    "modules/storage/outputs.tf",
    "modules/storage/variables.tf"
)

$rootPath = Split-Path -Parent $PSScriptRoot
$fixedCount = 0

Write-Host "Fixing Terraform formatting issues..." -ForegroundColor Cyan
Write-Host "Root path: $rootPath" -ForegroundColor Gray
Write-Host ""

foreach ($file in $files) {
    $fullPath = Join-Path $rootPath $file
    
    if (Test-Path $fullPath) {
        Write-Host "Processing: $file" -ForegroundColor Yellow
        
        $content = Get-Content $fullPath -Raw
        
        # Remove trailing spaces from each line
        $content = $content -replace ' +\r?\n', "`n"
        $content = $content -replace ' +$', ''
        
        # Fix specific patterns
        # Remove space after opening brace: variable "name" { 
        $content = $content -replace '(\w+\s+"[^"]+"\s+)\{\s+\r?\n', '$1{' + "`n"
        $content = $content -replace '(\w+\s+\{)\s+\r?\n', '$1' + "`n"
        
        # Save the file
        [System.IO.File]::WriteAllText($fullPath, $content)
        $fixedCount++
    }
    else {
        Write-Host "Not found: $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Fixed $fixedCount files!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the changes: git diff" -ForegroundColor White
Write-Host "2. Commit: git add . && git commit -m 'chore: fix terraform formatting'" -ForegroundColor White
Write-Host "3. Push: git push origin master" -ForegroundColor White
