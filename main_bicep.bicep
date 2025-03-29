param location string = 'westeurope'
param acrName string = 'flaskcrudacrac'
param vnetName string = 'flask-crud-vnet-ac'
param aciSubnetName string = 'aci-subnet'
param agwSubnetName string = 'appgw-subnet'
param logAnalyticsWorkspaceName string = 'flask-crud-logs-ac'
param aciName string = 'flaskcrudaciac'
param agwName string = 'flask-crud-agw'
param agwPublicIpName string = 'flask-crud-agw-ip'
param agwFrontendPort int = 80
param agwBackendPort int = 80

// Reference existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

// Create Virtual Network with two subnets
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: aciSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'aci-delegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: agwSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// Create Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Network Profile for ACI
resource networkProfile 'Microsoft.Network/networkProfiles@2021-05-01' = {
  name: 'aci-network-profile'
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'aci-network-interface'
        properties: {
          ipConfigurations: [
            {
              name: 'aci-ipconfig'
              properties: {
                subnet: {
                  id: '${vnet.id}/subnets/${aciSubnetName}'
                }
              }
            }
          ]
        }
      }
    ]
  }
}

// Deploy ACI with private IP in VNet
resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  properties: {
    osType: 'Linux'
    imageRegistryCredentials: [
      {
        server: '${acrName}.azurecr.io'
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
    networkProfile: {
      id: networkProfile.id
    }
    containers: [
      {
        name: 'flask-crud-container-ac'
        properties: {
          image: '${acrName}.azurecr.io/flask-crud-app:latest'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          ports: [
            {
              port: agwBackendPort
            }
          ]
        }
      }
    ]
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalytics.properties.customerId
        workspaceKey: listKeys(logAnalytics.id, logAnalytics.apiVersion).primarySharedKey
      }
    }
  }
}

// Public IP for Application Gateway
resource agwPublicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: agwPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Application Gateway
resource agw 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: agwName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${agwSubnetName}'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: agwPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: agwFrontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'aciBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: reference(aci.id, '2023-05-01').properties.ipAddress.ip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'aciBackendSettings'
        properties: {
          port: agwBackendPort
          protocol: 'Http'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'aciListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agwName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agwName, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'aciRoutingRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agwName, 'aciListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agwName, 'aciBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agwName, 'aciBackendSettings')
          }
        }
      }
    ]
  }
  dependsOn: [
    aci
  ]
}

output applicationGatewayPublicIp string = agwPublicIp.properties.ipAddress
output aciPrivateIp string = reference(aci.id, '2023-05-01').properties.ipAddress.ip
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId