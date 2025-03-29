param location string = 'westeurope'
param acrName string = 'flaskcrudacrac'
param resourceGroup string = 'flask-crud-rg-ac'

// Create Azure Container Registry (ACR) with best practices
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

// Create an ACR Token with least privilege (pull-only access)
resource acrToken 'Microsoft.ContainerRegistry/registries/tokens@2023-01-01' = {
  parent: acr
  name: 'flask-crud-acr-token-ac'
  properties: {
    scopeMapId: acr.id + '/scopeMaps/_repositories_pull'
    status: 'Enabled'
  }
}

// Retrieve the token credentials
resource acrTokenCredential 'Microsoft.ContainerRegistry/registries/tokens/credentials@2023-01-01' = {
  parent: acrToken
  name: 'password'
  properties: {
    password1: {
      create: true
    }
    password2: {
      create: true
    }
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrId string = acr.id
output acrTokenName string = acrToken.name