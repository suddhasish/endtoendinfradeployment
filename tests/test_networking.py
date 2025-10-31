"""
Networking module specific tests
"""
import pytest
from python_terraform import Terraform


@pytest.mark.networking
class TestNetworkingModule:
    """Test networking module independently"""

    @pytest.fixture(scope="class")
    def terraform_networking(self):
        """Terraform instance for networking module"""
        return Terraform(working_dir='../modules/networking')

    def test_module_outputs_exist(self, terraform_networking):
        """Verify networking module has required outputs"""
        # This test validates the module structure
        # Actual deployment test would require apply
        
        # For now, we validate terraform files are valid
        return_code, stdout, stderr = terraform_networking.init()
        assert return_code == 0, f"Terraform init failed: {stderr}"

        return_code, stdout, stderr = terraform_networking.validate()
        assert return_code == 0, f"Terraform validate failed: {stderr}"

    def test_hub_spoke_topology(self, terraform_outputs_dev):
        """Verify hub-spoke network topology is created"""
        # Hub VNet
        assert 'hub_vnet_id' in terraform_outputs_dev
        hub_vnet = terraform_outputs_dev['hub_vnet_id']['value']
        assert hub_vnet

        # Spoke VNets
        assert 'spoke_vnet_ids' in terraform_outputs_dev
        spoke_vnets = terraform_outputs_dev['spoke_vnet_ids']['value']
        assert len(spoke_vnets) > 0

        # Each spoke should be a valid resource ID
        for spoke in spoke_vnets:
            assert '/virtualNetworks/' in spoke

    def test_required_subnets(self, terraform_outputs_dev):
        """Verify all required subnets are created"""
        # Application Gateway subnet
        assert 'appgw_subnet_id' in terraform_outputs_dev
        assert terraform_outputs_dev['appgw_subnet_id']['value']

        # Private Endpoint subnet
        assert 'pe_subnet_id' in terraform_outputs_dev
        assert terraform_outputs_dev['pe_subnet_id']['value']

        # AKS subnets
        assert 'aks_subnet_ids' in terraform_outputs_dev
        aks_subnets = terraform_outputs_dev['aks_subnet_ids']['value']
        assert len(aks_subnets) > 0

        # Database subnets
        assert 'db_subnet_ids' in terraform_outputs_dev
        db_subnets = terraform_outputs_dev['db_subnet_ids']['value']
        assert len(db_subnets) > 0
