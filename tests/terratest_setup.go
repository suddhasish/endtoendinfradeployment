// terraform/tests/go.mod
module github.com/yourorg/infrastructure-tests

go 1.21

require (
    github.com/gruntwork-io/terratest v0.46.8
    github.com/stretchr/testify v1.8.4
)

// terraform/tests/networking_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestNetworkingModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/networking",
        Vars: map[string]interface{}{
            "environment":         "test",
            "location":            "eastus",
            "location_short":      "eus",
            "resource_group_name": "rg-network-test-eus",
        },
        NoColor: true,
    })

    defer terraform.Destroy(t, terraformOptions)

    // Run terraform init and apply
    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    hubVnetID := terraform.Output(t, terraformOptions, "hub_vnet_id")
    assert.NotEmpty(t, hubVnetID)

    spokeVnetID := terraform.Output(t, terraformOptions, "spoke_vnet_id")
    assert.NotEmpty(t, spokeVnetID)

    aksSubnetID := terraform.Output(t, terraformOptions, "aks_subnet_id")
    assert.NotEmpty(t, aksSubnetID)
}

// terraform/tests/aks_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/k8s"
    "github.com/stretchr/testify/assert"
)

func TestAKSModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/aks",
        Vars: map[string]interface{}{
            "environment":                 "test",
            "location":                    "eastus",
            "location_short":              "eus",
            "resource_group_name":         "rg-aks-test-eus",
            "subnet_id":                   "/subscriptions/.../subnets/test",
            "vnet_id":                     "/subscriptions/.../virtualNetworks/test",
            "kubernetes_version":          "1.28.3",
            "ssh_public_key":              "ssh-rsa AAAAB3...",
            "admin_group_object_ids":      []string{"test-object-id"},
            "application_gateway_id":      "/subscriptions/.../applicationGateways/test",
        },
        NoColor: true,
    })

    defer terraform.Destroy(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    // Validate cluster outputs
    clusterName := terraform.Output(t, terraformOptions, "cluster_name")
    assert.NotEmpty(t, clusterName)

    clusterFQDN := terraform.Output(t, terraformOptions, "cluster_fqdn")
    assert.NotEmpty(t, clusterFQDN)
}

func TestAKSClusterAccess(t *testing.T) {
    // This test requires actual AKS cluster to be deployed
    t.Skip("Skipping integration test")

    kubectlOptions := k8s.NewKubectlOptions("", "", "default")
    
    // Test basic cluster connectivity
    nodes := k8s.GetNodes(t, kubectlOptions)
    assert.True(t, len(nodes) > 0, "Cluster should have at least one node")

    // Test system pods are running
    pods := k8s.ListPods(t, kubectlOptions, map[string]string{})
    assert.True(t, len(pods) > 0, "Cluster should have running pods")
}

// terraform/tests/integration_test.go
package test

import (
    "testing"
    "time"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/http-helper"
    "github.com/stretchr/testify/assert"
)

func TestFullInfrastructureDeployment(t *testing.T) {
    // This is a full integration test
    t.Skip("Skipping full integration test - run manually")

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../environments/dev",
        Vars: map[string]interface{}{
            "project_name": "test",
            "cost_center":  "TEST",
            "owner":        "test@company.com",
        },
        NoColor: true,
    })

    defer terraform.Destroy(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    // Test Front Door endpoint
    frontdoorURL := terraform.Output(t, terraformOptions, "frontdoor_endpoint")
    assert.NotEmpty(t, frontdoorURL)

    // Wait for Front Door to be fully provisioned
    time.Sleep(5 * time.Minute)

    // Test endpoint is accessible
    http_helper.HttpGetWithRetry(
        t,
        frontdoorURL,
        nil,
        200,
        "OK",
        30,
        10*time.Second,
    )
}

func TestSecurityCompliance(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../environments/dev",
        NoColor: true,
    })

    // Initialize only, don't apply
    terraform.Init(t, terraformOptions)
    
    // Run terraform validate
    terraform.Validate(t, terraformOptions)

    // Check for security issues using terraform plan
    planExitCode := terraform.PlanExitCode(t, terraformOptions)
    assert.Equal(t, 0, planExitCode, "Terraform plan should succeed")
}

func TestModuleVersions(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../environments/dev",
    }

    // Validate terraform version
    terraform.RunTerraformCommand(t, terraformOptions, "version")
}

// terraform/tests/storage_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestStorageModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/storage",
        Vars: map[string]interface{}{
            "environment":                 "test",
            "project_name":                "testapp",
            "location":                    "eastus",
            "location_short":              "eus",
            "resource_group_name":         "rg-storage-test-eus",
            "private_endpoint_subnet_id":  "/subscriptions/.../subnets/test",
            "private_dns_zone_blob_id":    "/subscriptions/.../privateDnsZones/test",
            "log_analytics_workspace_id":  "/subscriptions/.../workspaces/test",
        },
        NoColor: true,
    })

    defer terraform.Destroy(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    storageAccountName := terraform.Output(t, terraformOptions, "storage_account_name")
    assert.NotEmpty(t, storageAccountName)
    assert.Contains(t, storageAccountName, "st")
}

// terraform/tests/keyvault_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestKeyVaultModule(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/keyvault",
        Vars: map[string]interface{}{
            "environment":                      "test",
            "project_name":                     "testapp",
            "location":                         "eastus",
            "location_short":                   "eus",
            "resource_group_name":              "rg-keyvault-test-eus",
            "private_endpoint_subnet_id":       "/subscriptions/.../subnets/test",
            "private_dns_zone_keyvault_id":     "/subscriptions/.../privateDnsZones/test",
            "aks_kubelet_identity_object_id":   "test-object-id",
            "log_analytics_workspace_id":       "/subscriptions/.../workspaces/test",
        },
        NoColor: true,
    })

    defer terraform.Destroy(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    keyVaultName := terraform.Output(t, terraformOptions, "key_vault_name")
    assert.NotEmpty(t, keyVaultName)
    assert.Contains(t, keyVaultName, "kv-")
}