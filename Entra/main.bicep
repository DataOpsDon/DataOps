extension microsoftGraph

@description('Group configuration object')
param groupConfig object = {
  displayName: 'bicep-grp'
  mailEnabled: false
  mailNickname: 'bicep-grp'
  securityEnabled: true
  uniqueName: 'bicep-grp'
}

resource groups 'Microsoft.Graph/groups@v1.0' = {
  displayName: groupConfig.displayName
  mailEnabled: groupConfig.mailEnabled
  mailNickname: groupConfig.mailNickname
  securityEnabled: groupConfig.securityEnabled
  uniqueName: groupConfig.uniqueName
}

