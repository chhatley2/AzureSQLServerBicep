param privateEndpointName string
param subnetID string
param resourceID string
param peResourceType string
param pvtDNSGroupName string
param pvtDNSZoneID string
param location string


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
          privateLinkServiceId: resourceID
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


