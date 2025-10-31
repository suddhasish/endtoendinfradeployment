"""
Unit tests for Terraform modules - run before apply
These tests validate Terraform syntax and configuration without deploying resources
"""
import pytest
from python_terraform import Terraform
import os
import json


@pytest.mark.unit
class TestTerraformSyntax:
    """Test Terraform configuration syntax and validation"""

    @pytest.mark.parametrize("environment", ["dev", "qa", "stg", "prod"])
    def test_environment_terraform_init(self, environment):
        """Verify terraform init succeeds for all environments"""
        tf = Terraform(working_dir=f'../environments/{environment}')
        return_code, stdout, stderr = tf.init(backend=False)
        assert return_code == 0, f"Terraform init failed for {environment}: {stderr}"

    @pytest.mark.parametrize("environment", ["dev", "qa", "stg", "prod"])
    def test_environment_terraform_validate(self, environment):
        """Verify terraform validate succeeds for all environments"""
        tf = Terraform(working_dir=f'../environments/{environment}')
        tf.init(backend=False)
        return_code, stdout, stderr = tf.validate()
        assert return_code == 0, f"Terraform validation failed for {environment}: {stderr}"

    @pytest.mark.parametrize("module", [
        "aks",
        "application-gateway",
        "frontdoor",
        "keyvault",
        "monitoring",
        "networking",
        "private-endpoint",
        "sql-database",
        "storage"
    ])
    def test_module_terraform_validate(self, module):
        """Verify terraform validate succeeds for all modules"""
        tf = Terraform(working_dir=f'../modules/{module}')
        tf.init(backend=False)
        return_code, stdout, stderr = tf.validate()
        assert return_code == 0, f"Module {module} validation failed: {stderr}"


@pytest.mark.unit
class TestTerraformConfiguration:
    """Test Terraform configuration files exist and are properly structured"""

    @pytest.mark.parametrize("environment", ["dev", "qa", "stg", "prod"])
    def test_environment_has_required_files(self, environment):
        """Verify all required Terraform files exist"""
        env_dir = f'../environments/{environment}'
        required_files = [
            'main.tf',
            'variables.tf',
            'outputs.tf',
            'versions.tf',
            'backend.tf',
            'terraform.tfvars'
        ]
        
        for file in required_files:
            file_path = os.path.join(env_dir, file)
            assert os.path.exists(file_path), f"Missing {file} in {environment}"

    @pytest.mark.parametrize("module", [
        "aks",
        "application-gateway",
        "frontdoor",
        "keyvault",
        "monitoring",
        "networking",
        "private-endpoint",
        "sql-database",
        "storage"
    ])
    def test_module_has_required_files(self, module):
        """Verify all modules have required files"""
        module_dir = f'../modules/{module}'
        required_files = [
            'main.tf',
            'variables.tf',
            'outputs.tf',
            'versions.tf'
        ]
        
        for file in required_files:
            file_path = os.path.join(module_dir, file)
            assert os.path.exists(file_path), f"Missing {file} in module {module}"

    def test_root_has_versions_tf(self):
        """Verify root directory has versions.tf"""
        assert os.path.exists('../versions.tf'), "Missing versions.tf in root"


@pytest.mark.unit
class TestTerraformVariables:
    """Test Terraform variables are properly defined"""

    @pytest.mark.parametrize("environment", ["dev", "qa", "stg", "prod"])
    def test_environment_tfvars_exists(self, environment):
        """Verify terraform.tfvars exists and is not empty"""
        tfvars_path = f'../environments/{environment}/terraform.tfvars'
        assert os.path.exists(tfvars_path), f"Missing terraform.tfvars for {environment}"
        
        # Check file is not empty
        with open(tfvars_path, 'r') as f:
            content = f.read().strip()
            assert len(content) > 0, f"terraform.tfvars is empty for {environment}"

    @pytest.mark.parametrize("environment", ["dev", "qa", "stg", "prod"])
    def test_environment_has_backend_config(self, environment):
        """Verify backend.tf is properly configured"""
        backend_path = f'../environments/{environment}/backend.tf'
        assert os.path.exists(backend_path), f"Missing backend.tf for {environment}"
        
        with open(backend_path, 'r') as f:
            content = f.read()
            # Check for azurerm backend
            assert 'backend "azurerm"' in content, f"backend.tf missing azurerm config for {environment}"
            # Check for resource group reference
            assert 'resource_group_name' in content, f"backend.tf missing resource_group_name for {environment}"


@pytest.mark.unit
class TestModuleStructure:
    """Test module internal structure and best practices"""

    @pytest.mark.parametrize("module", [
        "aks",
        "application-gateway",
        "keyvault",
        "networking",
        "sql-database",
        "storage"
    ])
    def test_module_has_outputs(self, module):
        """Verify modules define outputs"""
        outputs_path = f'../modules/{module}/outputs.tf'
        
        with open(outputs_path, 'r') as f:
            content = f.read()
            assert 'output' in content, f"Module {module} has no outputs defined"
            assert len(content.strip()) > 0, f"Module {module} outputs.tf is empty"

    @pytest.mark.parametrize("module", [
        "aks",
        "application-gateway",
        "keyvault",
        "networking",
        "sql-database",
        "storage"
    ])
    def test_module_has_variables(self, module):
        """Verify modules define variables"""
        variables_path = f'../modules/{module}/variables.tf'
        
        with open(variables_path, 'r') as f:
            content = f.read()
            assert 'variable' in content, f"Module {module} has no variables defined"

    @pytest.mark.parametrize("module", [
        "aks",
        "application-gateway",
        "keyvault",
        "networking",
        "sql-database",
        "storage"
    ])
    def test_module_has_readme(self, module):
        """Verify modules have README documentation"""
        readme_path = f'../modules/{module}/README.md'
        assert os.path.exists(readme_path), f"Module {module} missing README.md"


@pytest.mark.unit
class TestTerraformVersions:
    """Test Terraform and provider version constraints"""

    @pytest.mark.parametrize("environment", ["dev", "qa", "stg", "prod"])
    def test_environment_has_version_constraints(self, environment):
        """Verify environments have Terraform version constraints"""
        versions_path = f'../environments/{environment}/versions.tf'
        
        with open(versions_path, 'r') as f:
            content = f.read()
            assert 'required_version' in content, f"Missing required_version in {environment}"
            assert 'required_providers' in content, f"Missing required_providers in {environment}"
            assert 'azurerm' in content, f"Missing azurerm provider in {environment}"

    @pytest.mark.parametrize("module", [
        "aks",
        "application-gateway",
        "keyvault",
        "networking",
        "sql-database",
        "storage"
    ])
    def test_module_has_version_constraints(self, module):
        """Verify modules have version constraints"""
        versions_path = f'../modules/{module}/versions.tf'
        
        with open(versions_path, 'r') as f:
            content = f.read()
            assert 'required_version' in content, f"Missing required_version in module {module}"
