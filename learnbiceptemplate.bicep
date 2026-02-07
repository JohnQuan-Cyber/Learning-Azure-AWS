param vmName string = 'ubuntuVM'
param adminUsername string = 'azureuser'

@secure()
param adminPassword string

resource vnet_lab 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'vnet-lab'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource nsg_ubuntu_ssh 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'nsg-ubuntu-ssh'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vmName_pip 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: '${vmName}-pip'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vmName_nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-nic'
  location: resourceGroup().location
  properties: {
    networkSecurityGroup: {
      id: nsg_ubuntu_ssh.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-lab', 'default')
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmName_pip.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet_lab
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmName_nic.id
        }
      ]
    }
  }
}
 