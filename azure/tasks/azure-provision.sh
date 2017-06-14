#!/usr/bin/env bash

set -e

: ${AZURE_CLIENT_ID:?}
: ${AZURE_CLIENT_SECRET:?}
: ${AZURE_TENANT_ID:?}
: ${AZURE_ENVIRONMENT:?}
: ${AZURE_RESOURCE_GROUP_NAME:?}
: ${AZURE_GROUP_NAME_FOR_NETWORK:?}
: ${AZURE_GROUP_NAME_FOR_MANAGED_DISKS:?}
: ${AZURE_GROUP_NAME_FOR_NETWORK_MANAGED_DISKS:?}
: ${AZURE_GROUP_NAME_FOR_CENTOS:?}
: ${AZURE_GROUP_NAME_FOR_NETWORK_CENTOS:?}
: ${AZURE_REGION_NAME:?}
: ${AZURE_REGION_SHORT_NAME:?}
: ${AZURE_STORAGE_ACCOUNT_NAME:?}
: ${AZURE_STORAGE_ACCOUNT_NAME_MANAGED_DISKS:?}
: ${AZURE_VIRTUAL_NETWORK_NAME:?}
: ${AZURE_BOSH_SUBNET_NAME:?}
: ${AZURE_BOSH_SECOND_SUBNET_NAME:?}
: ${AZURE_CF_SUBNET_NAME:?}
: ${AZURE_CF_SECOND_SUBNET_NAME:?}

azure login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} --environment ${AZURE_ENVIRONMENT}
azure config mode arm

set +e

resource_group_names="${AZURE_RESOURCE_GROUP_NAME} ${AZURE_GROUP_NAME_FOR_NETWORK} ${AZURE_GROUP_NAME_FOR_MANAGED_DISKS} ${AZURE_GROUP_NAME_FOR_NETWORK_MANAGED_DISKS} ${AZURE_GROUP_NAME_FOR_CENTOS} ${AZURE_GROUP_NAME_FOR_NETWORK_CENTOS}"
for resource_group_name in ${resource_group_names}
do
  # Check if the resource group already exists
  echo "azure group list | grep ${resource_group_name}"
  azure group list | grep ${resource_group_name}
  
  if [ $? -eq 0 ]
  then
    echo "azure group delete ${resource_group_name}"
    azure group delete ${resource_group_name} --quiet
    echo "waiting for delete operation to finish..."
    # Wait for the completion of deleting the resource group
    azure group show ${resource_group_name}
    while [ $? -eq 0 ]
    do
      azure group show ${resource_group_name} > /dev/null 2>&1
      echo "..."
    done
  fi
done

set -e

resource_group_names="${AZURE_RESOURCE_GROUP_NAME} ${AZURE_GROUP_NAME_FOR_NETWORK} ${AZURE_GROUP_NAME_FOR_MANAGED_DISKS} ${AZURE_GROUP_NAME_FOR_NETWORK_MANAGED_DISKS} ${AZURE_GROUP_NAME_FOR_CENTOS} ${AZURE_GROUP_NAME_FOR_NETWORK_CENTOS}"
for resource_group_name in ${resource_group_names}
do
  echo azure group create ${resource_group_name} ${AZURE_REGION_SHORT_NAME}
  azure group create ${resource_group_name} ${AZURE_REGION_SHORT_NAME}
  cat > network-parameters.json << EOF
  {
    "virtualNetworkName": {
      "value": "${AZURE_VIRTUAL_NETWORK_NAME}"
    },
    "subnetNameForBosh": {
      "value": "${AZURE_BOSH_SUBNET_NAME}"
    },
    "secondSubnetNameForBosh": {
      "value": "${AZURE_BOSH_SECOND_SUBNET_NAME}"
    }
  }
EOF
  azure group deployment create ${resource_group_name} --template-file ./pipelines/azure/assets/network.json --parameters-file ./network-parameters.json
done

# Setup the storage account
resource_group_name="${AZURE_RESOURCE_GROUP_NAME}"
storage_account_name="${AZURE_STORAGE_ACCOUNT_NAME}"
azure storage account create --location ${AZURE_REGION_SHORT_NAME} --sku-name LRS --kind Storage --resource-group ${resource_group_name} ${storage_account_name}
storage_account_key=$(azure storage account keys list ${storage_account_name} --resource-group ${resource_group_name} --json | jq '.[0].value' -r)
azure storage container create --account-name ${storage_account_name} --account-key ${storage_account_key} --container bosh
azure storage container create --account-name ${storage_account_name} --account-key ${storage_account_key} --permission blob --container stemcell

resource_group_name="${AZURE_GROUP_NAME_FOR_MANAGED_DISKS}"
storage_account_name="${AZURE_STORAGE_ACCOUNT_NAME_MANAGED_DISKS}"
azure storage account create --location ${AZURE_REGION_SHORT_NAME} --sku-name LRS --kind Storage --resource-group ${resource_group_name} ${storage_account_name}
storage_account_key=$(azure storage account keys list ${storage_account_name} --resource-group ${resource_group_name} --json | jq '.[0].value' -r)
azure storage container create --account-name ${storage_account_name} --account-key ${storage_account_key} --permission blob --container stemcell
