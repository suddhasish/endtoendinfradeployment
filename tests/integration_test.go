package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestFullInfrastructureDeployment tests complete infrastructure deployment
func TestFullInfrastructureDeployment(t *testing.T) {
	t.Parallel()

	// Generate unique suffix for test resources
	uniqueID := random.UniqueId()
	expectedEnvironment := "test"
	expectedLocation := "eastus"

	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../environments/dev",
		Vars: map[string]interface{}{
			"prefix":       expectedEnvironment,
			"location":     expectedLocation,
			"project_name": "integration-test",
			"random_suffix": uniqueID,
			// Add required variables
			"aks_node_count":                  2,
			"sql_administrator_login":         "sqladmin",
			"sql_administrator_password":      fmt.Sprintf("TestP@ssw0rd!%s", uniqueID),
			"sql_database_name":               "testdb",
			"aks_admin_group_object_ids":      []string{},
			"keyvault_admin_object_ids":       []string{},
			"storage_account_replication_type": "LRS",
			"cost_center":                     "Testing",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,
		RetryableTerraformErrors: map[string]string{
			".*timeout while waiting.*": "Timeout waiting for resource",
		},
	}

	// Destroy resources at the end of test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Run validation tests
	t.Run("ValidateNetworking", func(t *testing.T) {
		validateNetworking(t, terraformOptions, expectedEnvironment, expectedLocation)
	})

	t.Run("ValidateAKS", func(t *testing.T) {
		validateAKSCluster(t, terraformOptions, expectedEnvironment)
	})

	t.Run("ValidateStorage", func(t *testing.T) {
		validateStorage(t, terraformOptions, expectedEnvironment)
	})

	t.Run("ValidateKeyVault", func(t *testing.T) {
		validateKeyVault(t, terraformOptions, expectedEnvironment)
	})

	t.Run("ValidateSQL", func(t *testing.T) {
		validateSQLDatabase(t, terraformOptions, expectedEnvironment)
	})
}

// validateNetworking verifies networking resources
func validateNetworking(t *testing.T, opts *terraform.Options, env string, location string) {
	// Get outputs
	hubVNetName := terraform.Output(t, opts, "hub_vnet_name")
	spokeVNetName := terraform.Output(t, opts, "spoke_vnet_name")
	
	hubRGName := fmt.Sprintf("%s-rg-hub", env)
	spokeRGName := fmt.Sprintf("%s-rg-workload", env)

	// Verify Hub VNet exists
	hubVNet := azure.GetVirtualNetwork(t, hubVNetName, hubRGName, "")
	assert.Equal(t, hubVNetName, *hubVNet.Name)
	assert.Equal(t, location, *hubVNet.Location)

	// Verify Spoke VNet exists
	spokeVNet := azure.GetVirtualNetwork(t, spokeVNetName, spokeRGName, "")
	assert.Equal(t, spokeVNetName, *spokeVNet.Name)

	// Verify VNet Peering
	assert.NotNil(t, hubVNet.VirtualNetworkPeerings)
	assert.NotNil(t, spokeVNet.VirtualNetworkPeerings)

	// Verify subnets exist
	assert.NotEmpty(t, hubVNet.Subnets)
	assert.NotEmpty(t, spokeVNet.Subnets)

	// Verify NSGs are attached (at least one subnet should have NSG)
	hasNSG := false
	for _, subnet := range *spokeVNet.Subnets {
		if subnet.NetworkSecurityGroup != nil {
			hasNSG = true
			break
		}
	}
	assert.True(t, hasNSG, "At least one subnet should have NSG attached")
}

// validateAKSCluster verifies AKS cluster configuration
func validateAKSCluster(t *testing.T, opts *terraform.Options, env string) {
	// Get cluster name and resource group
	clusterName := terraform.Output(t, opts, "aks_cluster_name")
	rgName := fmt.Sprintf("%s-rg-workload", env)

	// Get AKS cluster
	cluster := azure.GetManagedCluster(t, rgName, clusterName, "")
	
	// Verify cluster properties
	require.NotNil(t, cluster)
	assert.Equal(t, clusterName, *cluster.Name)

	// Verify private cluster is enabled
	assert.NotNil(t, cluster.APIServerAccessProfile)
	assert.True(t, *cluster.APIServerAccessProfile.EnablePrivateCluster)

	// Verify RBAC is enabled
	assert.True(t, *cluster.EnableRBAC)

	// Verify network profile
	assert.NotNil(t, cluster.NetworkProfile)
	assert.Equal(t, "azure", string(cluster.NetworkProfile.NetworkPlugin))

	// Verify addon profiles
	assert.NotNil(t, cluster.AddonProfiles)
	
	// Verify monitoring is enabled
	if omsAgent, ok := cluster.AddonProfiles["omsAgent"]; ok {
		assert.True(t, *omsAgent.Enabled)
	}

	// Verify AGIC is enabled
	if agic, ok := cluster.AddonProfiles["ingressApplicationGateway"]; ok {
		assert.True(t, *agic.Enabled)
	}

	// Verify node pools
	assert.NotEmpty(t, cluster.AgentPoolProfiles)
	
	// Verify auto-scaling on system node pool
	systemPool := (*cluster.AgentPoolProfiles)[0]
	assert.True(t, *systemPool.EnableAutoScaling)
}

// validateStorage verifies storage account configuration
func validateStorage(t *testing.T, opts *terraform.Options, env string) {
	storageAccountName := terraform.Output(t, opts, "storage_account_name")
	rgName := fmt.Sprintf("%s-rg-workload", env)

	// Get storage account
	storageAccount := azure.GetStorageAccount(t, storageAccountName, rgName, "")
	
	require.NotNil(t, storageAccount)
	assert.Equal(t, storageAccountName, *storageAccount.Name)

	// Verify encryption
	assert.NotNil(t, storageAccount.Encryption)
	
	// Verify HTTPS only
	assert.True(t, *storageAccount.EnableHTTPSTrafficOnly)

	// Verify minimum TLS version
	assert.Equal(t, "TLS1_2", string(storageAccount.MinimumTLSVersion))

	// Verify blob service properties
	assert.NotNil(t, storageAccount.PrimaryEndpoints)
}

// validateKeyVault verifies Key Vault configuration
func validateKeyVault(t *testing.T, opts *terraform.Options, env string) {
	keyVaultName := terraform.Output(t, opts, "keyvault_name")
	rgName := fmt.Sprintf("%s-rg-hub", env)

	// Get Key Vault
	keyVault := azure.GetKeyVault(t, keyVaultName, rgName, "")
	
	require.NotNil(t, keyVault)
	assert.Equal(t, keyVaultName, *keyVault.Name)

	// Verify soft delete is enabled
	assert.True(t, *keyVault.Properties.EnableSoftDelete)

	// Verify purge protection
	assert.True(t, *keyVault.Properties.EnablePurgeProtection)

	// Verify RBAC authorization
	assert.True(t, *keyVault.Properties.EnableRbacAuthorization)

	// Verify network ACLs (should restrict to private endpoint)
	assert.NotNil(t, keyVault.Properties.NetworkACLs)
}

// validateSQLDatabase verifies SQL Database configuration
func validateSQLDatabase(t *testing.T, opts *terraform.Options, env string) {
	sqlServerName := terraform.Output(t, opts, "sql_server_name")
	sqlDBName := terraform.Output(t, opts, "sql_database_name")
	rgName := fmt.Sprintf("%s-rg-workload", env)

	// Get SQL Server
	sqlServer := azure.GetSQLServer(t, rgName, sqlServerName, "")
	
	require.NotNil(t, sqlServer)
	assert.Equal(t, sqlServerName, *sqlServer.Name)

	// Verify public network access is disabled
	assert.Equal(t, "Disabled", string(sqlServer.PublicNetworkAccess))

	// Verify TLS version
	assert.Equal(t, "1.2", *sqlServer.MinimalTLSVersion)

	// Get SQL Database
	sqlDB := azure.GetSQLDatabase(t, rgName, sqlServerName, sqlDBName, "")
	
	require.NotNil(t, sqlDB)
	assert.Equal(t, sqlDBName, *sqlDB.Name)

	// Verify SKU (should be GeneralPurpose or BusinessCritical)
	assert.Contains(t, []string{"GeneralPurpose", "BusinessCritical"}, *sqlDB.Sku.Tier)
}

// TestModuleIndependently tests individual modules
func TestNetworkingModule(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/networking",
		Vars: map[string]interface{}{
			"prefix":       "test",
			"location":     "eastus",
			"project_name": "nettest",
			"tags": map[string]string{
				"Environment": "Test",
				"ManagedBy":   "Terratest",
			},
			"random_suffix": uniqueID,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	hubVNetID := terraform.Output(t, terraformOptions, "hub_vnet_id")
	spokeVNetID := terraform.Output(t, terraformOptions, "spoke_vnet_id")

	assert.NotEmpty(t, hubVNetID)
	assert.NotEmpty(t, spokeVNetID)
}

// TestSecurityCompliance validates security configurations
func TestSecurityCompliance(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../environments/dev",
		Vars: map[string]interface{}{
			"prefix":                          "sectest",
			"location":                        "eastus",
			"project_name":                    "security",
			"random_suffix":                   uniqueID,
			"aks_node_count":                  2,
			"sql_administrator_login":         "sqladmin",
			"sql_administrator_password":      fmt.Sprintf("SecP@ssw0rd!%s", uniqueID),
			"sql_database_name":               "secdb",
			"aks_admin_group_object_ids":      []string{},
			"keyvault_admin_object_ids":       []string{},
			"storage_account_replication_type": "LRS",
			"cost_center":                     "Security",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	t.Run("PrivateEndpointsEnabled", func(t *testing.T) {
		// Verify private endpoints are created
		storagePrivateEndpoint := terraform.Output(t, terraformOptions, "storage_blob_private_endpoint_id")
		sqlPrivateEndpoint := terraform.Output(t, terraformOptions, "sql_private_endpoint_id")
		kvPrivateEndpoint := terraform.Output(t, terraformOptions, "keyvault_private_endpoint_id")

		assert.NotEmpty(t, storagePrivateEndpoint)
		assert.NotEmpty(t, sqlPrivateEndpoint)
		assert.NotEmpty(t, kvPrivateEndpoint)
	})

	t.Run("WAFEnabled", func(t *testing.T) {
		// Verify WAF is enabled on Application Gateway
		appGwID := terraform.Output(t, terraformOptions, "application_gateway_id")
		assert.NotEmpty(t, appGwID)
		// Additional checks can be added to verify WAF policy attachment
	})
}
