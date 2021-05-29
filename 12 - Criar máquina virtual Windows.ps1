## Script para criar Máquina Virtual Windows ##

# Conectar no Azure
Connect-AzAccount

# Definindo as variáveis 
$ResourceGroup  = "RG-dev-jadsonalves"                  #Variavel com o nome do grupo de recursos
$Location       = "EastUS"                              #Variavel com a localização dos recursos
$vNetName       = "vnet-dev-EastUS-contoso"             #Variavel com o nome da virtual network
$AddressSpace   = "10.0.0.0/16"                         #Variavel com o endereço IP da Virtual network
$SubnetIPRange  = "10.0.0.0/24"                         #Variavel com o endereço IP da subnet
$SubnetName     = "subnet-dev-EastUS-contoso"           #Variavel com o nome da subnet
$nsgName        = "nsg-dev-EastUS-contoso"              #Variavel com o nome do network security group
$adminUsername  = 'jadson.alves'                        #Variavel com o nome do administardor da máquina
$adminPassword  = 'Pa$$w0rd.qwe1234'                    #Variavel com a senha do usuário adiministrador da máquina
$vmName 	    = "dev-VM001"                           #Variavel com o nome da máquina virtual

# Criar o Resource Group
New-AzResourceGroup -Name $ResourceGroup -Location $Location

# Criar a Virtual Network
$vNetwork = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName -AddressPrefix $AddressSpace -Location $location

# Criar a Subnet
Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNetwork -AddressPrefix $SubnetIPRange

# Setando as configurações da virtual network
Set-AzVirtualNetwork -VirtualNetwork $vNetwork

# Criar o Network Security Group
$nsgRuleVMAccess = New-AzNetworkSecurityRuleConfig -Name 'allow-vm-access' -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389,443,80 -Access Allow
New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $location -Name $nsgName -SecurityRules $nsgRuleVMAccess

# Definindo as variáveis da máquina virtual
$vNet       = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
$Subnet     = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNet
$nsg        = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $NsgName
$pubName	= "MicrosoftWindowsServer"
$offerName	= "WindowsServer"
$skuName	= "2016-Datacenter"
$vmSize 	= "Standard_DS2_v2"
$pipName    = "$vmName-pip" 
$nicName    = "$vmName-nic"
$osDiskName = "$vmName-OsDisk"
$osDiskType = "Standard_LRS"

# Definindo as credenciais de administrador
$pw = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$adminCreds  = New-Object System.Management.Automation.PSCredential ("$adminUsername", $pw)

# Criando IP público e interface de rede 
$pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $ResourceGroup -Location $location -AllocationMethod Static 
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroup -Location $location -SubnetId $Subnet.Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Adicionando as configurações da máquina virtual
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Setando os parâmetros do sistema operacional 
Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $adminCreds

# Setando a imagem utilizada na máquina virtual
Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version 'latest'

# Setando as configurações de disco
Set-AzVMOSDisk -VM $vmConfig -Name $osDiskName -StorageAccountType $osDiskType -CreateOption fromImage

# Desabilitando o diagnóstico de boot
Set-AzVMBootDiagnostic -VM $vmConfig -Disable

# Criando a máquina virtual
New-AzVM -ResourceGroupName $ResourceGroup -Location $location -VM $vmConfig

