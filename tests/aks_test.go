
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestAKS(t *testing.T) {
  t.Parallel()
  opts := &terraform.Options{
    TerraformDir: "../environments/dev",
  }
  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)
  out := terraform.Output(t, opts, "aks_cluster_name")
  assert.NotEmpty(t, out)
}
