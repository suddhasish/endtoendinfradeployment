
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestNetworking(t *testing.T) {
  t.Parallel()
  opts := &terraform.Options{
    TerraformDir: "../environments/dev",
  }
  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)
  // basic assertion: outputs exist
  out := terraform.Output(t, opts, "hub_rg_name")
  assert.NotEmpty(t, out)
}
