@maxLength(9)
param namePrefix string = 'dpgetprod'

param location string = 'westeurope'

var functionName = '${namePrefix}-func'
var appServicePlanName = '${namePrefix}-asp'
var storageAccountName = '${namePrefix}${uniqueString(resourceGroup().id)}'
var appInsightsName = '${namePrefix}-ai'
var logAnalyticsWorkspaceName = '${namePrefix}-log'
var appTags = {
  AppID: 'myfunc'
  AppName: 'My Function App'
  HackTeam: 'Team04'
}

// Function App
resource getProductFunc 'Microsoft.Web/sites@2020-12-01' = {
  name: functionName
  location: location
  tags: appTags
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('name')
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
      ]
      linuxFxVersion: 'Python|3.8'
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: appTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// App Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: location
  tags: appTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  tags: appTags
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  tags: appTags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

// Blob Services for Storage Account
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  parent: storageAccount

  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

