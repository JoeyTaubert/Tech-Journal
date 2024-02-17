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
    Start-Sleep -Seconds 1
}
### Usage: 480Connect -server (IP of ESXI)
function 480Connect([string] $server) {
    # If this PowerCLI global variable is populated, we are already connected to a server
    $conn = $global:DefaultVIServer

    if ($conn){
        Write-Host "Already connected to " -NoNewline
        Write-Host "$conn" -ForegroundColor Green
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
        Write-Host "Using config file at " -NoNewline
        Write-Host "$config_path" -ForegroundColor Green
    } else {
        Write-Host "Config file not found: $config_path" -ForegroundColor Red
    }
    return $conf
}

function Select-480BaseVM([string] $folder) {
    $selectedvm = $null

    $vms = Get-VM -Location $folder
    $index = 1

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE VMs IN $folder =-=-=-" -ForegroundColor Green
    foreach($vm in $vms) {
        Write-Host [$index] $vm.name
        $index += 1
    }
    $pickindex = Read-Host "Index number of desired VM"
    $selectedvm = $vms[$pickindex - 1]

    # Input validation
    if ($vms -contains $selectedvm) {

    } else {
        Write-Host "Invalid index. Goodbye..." -ForegroundColor Red
        exit
    }

    $selectedvmname = $selectedvm.name
    Write-Host "You picked " -NoNewline
    Write-Host "$selectedvmname" -ForegroundColor Green
    return $selectedvm
}

function Select-480BaseVMFolder() {
    # Get all available VM folders and then list them
    $availableFolders = Get-Folder -Type VM | Where-Object { $_.Name -ne 'vm' } | Select-Object -ExpandProperty Name

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE FOLDERS =-=-=-" -ForegroundColor Green
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
        Write-Host "You picked " -NoNewline
        Write-Host "$folderName" -ForegroundColor Green
        $folder = $availableFolders[$folderIndex]

    } else {
        Write-Host "Invalid index. Goodbye..." -ForegroundColor Red
        exit
    }

    return $folder
}

function Select-480Snapshot([VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine] $vm) {
    $snapshots = Get-Snapshot -VM $vm
    
    Write-Host "`n"
    Write-Host "-=-=-= SNAPSHOT LIST FOR $vm =-=-=-" -ForegroundColor Green
    $1 = 1
    foreach($snapshot in $snapshots) {
        Write-Host "$1. $snapshot"
        $1+=1
    }

    $snapshotIndex = Read-Host "Number of the snapshot to use"


    $snapshotChoice = $snapshots[$snapshotIndex - 1]

    if ($snapshots -contains $snapshotChoice) {
        Write-Host "You picked " -NoNewline
        Write-Host "$snapshotChoice" -ForegroundColor Green
    } else {
        Write-Host "Invalid index. Goodbye..." -ForegroundColor Red
        exit
    }

    return $snapshotChoice
}

function Select-480Datastore() {
    $dsList = Get-Datastore | Select-Object -ExpandProperty "Name"

    Write-Host "`n"
    Write-Host "-=-=-= DATASTORE LIST =-=-=-" -ForegroundColor Green
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
        
        Write-Host "You picked " -NoNewline
        Write-Host "$ds" -ForegroundColor Green

        return $ds
    } else {
        Write-Host "Invalid input. Goodbye..." -ForegroundColor Red
        exit
    }
}

### Usage: New-SnapshotFrom-Name -vmName (name of vm)
function New-480SnapshotFrom-Name([string] $vmName) {
    $vm = Get-VM -name $vmName
    $vm | New-Snapshot -Name "Base" | Out-Null # Out-Null discards standard output stream
}

### Usage: Set-NetworkAdapters [-vname (VM Name) (OPTIONAL)]
function Set-480NetworkAdapters($vname) {
    # If a parameter was provided, continue
    if ($vname) {
        Write-Host "Selected VM: " -NoNewline
        Write-Host "$vname" -ForegroundColor Green
    # If no parameter was provided, get the desired VM
    } else {
        $vmlist = Get-VM | Select-Object -ExpandProperty Name

        Write-Host "`n"
        Write-Host "-=-=-= AVAILABLE VMs =-=-=-" -ForegroundColor Green
        $1 = 1
        foreach ($vm in $vmlist) {
            Write-Host "$1. $vm"
            $1+=1
        }

        $1-=1

        $vindex = Read-Host "Index of VM to make network adapter change to"

        # Input validation
        if ([int]$vindex -le $1 -and [int]$vindex -ge 1) {
            $vindex = [int]$vindex
            $vindex-=1
            $vname = $vmlist[$vindex]
            Write-Host "You picked " -NoNewline
            Write-Host "$vname" -ForegroundColor Green
        } else {
            Write-Host "Invalid index. Goodbye..." -ForegroundColor Red
            exit
        }
    }


    $vadapters = Get-VM -Name $vname | Get-NetworkAdapter | Select-Object -ExpandProperty "Name"

    $adapterList = New-Object System.Collections.Generic.List[string]

    foreach ($adapter in $vadapters) {
        $adapterList.Add($adapter)
    }

    # If there is only 1 adapter, skip picking which adapter
    if ($adapterList.Count -ne 1) {
        $adapter = $adapterList[0]


        Write-Host "`n"
        Write-Host "-=-=-= AVAILABLE ADAPTERS =-=-=-" -ForegroundColor Green
        $3 = 1
        foreach ($adapter in $vadapters) {
            Write-Host "$3. $adapter"
            $3+=1
        }
        
        $3-=1
        $adapterPickIndex = Read-Host "Index of the network adapter to edit"

        if ([int]$adapterPickIndex -ge 1 -and [int]$adapterPickIndex -le $3) {

        } else {
            Write-Host "Bad index. Aborting..." -ForegroundColor Red
            exit
        }

        $adapterPickIndex = [int]$adapterPickIndex
        $adapterPickIndex-=1
    
        $adapter = $adapterList[$adapterPickIndex]
        Write-Host "You picked " -NoNewline
        Write-Host "$adapter" -ForegroundColor Green
    } else {
        $adapterPickIndex = 0
        $adapter = $adapterList[$adapterPickIndex]
        Write-Host "Selected " -NoNewline
        Write-Host "$adapter" -NoNewline -ForegroundColor Green
        Write-Host " as it is the only available adapter"
    }

    # Check what the adapter is currently set to and provide that info // No error thrown if try to set to network it is already on

    $vNetworks = Get-VirtualNetwork | Select-Object -ExpandProperty "Name"

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE NETWORKS =-=-=-" -ForegroundColor Green
    $2 = 1
    foreach ($network in $vNetworks) {
        Write-Host "$2. $network"
        $2+=1   
    }

    $2-=1

    $networkIndex = Read-Host "Index of network to set the adapter to"
    
    # Input validation
    if ([int]$networkIndex -ge 1 -and [int]$networkIndex -le $2) {

    } else {
        Write-Host "Invalid index. Exiting..." -ForegroundColor Red
        exit
    }

    $networkIndex = [int]$networkIndex - 1

    $networkName = $vNetworks[$networkIndex]

    Write-Host "You picked " -NoNewline
    Write-Host "$networkName" -ForegroundColor Green

    Write-Host "`n"
    Write-Host "-=-=-= ADAPTER CHANGE SUMMARY =-=-=-" -ForegroundColor Green
    Write-Host "VM Name: " -NoNewline
    Write-Host "$vname" -ForegroundColor Green
    Write-Host "Adapter: " -NoNewline
    Write-Host "$adapter" -ForegroundColor Green
    Write-Host "Network: " -NoNewline
    Write-Host "$networkName" -ForegroundColor Green

    # Proceed?
    $finalChoice = Read-Host "Proceed with network adapter change? (y/n)"

    if ($finalChoice -eq "y" -or $finalChoice -eq "Y") {
        Get-VM -Name $vname | Get-NetworkAdapter -Name $adapter | Set-NetworkAdapter -Portgroup $networkName -Confirm:$false | Out-Null # Discard standard output
    } else {
        Write-Host "Cancelling operation..." -ForegroundColor Yellow
    }


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
    Write-Host "-=-=-= LINKED VM SUMMARY =-=-=-" -ForegroundColor Green
    Write-Host "Name: " -NoNewline
    Write-Host "$linkedClone" -ForegroundColor Green
    Write-Host "Base VM: " -NoNewline
    Write-Host "$vm" -ForegroundColor Green
    Write-Host "Ref Snapshot: " -NoNewline
    Write-Host "$snapshot" -ForegroundColor Green
    Write-Host "ESXi IP: " -NoNewline
    Write-Host "$esxiIP" -ForegroundColor Green
    Write-Host "Datastore: " -NoNewline
    Write-Host "$datastore" -ForegroundColor Green

    # Check to make sure a linked clone with this name does not already exist
    $allVMs = Get-VM | Select-Object -ExpandProperty Name

    if ($allVMs -contains $linkedClone) {
        # Maybe check this earlier on and automatically delete it?
        Write-Host "Temporary linked clone already exists. Please delete it and try again. Exiting..." -ForegroundColor Red
        exit
    } else {

    }

    # Prompt to confirm creation of linked clone
    $c = Read-Host "Proceed with creation of linked clone? (y/n)" 

    if ($c -eq "y" -or $c -eq "Y") {
        Write-Host "Creating linked clone, " -NoNewline
        Write-Host "$linkedClone" -ForegroundColor Green
    } else {
        Write-Host "Aborting..." -ForegroundColor Green
        exit #Maybe replace with a loop back to a main menu?
    }

    Write-Host "`n"

    # Create linked clone
    $linkedvm = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $esxiIP -Datastore $datastore
    
    
    # Prompt for full clone creation
    $d = Read-Host "Proceed with full clone creation? (y/n)"

    # If yes, proceed. If no, exit
    if ($d -eq "y" -or $d -eq "Y") {

    } else {
        Write-Host "Exiting..." -ForegroundColor Green
        exit
    }

    # Prompt OS name to build VM name with
    $systemName = Read-Host "What is the OS name? (e.g. 'ubuntu' or 'server2019')"

    # Default version number to "x" if not provided
    $num = "x"
    $numInput = Read-Host "Please provide the version number [x]"
    if(![string]::IsNullOrWhiteSpace($numInput)) {
        $num = $numInput
    }

    # Build new VM name
    $newVmName = "{0}.base.v{1}" -f $systemName, $num
    
    # Check if the built VM name already exists
    $allVMs2 = Get-VM | Select-Object -ExpandProperty Name

    Write-Host "`n"

    if ($allVMs2 -contains $newVmName) {
        # If the name is a duplicate, exit
        Write-Host "Duplicate VM name. Exiting..." -ForegroundColor Red
        exit
    } else {
        # If the name does not already exist, create the VM
        Write-Host "Creating new VM, " -NoNewline
        Write-Host "$newVmName" -ForegroundColor Green
        # Create the new VM:
        New-VM -Name $newVmName -VMHost $esxiIP -VM $linkedClone -Datastore $datastore | Out-Null # Out-Null discards standard output stream
    }

    # Grab a snapshot:
    Write-Host "Getting snapshot..."
    New-480SnapshotFrom-Name($newVmName)

    # Remove temporary linked clone:
    Write-Host "Removing temporary VM, " -NoNewline
    Write-Host "$linkedClone" -ForegroundColor Yellow
    $linkedvm | Remove-VM -Confirm:$false

    Write-Host "`n"
    # Prompt network adapter change
    Write-Host "Would you like to change the network adapter of " -NoNewline
    Write-Host "$newVmName" -ForegroundColor Green -NoNewline
    $nchoice = Read-Host "? (y/n)"
    
    # If yes, start Set-480NetworkAdapters with parameter
    if ($nchoice -eq "y" -or $nchoice -eq "Y") {
        Set-480NetworkAdapters($newVmName)
    } else {

    }

    # Prompt to power on
    Write-Host "`n"
    Write-Host "Would you like to power on " -NoNewline
    Write-Host "$newVmName" -ForegroundColor Green -NoNewline
    $powchoice = Read-Host "? (y/n)"

    # If yes, start 480PowerToggle with parameters
    if ($powchoice -eq "y" -or $powchoice -eq "Y") {
        $powerAction = "On"
        480PowerToggle -vname $newVmName -powerAction $powerAction
    }

    Write-Host "Exiting..." -ForegroundColor Green
}

### Usage: 480PowerToggle [-vname (VM Name) (OPTIONAL)] [-powerAction ("On"/"Off") (OPTIONAL)]
function 480PowerToggle() {
    param(
        [string]$vname,
        [ValidateSet("On", "Off")]
        [string]$powerAction
    )

    # If a parameter was provided, continue
    if ($vname) {
        Write-Host "Selected VM: " -NoNewline
        Write-Host "$vname" -ForegroundColor Green
    # If no parameter was provided, get the desired VM
    } else {
        $vmlist = Get-VM | Select-Object -ExpandProperty Name

        Write-Host "`n"
        Write-Host "-=-=-= AVAILABLE VMs =-=-=-" -ForegroundColor Green
        $1 = 1
        foreach ($vm in $vmlist) {
            Write-Host "$1. $vm"
            $1+=1
        }

        $1-=1

        $vindex = Read-Host "Index of VM to make power change to"

    
        # Input validation
        if ([int]$vindex -le [int]$1 -and [int]$vindex -ge 1) {

        } else {
            Write-Host "Invalid index. Goodbye..." -ForegroundColor Red
            exit
        }

        $vindex-=1
        $vindex = [int]$vindex
        $vname = $vmlist[$vindex]

        Write-Host "You picked " -NoNewline
        Write-Host "$vname" -ForegroundColor Green

    }

    # If $powerAction was not supplied, prompt for a choice
    if (-not $powerAction) {
        Write-Host "`n"
        Write-Host "-=-=-= ACTIONS =-=-=-" -ForegroundColor Green
        Write-Host "1. Power On"
        Write-Host "2. Power Off"
    
        $actionChoice = Read-Host "What number action would you like to take?"
        
        # Based on choice, set $actionChoice to "On" or "Off"
        if ($actionChoice -eq "1") {
            $powerAction = "On"
        } elseif ($actionChoice -eq "2") {
            $powerAction = "Off"
        } else {
            Write-Host "No valid selection. Exiting..." -ForegroundColor Red
            exit
        }
    }

    # Check to see what state the VM is currently in and remove that option to prevent error

    # ChatGPT recommended this switch statement, which I thought was very nifty. I find it similar to a 'match' statement in Rust
    switch ($powerAction) {
        "On" {
            $powOut = Start-VM -VM $vname -Confirm:$false
            Write-Host "$vname" -ForegroundColor Green -NoNewline
            Write-Host " has been powered on."
        }
        "Off" {
            $powOut = Stop-VM -VM $vname -Confirm:$false 
            Write-Host "$vname" -ForegroundColor Green -NoNewline
            Write-Host " has been powered off."
        }
    }
}
