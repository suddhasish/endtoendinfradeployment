package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// GetBaselineOptions returns common Terraform options for testing
func GetBaselineOptions(t *testing.T, terraformDir string) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		NoColor:      true,
		Vars: map[string]interface{}{
			"location": "eastus",
		},
		EnvVars: map[string]string{
			"ARM_CLIENT_ID":       os.Getenv("ARM_CLIENT_ID"),
			"ARM_CLIENT_SECRET":   os.Getenv("ARM_CLIENT_SECRET"),
			"ARM_SUBSCRIPTION_ID": os.Getenv("ARM_SUBSCRIPTION_ID"),
			"ARM_TENANT_ID":       os.Getenv("ARM_TENANT_ID"),
		},
	})
}

// CleanupOptions provides consistent cleanup across tests
func CleanupOptions(t *testing.T, terraformOptions *terraform.Options) {
	terraform.Destroy(t, terraformOptions)
}
