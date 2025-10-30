
#!/usr/bin/env bash
set -euo pipefail
TF_DIR=${1:-environments/dev}
cd "$TF_DIR"
terraform init -backend=false
terraform fmt -check
terraform validate
