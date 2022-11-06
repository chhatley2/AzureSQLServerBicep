param azureSQLServerName string
param location string
param tenantID string
param sqlLogin string
param sqlOperatorObjectID string
param financialTag string
param login string
param sqltslversion string
@secure()
param sqlpassword string
param privateEndpointName string
param subnetID string
param peResourceType string
param pvtDNSGroupName string
param pvtDNSZoneID string
param eventHubAuthorizationRuleId string
param eventHubName string
param workspaceId string


//Deploy Azure SQL Server
resource sqlServerDeployment 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: azureSQLServerName
  location: location
  tags: {
    tagName1: financialTag

  }
  properties: {
    administratorLogin: sqlLogin
    administratorLoginPassword: sqlpassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      login: login
      principalType: 'group'
      sid: sqlOperatorObjectID
      tenantId: tenantID
    }
    minimalTlsVersion: sqltslversion
    primaryUserAssignedIdentityId: 'string'
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Enabled'
  }
}


//Deploy Private Endpoint. Can't be a seperate module.
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: sqlServerDeployment.id
          groupIds: [
            peResourceType
          ]
        }
      }
    ]
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtDNSGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: pvtDNSZoneID
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

resource setting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Send to Eventhub and LaW'
  scope: sqlServerDeployment
  properties: {
    workspaceId: workspaceId
    eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
    eventHubName: eventHubName
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

