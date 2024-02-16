function 480Banner() {
    $banner = @"

    Joey Taubert's
     _  _   ___   ___    _    _ _   _ _     
    | || | / _ \ / _ \  | |  | | | (_) |    
    | || || (_) | | | | | |  | | |_ _| |___ 
    |__   _> _ <| | | | | |  | | __| | / __|
       | || (_) | |_| | | |__| | |_| | \__ \
       |_| \___/ \___/   \____/ \__|_|_|___/   

"@
    Write-Host $banner
}
### Usage: 480Connect -server (IP of ESXI)
function 480Connect([string] $server) {
    # If this PowerCLI global variable is populated, we are already connected to a server
    $conn = $global:DefaultVIServer

    if ($conn){
        Write-Host "Already connected to $conn"
    } else {
        # Connect if not already connected
        $conn = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path) {
    $conf = $null

    # Check if file exists
    if (Test-Path $config_path) {
        # Get the config file and convert it so it is usable
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        Write-Host "Using config file at $config_path"
    } else {
        Write-Host "Config file not found: $config_path"
    }
    return $conf
}

function Select-480BaseVM([string] $folder) {
    $selectedvm = $null
    try {
        $vms = Get-VM -Location $folder
        $index = 1

        Write-Host "`n"
        Write-Host "-=-=-= AVAILABLE BASE VMs =-=-=-"
        foreach($vm in $vms) {
            Write-Host [$index] $vm.name
            $index += 1
        }
        $pickindex = Read-Host "Index number of desired VM"
        $selectedvm = $vms[$pickindex - 1]

        # Input validation
        if ($vms -contains $selectedvm) {

        } else {
            Write-Host "Invalid index. Goodbye..."
            exit
        }

        $selectedvmname = $selectedvm.name
        Write-Host "You picked $selectedvmname"
        return $selectedvm
    } catch {
        Write-Host "Invalid folder option: $folder"
        exit
    }
}

function Select-480aseVMFolder() {
    # Get all available VM folders and then list them
    $availableFolders = Get-Folder -Type VM | Where-Object { $_.Name -ne 'vm' } | Select-Object -ExpandProperty Name

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE FOLDERS =-=-=-"
    $1 = 1
    foreach($availableFolder in $availableFolders) {
        Write-Host "$1. $availableFolder"
        $1+=1
    }
    $1-=1

    $folderIndex = Read-Host "Number of the VM folder you wish to use [1-$1]"

    $folderIndex-=1

    # Input validation
    if ($availableFolders -contains $availableFolders[$folderIndex]) {

        $folderName = $availableFolders[$folderIndex]
        Write-Host "You picked $folderName"
        $folder = $availableFolders[$folderIndex]

    } else {
        Write-Host "Invalid index. Goodbye..."
        exit
    }

    return $folder
}

function Select-480Snapshot([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $vm) {
    $snapshots = Get-Snapshot -VM $vm
    
    Write-Host "`n"
    Write-Host "-=-=-= SNAPSHOT LIST FOR $vm =-=-=-"
    $1 = 1
    foreach($snapshot in $snapshots) {
        Write-Host "$1. $snapshot"
        $1+=1
    }

    $snapshotIndex = Read-Host "Number of the snapshot to use"


    $snapshotChoice = $snapshots[$snapshotIndex - 1]

    if ($snapshots -contains $snapshotChoice) {
        Write-Host "You picked $snapshotChoice"
    } else {
        Write-Host "Invalid index. Goodbye..."
    }

    return $snapshotChoice
}

function Select-480Datastore() {
    $dsList = Get-Datastore | Select-Object -ExpandProperty "Name"

    Write-Host "`n"
    Write-Host "-=-=-= DATASTORE LIST =-=-=-"
    $2 = 1
    foreach ($dsName in $dsList) {
        Write-Host "$2. $dsName"
        $2 = $2 + 1
    }
    $2 = $2 - 1

    $dsPick = Read-Host "Number of the datastore you would like to use"

    if ($dsPick -ge 1 -and $dsPick -le $2) {
        $dsPick = $dsPick - 1

        $ds = Get-DataStore -Name $dsList[$dsPick]
        
        return $ds
    } else {
        Write-Host "Invalid input, goodbye"
        exit
    }
}

### Usage: New-SnapshotFrom-Name -vmName (name of vm)
function New-480SnapshotFrom-Name([string] $vmName) {
    $vm = Get-VM -name $vmName
    $vm | New-Snapshot -Name "Base" 
}

### Usage: Select-NetworkAdapters
function Set-480NetworkAdapters() {
    $vmlist = Get-VM | Select-Object -ExpandProperty Name

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE VMs =-=-=-"
    $1 = 1
    foreach ($vm in $vmlist) {
        Write-Host "$1. $vm"
        $1+=1
    }
    
    $vindex = Read-Host "Index of VM to make network adapter change to"

    $vindex = [int]$vindex
    $vindex-=1

    try {
        $vname = $vmlist[$vindex]
        Write-Host "You picked $vname"
    } catch {
        Write-Host "Invalid index. Goodbye..."
        exit
    }
    $v = Get-VM -Name $vname

    $vadapters = $v | Get-NetworkAdapter | Select-Object -ExpandProperty "Name"

    # If there is only 1 adapter, skip picking which adapter
    if ($vadapters.Length -eq [string]$vadapters.Length) {
        $adapter = $vadapters
    } else {
        Write-Host "`n"
        Write-Host "-=-=-= AVAILABLE ADAPTERS =-=-=-"
        $3 = 1
        foreach ($adapter in $vadapters) {
            Write-Host "$3. $adapter"
            $3+=1
        }

        $adapterPickIndex = Read-Host "Index of the network adapter to edit"

        try {
            $adapterPickIndex = [int]$adapterPickIndex
            $adapterPickIndex-=1
        } catch {
            Bad index. Aborting...
            exit
        }
    
        $adapter = $vadapters[$adapterPickIndex]
        Write-Host "You picked $adapter"
    }

    $vNetworks = Get-VirtualNetwork | Select-Object -ExpandProperty "Name"

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE NETWORKS =-=-=-"
    $2 = 1
    foreach ($network in $vNetworks) {
        Write-Host "$2. $network"
        $2+=1   
    }

    $networkIndex = Read-Host "Index of network to set the adapter to"

    $networkIndex = [int]$networkIndex - 1
    
    try {
        $networkName = $vNetworks[$networkIndex]
    } catch {
        Invalid index. Goodbye...
    }
    Write-Host "You picked $networkName"

    Write-Host "-=-=-= SUMMARY =-=-=-"
    Write-Host "VM Name: $vname"
    Write-Host "Adapter: $adapter"
    Write-Host "Network: $networkName"

    Get-VM -Name $vname | Get-NetworkAdapter -Name $adapter | Set-NetworkAdapter -Portgroup $networkName

}

### Usage: 480Cloner -config_path (path to JSON)
function 480Cloner([string] $config_path) {
    # Grab 480.json
    $conf = Get-480Config($config_path)

    # Connect to vCenter
    480Connect($conf.vcenter_server)

    # Pick Base VM folder
    $folder = Select-480BaseVMFolder

    # Pick VM
    $vmName = Select-480BaseVM($folder)

    # Get a VM object of the chosen VM
    $vm = Get-VM -Name $vmName

    # Pick snapshot
    $snapshot = Select-480Snapshot($vm)

    # Pick datastore
    $datastore = Select-480Datastore

    # Set name
    $linkedClone = "{0}.linked" -f $vm.name

    $esxiIP = $conf.esxi_host

    # Summary & Confirm
    Write-Host "`n"
    Write-Host "-=-=-= LINKED VM SUMMARY =-=-=-"
    Write-Host "Name: $linkedClone"
    Write-Host "Base VM: $vm"
    Write-Host "Ref Snapshot: $snapshot"
    Write-Host "ESXi IP: $esxiIP"
    Write-Host "Datastore: $datastore"

    $c = Read-Host "Proceed with creation of linked clone? (y/n)"

    if ($c -eq "y" -or $c -eq "Y") {
        Write-Host "Proceeding with linked clone creation..."
    } else {
        Write-Host "Aborting..."
        exit #Maybe replace with a loop back to a main menu?
    }

    # Create linked clone
    $linkedvm = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $esxiIP -Datastore $datastore

    $d = Read-Host "Proceed with full clone creation? (y/n)"

    if ($d -eq "y" -or $d -eq "Y") {

    } else {
        Write-Host "Exiting..."
        exit
    }

    $systemName = Read-Host "What is the OS name? (e.g. 'ubuntu' or 'server2019')"

    $num = "x"
    $numInput = Read-Host "Please provide the version number [x]"
    if(![string]::IsNullOrWhiteSpace($numInput)) {
        $num = $numInput
    }

    $newVmName = "{0}.base.v{1}" -f $systemName, $num
    
    # Create the new VM:
    New-VM -Name $newVmName -VMHost $esxiIP -VM $linkedClone -Datastore $datastore

    # Grab a snapshot:
    New-480SnapshotFrom-Name($newVmName)

    # Remove temporary linked clone:
    $linkedvm | Remove-VM

    Write-Host "Complete! Exiting..."

    # Network adapter change
    Set-480NetworkAdapters
}