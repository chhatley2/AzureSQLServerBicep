//Deploys an Azure SQL Server, Azure Blob Storage (for Defender for Cloud Vulnerabilites Assessments, Private Endpoints, and the first Azure SQL DB. Environmnet paramater dictates which subnet is used for Priavte Endpoint. 


//Paramaters//
@description('Enviroment Azure SQL will be deployed in...')
@allowed([
  'Dev'
  'Live'
  'Stage'
])
param environmentName string = 'Dev'

param location string = resourceGroup().location

@description('Minimum TLS version. Made this a param so we can increase it in the future')
@allowed([
  '1.2'
])
param sqltlsversion string = '1.2'

@description('Minimum TLS version. Made this a param so we can increase it in the future')
@allowed([
  'TLS1_2'
])
param storagetlsversion string = 'TLS1_2'

@description('Azure SQL Server name.')
param azureSQLServerName string = 'azsqlservertest6'

@description('Resource Group to be used for deployment. Will need to run CLI command to create it as step one of the job')
param resourceGroupName string = 'azuresqlserverbicep-rg'

@description('Name of the Azure SQL Vulernability Stroage Account')
param storageName string = 'azstorageaccountsvtest6'

@description('Financial Tag value for deployed resources')
param financialTag string = 'chargeback'

@description('Subscription ID of resources')
param subscriptionId string = '508ee3b5-9a3f-4e79-985e-f4c0c4972af6'




//Varaibles//
@description('Hard coded the Subnets since they dont change in my envrionment')
var environmentSettings = {
  Dev: {
    subnetID: '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourceGroups/gao-rg-sharedServices-dev/providers/Microsoft.Network/virtualNetworks/gao-vnet-sharedServices-dev/subnets/gao-snet-sharedServices-dev'
    suffix: 'dev'
  }
  Stage: {
    subnetID: '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourceGroups/gao-rg-sharedServices-dev/providers/Microsoft.Network/virtualNetworks/gao-vnet-sharedServices-dev/subnets/gao-snet-sharedServices-dev'
    suffix: 'stage'
  }
  Live: {
    subnetID: '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourceGroups/gao-rg-sharedServices-dev/providers/Microsoft.Network/virtualNetworks/gao-vnet-sharedServices-dev/subnets/gao-snet-sharedServices-dev'
    suffix: 'live'
  }
}

var storageSKU = 'Standard_RAGZRS'

var sqlLogin = 'sqladmin'

@description('Required during Azure SQL Server deployment to specify an Azure AD Syncd Group')
var tenantID = '8a09f2d7-8415-4296-92b2-80bb4666c5fc'

@description('Azure AD Object ID of the Group Being Syncronized and Nested into Azure SQL Server Admin')
var sqlOperatorObjectID = '07f482cf-aa13-43b1-a466-0193a574c59a'

@description('Name of the Azrue AD Group being granded Azure SQL Server Admin permissions')
var login = 'sqlserveroperators'

@description('Resource ID of LAW')
var logAnalyticsID = '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourcegroups/azuresqlserverbicep-rg/providers/microsoft.operationalinsights/workspaces/exampletsaloganalytics-ws'

@description('Path to Azure Storage Account called by Azure SQL DB to configure Vulnerability Assessments')
var storageContainerPath = concat('${'https://'}${storageName}${'.blob.core.usgovcloudapi.net/'}${'vulnerability-assessment'}')

@description('Resource ID of Splunk Event Hub')
var eventHubID = '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourceGroups/azuresqlserverbicep-rg/providers/Microsoft.EventHub/namespaces/SplunkEventHub5000/authorizationRules/RootManageSharedAccessKey'
var eventHub = 'SplunkEventHub5000'

@description('Information for Jenkins Service Account to pull secret out of KeyVault')
var kvName = 'sqlkeyvault'
var kvResourceGroup = resourceGroupName

@description('DNS Zones and IDs used to configure Storagte and SQL Private endpoints')
var storagePrivateDNSZoneID = '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourceGroups/gao-rg-hub-dev/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.usgovcloudapi.net'
var sqlserverPrivateDNSZoneID = '/subscriptions/508ee3b5-9a3f-4e79-985e-f4c0c4972af6/resourceGroups/gao-rg-hub-dev/providers/Microsoft.Network/privateDnsZones/privatelink.database.usgovcloudapi.net'
var blobgroupid = 'blob'
var sqlgroupid = 'sqlServer'
var stgPrivateEndpointName = concat('${'PE-'}${storageName}${'-'}${environmentName}')
var sqlPrivateEndpointName = concat('${'PE-'}${azureSQLServerName}${'-'}${environmentName}')
var stgPvtDNSGroupName = concat('${stgPrivateEndpointName}${'/Default'}')
var sqlPvtDNSGroupName = concat('${sqlPrivateEndpointName}${'/Default'}')

//Deployments//


//Required to pass KeyVault Secret into Azure SQL Server Module
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: resourceGroup(subscriptionId, kvResourceGroup )
}

//Deploy Vulnerability Assessment Stroage Account
module stgAccountModule './stgAccount/stgAccount.bicep' =  {
  name: 'stgAccountDeploy'
  params: {
    location: location
    storageName: storageName
    storageSKU: storageSKU
    storageTLSversion: storagetlsversion
    financialTag: financialTag
  }
}


//Deploy Storage Account private Endpoint
module stgPrivateEndpointModule './pvtEndpoint/pvtEndpoint.bicep' =  {
  name: 'stgPrivateEndpointDeploy'
  params: {
    privateEndpointName: stgPrivateEndpointName
    location: location
    subnetID: environmentSettings.Dev.subnetID
    resourceID: stgAccountModule.outputs.storageresourceresourceid
    peResourceType: blobgroupid
    pvtDNSGroupName: stgPvtDNSGroupName
    pvtDNSZoneID: storagePrivateDNSZoneID
  }
  dependsOn: [
    stgAccountModule
  ]
}


//Deploy Azure SQL Server
module sqlServerModule './sqlServer/sqlServer.bicep' =  {
  name: 'sqlServerDeploy'
  params: {
    location: location
    azureSQLServerName: azureSQLServerName
    tenantID: tenantID
    financialTag: financialTag
    login: login
    sqltslversion: sqltlsversion
    sqlLogin: sqlLogin
    sqlOperatorObjectID: sqlOperatorObjectID
    sqlpassword: kv.getSecret('sqlpassword')
    privateEndpointName: sqlPrivateEndpointName
    subnetID: environmentSettings.Dev.subnetID
    peResourceType: sqlgroupid
    pvtDNSGroupName: sqlPvtDNSGroupName
    pvtDNSZoneID: sqlserverPrivateDNSZoneID
    eventHubAuthorizationRuleId: eventHubID
    eventHubName: eventHub
    workspaceId: logAnalyticsID
    storagePath: storageContainerPath
  }
  dependsOn: [
    stgAccountModule
    stgPrivateEndpointModule
  ]
}




//Oubputs
@description('Subnet ID based on Envrionment paramater to be injected into the Priave Endpoint deployment.')
output subnetID string = environmentSettings[environmentName].subnetID

@description('This was just an example. We could do stuff like this and then can it to the name')
output suffix string = environmentSettings[environmentName].suffix

@description('Resource ID of that Azure SQL Server object to be injected into the Private Endpoint deployment')
output stroageResourceID string = stgAccountModule.outputs.storageresourceresourceid



