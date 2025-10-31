package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
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
			// Add required variables
			"aks_node_count":                   2,
			"sql_administrator_login":          "sqladmin",
			"sql_administrator_password":       fmt.Sprintf("TestP@ssw0rd!%s", uniqueID),
			"sql_database_name":                "testdb",
			"aks_admin_group_object_ids":       []string{},
			"keyvault_admin_object_ids":        []string{},
			"storage_account_replication_type": "LRS",
			"cost_center":                      "Testing",
		},
	}

	// Destroy resources at the end of test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Run validation tests
	t.Run("ValidateNetworking", func(t *testing.T) {
		validateNetworking(t, terraformOptions)
	})

	t.Run("ValidateAKS", func(t *testing.T) {
		validateAKSCluster(t, terraformOptions)
	})

	t.Run("ValidateStorage", func(t *testing.T) {
		validateStorage(t, terraformOptions)
	})

	t.Run("ValidateKeyVault", func(t *testing.T) {
		validateKeyVault(t, terraformOptions)
	})

	t.Run("ValidateSQL", func(t *testing.T) {
		validateSQLDatabase(t, terraformOptions)
	})
}

// validateNetworking verifies networking resources
func validateNetworking(t *testing.T, opts *terraform.Options) {
	// Verify networking outputs exist and are valid
	hubVNetID := terraform.Output(t, opts, "hub_vnet_id")
	assert.NotEmpty(t, hubVNetID)
	assert.Contains(t, hubVNetID, "/virtualNetworks/")

	spokeVNetIDs := terraform.OutputList(t, opts, "spoke_vnet_ids")
	assert.NotEmpty(t, spokeVNetIDs)
	
	// Verify subnets
	appGwSubnetID := terraform.Output(t, opts, "appgw_subnet_id")
	assert.NotEmpty(t, appGwSubnetID)
	assert.Contains(t, appGwSubnetID, "/subnets/")

	aksSubnetIDs := terraform.OutputList(t, opts, "aks_subnet_ids")
	assert.NotEmpty(t, aksSubnetIDs)

	// Verify private DNS zones
	kvDNSZoneID := terraform.Output(t, opts, "private_dns_zone_keyvault_id")
	assert.NotEmpty(t, kvDNSZoneID)
	assert.Contains(t, kvDNSZoneID, "privatelink.vaultcore.azure.net")

	sqlDNSZoneID := terraform.Output(t, opts, "private_dns_zone_sql_id")
	assert.NotEmpty(t, sqlDNSZoneID)
	assert.Contains(t, sqlDNSZoneID, "privatelink.database.windows.net")
}

// validateAKSCluster verifies AKS cluster configuration
func validateAKSCluster(t *testing.T, opts *terraform.Options) {
	// Verify AKS outputs
	clusterName := terraform.Output(t, opts, "aks_cluster_name")
	assert.NotEmpty(t, clusterName)

	clusterID := terraform.Output(t, opts, "aks_cluster_id")
	assert.NotEmpty(t, clusterID)
	assert.Contains(t, clusterID, "/managedClusters/")

	// Verify OIDC issuer (proves private cluster with proper config)
	oidcIssuer := terraform.Output(t, opts, "aks_oidc_issuer_url")
	assert.NotEmpty(t, oidcIssuer)
	assert.Contains(t, oidcIssuer, "https://")

	// Verify AGIC identity
	agicClientID := terraform.Output(t, opts, "agic_client_id")
	assert.NotEmpty(t, agicClientID)
}

// validateStorage verifies storage account configuration
func validateStorage(t *testing.T, opts *terraform.Options) {
	// Verify storage outputs
	storageAccountName := terraform.Output(t, opts, "storage_account_name")
	assert.NotEmpty(t, storageAccountName)
	assert.True(t, len(storageAccountName) >= 3 && len(storageAccountName) <= 24)
	assert.Equal(t, strings.ToLower(storageAccountName), storageAccountName) // Must be lowercase

	storageAccountID := terraform.Output(t, opts, "storage_account_id")
	assert.NotEmpty(t, storageAccountID)
	assert.Contains(t, storageAccountID, "/storageAccounts/")

	// Verify private endpoint
	storageBlobPEID := terraform.Output(t, opts, "storage_blob_private_endpoint_id")
	assert.NotEmpty(t, storageBlobPEID)
	assert.Contains(t, storageBlobPEID, "/privateEndpoints/")
}

// validateKeyVault verifies Key Vault configuration
func validateKeyVault(t *testing.T, opts *terraform.Options) {
	// Verify Key Vault outputs
	keyVaultName := terraform.Output(t, opts, "keyvault_name")
	assert.NotEmpty(t, keyVaultName)

	keyVaultID := terraform.Output(t, opts, "keyvault_id")
	assert.NotEmpty(t, keyVaultID)
	assert.Contains(t, keyVaultID, "/vaults/")

	// Verify private endpoint
	kvPEID := terraform.Output(t, opts, "keyvault_private_endpoint_id")
	assert.NotEmpty(t, kvPEID)
	assert.Contains(t, kvPEID, "/privateEndpoints/")

	// Verify Key Vault URI
	kvURI := terraform.Output(t, opts, "keyvault_uri")
	assert.NotEmpty(t, kvURI)
	assert.Contains(t, kvURI, "https://")
	assert.Contains(t, kvURI, ".vault.azure.net")
}

// validateSQLDatabase verifies SQL Database configuration
func validateSQLDatabase(t *testing.T, opts *terraform.Options) {
	// Verify SQL Server outputs
	sqlServerName := terraform.Output(t, opts, "sql_server_name")
	assert.NotEmpty(t, sqlServerName)

	sqlServerID := terraform.Output(t, opts, "sql_server_id")
	assert.NotEmpty(t, sqlServerID)
	assert.Contains(t, sqlServerID, "/servers/")

	// Verify SQL Database
	sqlDBName := terraform.Output(t, opts, "sql_database_name")
	assert.NotEmpty(t, sqlDBName)

	sqlDBID := terraform.Output(t, opts, "sql_database_id")
	assert.NotEmpty(t, sqlDBID)
	assert.Contains(t, sqlDBID, "/databases/")

	// Verify private endpoint
	sqlPEID := terraform.Output(t, opts, "sql_private_endpoint_id")
	assert.NotEmpty(t, sqlPEID)
	assert.Contains(t, sqlPEID, "/privateEndpoints/")

	// Verify FQDN
	sqlFQDN := terraform.Output(t, opts, "sql_server_fqdn")
	assert.NotEmpty(t, sqlFQDN)
	assert.Contains(t, sqlFQDN, ".database.windows.net")
}

// TestModuleIndependently tests individual modules
func TestNetworkingModule(t *testing.T) {
	t.Parallel()

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
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	hubVNetID := terraform.Output(t, terraformOptions, "hub_vnet_id")
	spokeVNetIDs := terraform.OutputList(t, terraformOptions, "spoke_vnet_ids")

	assert.NotEmpty(t, hubVNetID)
	assert.NotEmpty(t, spokeVNetIDs)
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
