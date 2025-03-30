param location string = 'westeurope'
param acrName string = 'flaskcrudacrac'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}


output acrLoginServer string = acr.properties.loginServer