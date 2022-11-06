
param location string
param financialTag string
param storageName string
param storageSKU string
param storageTLSversion string

resource storageDeployment 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  tags: {
    tag: financialTag
  }
  sku: {
    name: storageSKU
      }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: storageTLSversion
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource storageAccountBlobVulnerability 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  name: 'default'
  parent: storageDeployment
}

resource storageAccountContainerVulnerability 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: 'vulnerabilityscans'
  parent: storageAccountBlobVulnerability
}

@description('The resource ID of the Azure SQL Server for the Private Endpoint.')
output storageresourceresourceid string = storageDeployment.id
