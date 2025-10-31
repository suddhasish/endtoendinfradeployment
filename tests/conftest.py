"""
Pytest configuration and shared fixtures for infrastructure tests
"""
import os
import json
import pytest
from python_terraform import Terraform


@pytest.fixture(scope="session")
def terraform_env_dev():
    """Fixture for DEV environment Terraform"""
    tf = Terraform(working_dir='../environments/dev')
    return tf


@pytest.fixture(scope="session")
def terraform_outputs_dev(terraform_env_dev):
    """Get Terraform outputs for DEV environment"""
    # Note: Assumes terraform is already applied
    # In CI/CD, this runs after terraform apply step
    outputs = terraform_env_dev.output()
    return outputs


@pytest.fixture
def azure_credentials():
    """Get Azure credentials from environment variables"""
    return {
        'client_id': os.getenv('AZURE_CLIENT_ID'),
        'client_secret': os.getenv('AZURE_CLIENT_SECRET'),
        'tenant_id': os.getenv('AZURE_TENANT_ID'),
        'subscription_id': os.getenv('AZURE_SUBSCRIPTION_ID')
    }


def pytest_configure(config):
    """Configure pytest with custom markers"""
    config.addinivalue_line(
        "markers", "integration: mark test as integration test"
    )
    config.addinivalue_line(
        "markers", "networking: mark test as networking test"
    )
    config.addinivalue_line(
        "markers", "security: mark test as security test"
    )
