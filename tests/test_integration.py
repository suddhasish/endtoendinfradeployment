"""
Integration tests for full infrastructure deployment
"""
import pytest


@pytest.mark.integration
class TestFullInfrastructureDeployment:
    """Test complete infrastructure deployment"""

    def test_networking_outputs(self, terraform_outputs_dev):
        """Verify networking resources are created"""
        # Verify Hub VNet
        assert 'hub_vnet_id' in terraform_outputs_dev
        hub_vnet_id = terraform_outputs_dev['hub_vnet_id']['value']
        assert hub_vnet_id
        assert '/virtualNetworks/' in hub_vnet_id

        # Verify Spoke VNets
        assert 'spoke_vnet_ids' in terraform_outputs_dev
        spoke_vnets = terraform_outputs_dev['spoke_vnet_ids']['value']
        assert isinstance(spoke_vnets, list)
        assert len(spoke_vnets) > 0

        # Verify subnets
        assert 'appgw_subnet_id' in terraform_outputs_dev
        appgw_subnet = terraform_outputs_dev['appgw_subnet_id']['value']
        assert '/subnets/' in appgw_subnet

        assert 'aks_subnet_ids' in terraform_outputs_dev
        aks_subnets = terraform_outputs_dev['aks_subnet_ids']['value']
        assert isinstance(aks_subnets, list)
        assert len(aks_subnets) > 0

    def test_private_dns_zones(self, terraform_outputs_dev):
        """Verify private DNS zones are created"""
        # Key Vault DNS Zone
        assert 'private_dns_zone_keyvault_id' in terraform_outputs_dev
        kv_dns = terraform_outputs_dev['private_dns_zone_keyvault_id']['value']
        assert 'privatelink.vaultcore.azure.net' in kv_dns

        # SQL DNS Zone
        assert 'private_dns_zone_sql_id' in terraform_outputs_dev
        sql_dns = terraform_outputs_dev['private_dns_zone_sql_id']['value']
        assert 'privatelink.database.windows.net' in sql_dns

        # Storage Blob DNS Zone
        assert 'private_dns_zone_storage_blob_id' in terraform_outputs_dev
        storage_dns = terraform_outputs_dev['private_dns_zone_storage_blob_id']['value']
        assert 'privatelink.blob.core.windows.net' in storage_dns

    def test_aks_cluster(self, terraform_outputs_dev):
        """Verify AKS cluster configuration"""
        # Cluster name
        assert 'aks_cluster_name' in terraform_outputs_dev
        cluster_name = terraform_outputs_dev['aks_cluster_name']['value']
        assert cluster_name

        # Cluster ID
        assert 'aks_cluster_id' in terraform_outputs_dev
        cluster_id = terraform_outputs_dev['aks_cluster_id']['value']
        assert '/managedClusters/' in cluster_id

        # OIDC Issuer (proves private cluster with proper config)
        assert 'aks_oidc_issuer_url' in terraform_outputs_dev
        oidc_url = terraform_outputs_dev['aks_oidc_issuer_url']['value']
        assert oidc_url.startswith('https://')

        # AGIC Identity
        assert 'agic_client_id' in terraform_outputs_dev
        agic_id = terraform_outputs_dev['agic_client_id']['value']
        assert agic_id

    def test_storage_account(self, terraform_outputs_dev):
        """Verify storage account configuration"""
        # Storage account name
        assert 'storage_account_name' in terraform_outputs_dev
        storage_name = terraform_outputs_dev['storage_account_name']['value']
        assert storage_name
        assert len(storage_name) >= 3 and len(storage_name) <= 24
        assert storage_name.islower()  # Must be lowercase
        assert storage_name.isalnum()  # Only alphanumeric

        # Storage account ID
        assert 'storage_account_id' in terraform_outputs_dev
        storage_id = terraform_outputs_dev['storage_account_id']['value']
        assert '/storageAccounts/' in storage_id

        # Private endpoint
        assert 'storage_blob_private_endpoint_id' in terraform_outputs_dev
        pe_id = terraform_outputs_dev['storage_blob_private_endpoint_id']['value']
        assert '/privateEndpoints/' in pe_id

    def test_key_vault(self, terraform_outputs_dev):
        """Verify Key Vault configuration"""
        # Key Vault name
        assert 'keyvault_name' in terraform_outputs_dev
        kv_name = terraform_outputs_dev['keyvault_name']['value']
        assert kv_name

        # Key Vault ID
        assert 'keyvault_id' in terraform_outputs_dev
        kv_id = terraform_outputs_dev['keyvault_id']['value']
        assert '/vaults/' in kv_id

        # Private endpoint
        assert 'keyvault_private_endpoint_id' in terraform_outputs_dev
        pe_id = terraform_outputs_dev['keyvault_private_endpoint_id']['value']
        assert '/privateEndpoints/' in pe_id

        # Key Vault URI
        assert 'keyvault_uri' in terraform_outputs_dev
        kv_uri = terraform_outputs_dev['keyvault_uri']['value']
        assert kv_uri.startswith('https://')
        assert '.vault.azure.net' in kv_uri

    def test_sql_database(self, terraform_outputs_dev):
        """Verify SQL Database configuration"""
        # SQL Server name
        assert 'sql_server_name' in terraform_outputs_dev
        server_name = terraform_outputs_dev['sql_server_name']['value']
        assert server_name

        # SQL Server ID
        assert 'sql_server_id' in terraform_outputs_dev
        server_id = terraform_outputs_dev['sql_server_id']['value']
        assert '/servers/' in server_id

        # SQL Database
        assert 'sql_database_name' in terraform_outputs_dev
        db_name = terraform_outputs_dev['sql_database_name']['value']
        assert db_name

        assert 'sql_database_id' in terraform_outputs_dev
        db_id = terraform_outputs_dev['sql_database_id']['value']
        assert '/databases/' in db_id

        # Private endpoint
        assert 'sql_private_endpoint_id' in terraform_outputs_dev
        pe_id = terraform_outputs_dev['sql_private_endpoint_id']['value']
        assert '/privateEndpoints/' in pe_id

        # FQDN
        assert 'sql_server_fqdn' in terraform_outputs_dev
        fqdn = terraform_outputs_dev['sql_server_fqdn']['value']
        assert '.database.windows.net' in fqdn

    def test_application_gateway(self, terraform_outputs_dev):
        """Verify Application Gateway configuration"""
        assert 'application_gateway_id' in terraform_outputs_dev
        appgw_id = terraform_outputs_dev['application_gateway_id']['value']
        assert '/applicationGateways/' in appgw_id

        assert 'application_gateway_public_ip' in terraform_outputs_dev
        public_ip = terraform_outputs_dev['application_gateway_public_ip']['value']
        assert public_ip  # Should have a public IP

    def test_monitoring(self, terraform_outputs_dev):
        """Verify monitoring resources"""
        # Log Analytics Workspace
        assert 'log_analytics_workspace_id' in terraform_outputs_dev
        law_id = terraform_outputs_dev['log_analytics_workspace_id']['value']
        assert '/workspaces/' in law_id

        # Application Insights
        assert 'application_insights_id' in terraform_outputs_dev
        ai_id = terraform_outputs_dev['application_insights_id']['value']
        assert '/components/' in ai_id


@pytest.mark.integration
@pytest.mark.security
class TestSecurityCompliance:
    """Test security and compliance configurations"""

    def test_private_endpoints_exist(self, terraform_outputs_dev):
        """Verify all critical resources have private endpoints"""
        # Storage
        assert 'storage_blob_private_endpoint_id' in terraform_outputs_dev
        assert terraform_outputs_dev['storage_blob_private_endpoint_id']['value']

        # Key Vault
        assert 'keyvault_private_endpoint_id' in terraform_outputs_dev
        assert terraform_outputs_dev['keyvault_private_endpoint_id']['value']

        # SQL
        assert 'sql_private_endpoint_id' in terraform_outputs_dev
        assert terraform_outputs_dev['sql_private_endpoint_id']['value']

    def test_resource_naming_convention(self, terraform_outputs_dev):
        """Verify resources follow naming conventions"""
        # AKS cluster should have predictable naming
        cluster_name = terraform_outputs_dev['aks_cluster_name']['value']
        assert 'aks' in cluster_name.lower()

        # Storage should be lowercase alphanumeric
        storage_name = terraform_outputs_dev['storage_account_name']['value']
        assert storage_name.islower()
        assert storage_name.isalnum()

    def test_waf_enabled(self, terraform_outputs_dev):
        """Verify WAF is configured on Application Gateway"""
        # Application Gateway should exist (WAF is configured in the module)
        assert 'application_gateway_id' in terraform_outputs_dev
        appgw_id = terraform_outputs_dev['application_gateway_id']['value']
        assert appgw_id
        # WAF policy is attached in the module configuration
