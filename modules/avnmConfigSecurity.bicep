@description('Name of the AVNM security admin configuration.')
param securityAdminConfigName string

@description('ResourceID  of the Network group to be associated with the security admin configuration.')
param networkGroupId array

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Apply on network intent policy based services setting for the AVNM security admin configuration.')
@allowed([
  'None'
  'AllowRulesOnly'
])
param applyOnNetworkIntentPolicyBasedServices string = 'None'

@description('Network group address space aggregation option for the AVNM security admin configuration.')
@allowed([
  'None'
  'Manual'
])
param networkGroupAddressSpaceAggregationOption string = 'None'

// variable with unencrypted traffic to be denied. array of object with Protocols, ports, name and description including explanation. Extract from https://learn.microsoft.com/en-us/azure/virtual-network-manager/concept-security-admins#protect-high-risk-ports
var unencryptedTraffic = [
  {
    name: 'Deny-Telnet'
    description: 'Deny Telnet traffic (TCP port 23) which is unencrypted and insecure.'
    protocols: 'Tcp'
    ports: '23'
  }
  {
    name: 'Deny-FTP'
    description: 'Deny FTP traffic (TCP ports 20 and 21) which is unencrypted and insecure.'
    protocols: 'Tcp'
    ports: '20-21'
  }
  {
    name: 'Deny-SMTP'
    description: 'Deny SMTP traffic (TCP port 25) which is often exploited for spam and phishing attacks.'
    protocols: 'Tcp'
    ports: '25'
  }
  {
    name: 'Deny-POP3'
    description: 'Deny POP3 traffic (TCP port 110) which is unencrypted and can expose sensitive information.'
    protocols: 'Tcp'
    ports: '110'
  }
  {
    name: 'Deny-IMAP'
    description: 'Deny IMAP traffic (TCP port 143) which is unencrypted and can be vulnerable to interception.'
    protocols: 'Tcp'
    ports: '143'
  }
  {
    name: 'Deny-ESP'
    description: 'Deny ESP traffic (IP protocol number 50) which can be exploited for certain types of attacks.'
    protocols: 'Esp'
    ports: '0-65535'
  }
  {
    name: 'Deny-AH'
    description: 'Deny AH traffic (IP protocol number 51) which can be vulnerable to specific security threats.'
    protocols: 'Ah'
    ports: '0-65535'
  }
]

// Get existing AVNM resource
resource avnm 'Microsoft.Network/networkManagers@2025-01-01' existing = {
  name: avnmName
}

// Deploy AVNM Security Admin Configuration
resource avnmSecurityAdminConfig 'Microsoft.Network/networkManagers/securityAdminConfigurations@2025-01-01' = {
  name: securityAdminConfigName
  parent: avnm
  properties: {
    description: 'Security admin configuration for AVNM Network Group'
    applyOnNetworkIntentPolicyBasedServices: [
      applyOnNetworkIntentPolicyBasedServices
    ]
    networkGroupAddressSpaceAggregationOption: networkGroupAddressSpaceAggregationOption
  }
}

// Deploy AVNM Security Admin Rule Collection to deny unencrypted traffic
resource avnmSecurityAdminRuleCollections 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2025-01-01' = {
  name: 'DenyUnencryptedTraffic'
  parent: avnmSecurityAdminConfig
  properties: {
    description: 'Deny unencrypted traffic rule collection'
    appliesToGroups: networkGroupId
  }
}

// Deploy AVNM Security Admin Rules to deny unencrypted traffic
resource avnmSecurityAdminRules 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-10-01' = [
  for (rule, i) in unencryptedTraffic: {
    name: rule.name
    parent: avnmSecurityAdminRuleCollections
    kind: 'Custom'
    properties: {
      access: 'Deny'
      description: rule.description
      protocol: rule.protocols
      direction: 'Outbound'
      priority: i + 500
      destinationPortRanges: [
        rule.ports
      ]
      sourcePortRanges: [
        '0-65535'
      ]
    }
  }
]
