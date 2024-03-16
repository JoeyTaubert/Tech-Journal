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
        return
    }

    $selectedvmname = $selectedvm.name
    Write-Host "You picked " -NoNewline
    Write-Host "$selectedvmname" -ForegroundColor Green
    return $selectedvm
}

function Select-480BaseVMName {
    $folder = Select-480BaseVMFolder

    $vmlist = Get-VM -Location $folder | Select-Object -ExpandProperty Name

    Write-Host "`n"
    Write-Host "-=-=-= AVAILABLE VMs IN $folder =-=-=-" -ForegroundColor Green
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

        return $vname #Returns a vm name as string

    } else {
        Write-Host "Invalid index. Goodbye..." -ForegroundColor Red
        return
    }
    
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
        return
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
        return
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
        return
    }
}

### Usage: New-SnapshotFrom-Name -vmName (name of vm)
function New-480SnapshotFrom-Name([string] $vmName) {

    if (-not $vmName) {
        $vmName = Select-480BaseVMName
    }

    $vm = Get-VM -name $vmName

    $defaultSnapName = "Base"

    $snapName = Read-Host "What would you like to name the snapshot? [Base]"

    # If no input was provided, proceed with default snapshot name
    if ($snapName -eq "") {
        $snapName = $defaultSnapName
    }

    $vm | New-Snapshot -Name $snapName | Out-Null # Out-Null discards standard output stream
}

### Usage: Set-NetworkAdapters [-vname (VM Name) (OPTIONAL)]
function Set-480NetworkAdapters($vname) {
    # If a parameter was provided, continue
    if ($vname) {
        Write-Host "Selected VM: " -NoNewline
        Write-Host "$vname" -ForegroundColor Green
    # If no parameter was provided, get the desired VM
    } else {
        $vname = Select-480BaseVMName
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
            return
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
        return
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
        return
    } else {

    }

    # Prompt to confirm creation of linked clone
    $c = Read-Host "Proceed with creation of linked clone? (y/n)" 

    if ($c -eq "y" -or $c -eq "Y") {
        Write-Host "Creating linked clone, " -NoNewline
        Write-Host "$linkedClone" -ForegroundColor Green
    } else {
        Write-Host "Aborting..." -ForegroundColor Green
        return #Maybe replace with a loop back to a main menu?
    }

    Write-Host "`n"

    # Create linked clone
    $linkedvm = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $esxiIP -Datastore $datastore
    
    # Prompt for full clone creation
    $d = Read-Host "Proceed with full clone creation? (y/n)"

    # If yes, proceed. If no, exit
    if ($d -eq "y" -or $d -eq "Y") {

    } else {
        Write-Host ""
        $renameLinkedInput = Read-Host "Would you like to rename the linked VM? (y/n)"

        if ($renameLinkedInput -eq "y" -or $renameLinkedInput -eq "Y") {
            Write-Host ""
            $newName = Read-Host "New name of linked clone"
            Set-VM -VM $linkedClone -Name $newName -Confirm:$false
            return
        } else {
            Write-Host "Linked clone complete. Exiting..." -ForegroundColor Green
            return
        }
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
        return
    } else {
        # If the name does not already exist, create the VM
        Write-Host "Creating new VM, " -NoNewline
        Write-Host "$newVmName" -ForegroundColor Green
        # Create the new VM:
        New-VM -Name $newVmName -VMHost $esxiIP -VM $linkedClone -Datastore $datastore | Out-Null # Out-Null discards standard output stream
    }

    # Grab a snapshot:
    Write-Host "`n"
    Write-Host "Getting snapshot..."
    New-480SnapshotFrom-Name($newVmName)

    # Remove temporary linked clone:
    Write-Host "Removing temporary VM, " -NoNewline
    Write-Host "$linkedClone" -ForegroundColor Yellow
    $linkedvm | Remove-VM -Confirm:$false

    Write-Host "`n"
    # Prompt network adapter change

    Write-Host "Would you like to change a network adapter of " -NoNewline
    Write-Host "$newVmName" -ForegroundColor Green -NoNewline
    $nchoice = Read-Host "? (y/n)"

    # If yes, start Set-480NetworkAdapters with parameter
    if ($nchoice -eq "y" -or $nchoice -eq "Y") {
        Set-480NetworkAdapters($newVmName)
        $adapterCheck = 0
        while ($adapterCheck -eq 0) {
            Write-Host "Would you like to change another network adapter of " -NoNewline
            Write-Host "$newVmName" -ForegroundColor Green -NoNewline
            $mchoice = Read-Host "? (y/n)"
            if ($mchoice -eq "y" -or $mchoice -eq "Y") {    
                Set-480NetworkAdapters($newVmName)
            } else {
                $adapterCheck += 1
            }
        }
    } else {
        # Continue
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
    # ChatGPT helped me come up with this param block
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
        $folder = Select-480BaseVMFolder

        $vmlist = Get-VM -Location $folder | Select-Object -ExpandProperty Name

        Write-Host "`n"
        Write-Host "-=-=-= AVAILABLE VMs IN $folder =-=-=-" -ForegroundColor Green
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
            return
        }

        $vindex-=1
        $vindex = [int]$vindex
        $vname = $vmlist[$vindex]

        Write-Host "You picked " -NoNewline
        Write-Host "$vname" -ForegroundColor Green

    }

    if (-not $powerAction){
        # Check current power state of VM
        $currentState = Get-VM -Name "$vname" | Select-Object -ExpandProperty PowerState

        switch ($currentState) {
            "PoweredOn" {
                $powerStr = "powered on"

                # Display power state
                Write-Host ""
                Write-Host "$vname" -ForegroundColor Green -NoNewline
                Write-Host " is currently " -NoNewline
                Write-Host "$($powerStr)" -ForegroundColor Green -NoNewline
                Write-Host "."

                Write-Host "Would you like to power off " -NoNewline
                Write-Host "$($vname)" -ForegroundColor Green -NoNewline
                $powchoice2 = Read-Host "? (y/n)"

                if ($powchoice2 -eq "y" -or $powchoice2 -eq "Y"){
                    $powerAction = "Off"
                } else {
                    Write-Host "Aborting..." -ForegroundColor Red
                    return
                }

            }
            "PoweredOff" {
                $powerStr = "powered off"

                # Display power state
                Write-Host ""
                Write-Host "$vname" -ForegroundColor Green -NoNewline
                Write-Host " is currently " -NoNewline
                Write-Host "$($powerStr)" -ForegroundColor Red -NoNewline
                Write-Host "."

                Write-Host "Would you like to power on " -NoNewline
                Write-Host "$($vname)" -ForegroundColor Green -NoNewline
                $powchoice2 = Read-Host "? (y/n)"

                if ($powchoice2 -eq "y" -or $powchoice2 -eq "Y"){
                    $powerAction = "On"
                } else {
                    Write-Host "Aborting..." -ForegroundColor Red
                    return
                }

            }
            default {
                Write-Host "Error, cannot get VM state. Exiting..." -ForegroundColor Red
                return
            }
        }
    }

    # Old workflow if the command was used without params
    ## If $powerAction was not supplied, prompt for a choice
    #if (-not $powerAction) {
    #    Write-Host "`n"
    #    Write-Host "-=-=-= ACTIONS =-=-=-" -ForegroundColor Green
    #    Write-Host "1. Power On"
    #    Write-Host "2. Power Off"
    #
    #    $actionChoice = Read-Host "What number action would you like to take?"
    #    
    #    # Based on choice, set $actionChoice to "On" or "Off"
    #    if ($actionChoice -eq "1") {
    #        $powerAction = "On"
    #    } elseif ($actionChoice -eq "2") {
    #        $powerAction = "Off"
    #    } else {
    #        Write-Host "No valid selection. Exiting..." -ForegroundColor Red
    #        return
    #    }
    #}

    # I need to handle if a powerAction parameter is specified to the power state the VM is already in.
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
    $powOut | Out-Null
}

function Get-480IP {
    $selectedvmname = Select-480BaseVMName

    $vmObj = Get-VM -Name $selectedvmname

    # ChatGPT helped me with this line
    $macs = $vmObj | Get-NetworkAdapter | Select-Object -ExpandProperty MacAddress

    Write-Host "-=-=-= NETWORKING SUMMARY FOR $($selectedvmname) =-=-=-" -ForegroundColor Green

    if ($macs -is [string]) {
        Write-Host "MAC (Net Ad1): " -NoNewline
        Write-Host "$macs" -ForegroundColor Yellow
    } elseif ($macs -is [array]) {
        $2 = 1
        foreach ($mac in $macs) {
            Write-Host "MAC (Net Ad$($2)): " -NoNewline
            Write-Host "$mac" -ForegroundColor Yellow
            $2 += 1
        }
    } else {
        Write-Host "MAC list of incorrect type. Exiting..." -ForegroundColor Red
        return
    }
    
    $ips = (Get-VM "$($selectedvmname)" | Get-VMGuest).IPAddress

    if (-not $ips) {
        $ips = "VMWare Tools missing or VM powered off"
    } 

    $newIps = New-Object System.Collections.ArrayList

    # ChatGPT helped me with filtering out IPv6 addresses
    $newIps = $ips | Where-Object { -not ($_ -match ":") }

    if ($newIps.Count -eq 1) {
        Write-Host "IP (Net Ad1): " -NoNewline
        Write-Host "$newIps" -ForegroundColor Yellow
    } else {
        $3 = 1
        foreach ($address in $newIps) {
            Write-Host "IP (Net Ad$($3)): " -NoNewline
            Write-Host "$address" -ForegroundColor Yellow
            $3 += 1
        }
    }

}

function New-480Network {
    $nameInput = Read-Host "Name of new vSwitch"

    $vSwitchOut = New-VirtualSwitch -VMHost 192.168.7.27 -Name $nameInput -ErrorAction Stop

    Write-Host "Virtual switch, " -NoNewline
    Write-Host "$($vSwitchOut.Name)" -ForegroundColor Green -NoNewline
    Write-Host ", created"

    Write-Host ""
    $portGroupInput = Read-Host "What would you like to name the associated port group? [$nameInput]"

    # If no input provided, just use the name of the switch
    if (-not $portGroupInput) {
        $portGroupInput = $nameInput
    }

    $portGroupOut = New-VirtualPortGroup -VirtualSwitch $nameInput -Name $portGroupInput -ErrorAction Stop

    Write-Host "Virtual port group, " -NoNewline
    Write-Host "$($portGroupOut.Name)" -ForegroundColor Green -NoNewline
    Write-Host ", created. Exiting..."
}

function Remove-480Network([string]$vSwitchName) {

    # If the parameter was not provided, prompt for a vSwitch 
    if (-not $vSwitchName) {
        Write-Host "-=-=-= vSwitch List =-=-=-" -ForegroundColor Green
    
        $switches = Get-VirtualSwitch
    
        $1 = 1
    
        foreach ($switch in $switches) {
            Write-Host "$($1). $($switch.Name)"
            $1 += 1
        }

        $vSwitchIndex = Read-Host "Index of vSwitch to remove"

        # Grabbing the vSwitch object and input validation

       
        $1 -= 1

        if ($vSwitchIndex -gt 0 -and $vSwitchIndex -le $1) {
               $vSwitchIndex = [int]$vSwitchIndex - 1
               $vSwitch = $switches[$vSwitchIndex]
            } else {
               Write-Host "Invalid index, exiting..." -ForegroundColor Red
               return
            }

    $vSwitchName = $vSwitch.Name
    }
    
    # ChatGPT helped me come up with this logic
    # Remove the selected virtual switch
    Get-VirtualSwitch -VMHost 192.168.7.27 -Name $vSwitchName | Remove-VirtualSwitch -Confirm:$false -ErrorAction Stop

    Write-Host "vSwitch, " -NoNewline
    Write-Host "$vSwitchName" -ForegroundColor Green -NoNewline
    Write-Host ", removed. Exiting..."
}

function 480Network {
    Write-Host "-=-=-= 480Network Functions =-=-=-" -ForegroundColor Green
    Write-Host "1. " -NoNewline
    Write-Host "New-480Network" -ForegroundColor Yellow -NoNewline
    Write-Host " - Create a new vSwitch and port group"
    Write-Host "2. " -NoNewline
    Write-Host "Remove-480Network" -ForegroundColor Yellow -NoNewline
    Write-Host " - Remove a vSwitch and its port group"
    Write-Host "3. " -NoNewline
    Write-host "Exit" -ForegroundColor Red
    $input = Read-Host "Index of function to use"

    Write-Host ""

    switch([int]$input) {
        1 {
            New-480Network
        }

        2 {
            Remove-480Network
        }
        3 {
            Write-Host "Exiting..." -ForegroundColor Green
            return
        }
        # Learned about this from ChatGPT
        default {
            Write-Host "Invalid index. Exiting..." -ForegroundColor Red
            return
        }
    }
}

function 480Utils {
    480Banner
    
    480Connect -server "vcenter.joey.local"

    $end = $false

    while ($end -eq $false) {

        Write-Host ""
        Write-Host "-=-=-= 480-Utils Functions =-=-=-" -ForegroundColor Green
        Write-Host "1. " -NoNewline
        Write-Host "480Cloner" -ForegroundColor Yellow -NoNewline
        Write-Host " - Creates a linked/full clone"
        Write-Host "2. " -NoNewline
        Write-Host "480Network" -ForegroundColor Yellow -NoNewline
        Write-Host " - Add or remove vSwitches/Port Groups"
        Write-Host "3. " -NoNewline
        Write-Host "480PowerToggle" -ForegroundColor Yellow -NoNewline
        Write-Host " - Turn a VM ON or OFF"
        Write-Host "4. " -NoNewline
        Write-Host "Get-480IP" -ForegroundColor Yellow -NoNewline
        Write-Host " - Get MACs and IPs for a VM"
        Write-Host "5. " -NoNewline
        Write-Host "New-480SnapshotFrom-Name" -ForegroundColor Yellow -NoNewline
        Write-Host " - Grab a snapshot of a VM"
        Write-Host "6. " -NoNewline
        Write-Host "Set-480NetworkAdapters" -ForegroundColor Yellow -NoNewline
        Write-Host " - Change what network an adapter is set to"
        Write-Host "7. " -NoNewline
        Write-Host "Exit" -ForegroundColor Red

        Write-Host ""
        [int]$pick = Read-Host "What would you like to do?"

        Write-Host ""

        switch($pick) {
            1 {
                480Cloner -config_path /home/joey/Tech-Journal/SEC-480/modules/480-Utils/480.json 
            }
            2 {
                480Network
            }
            3 {
                480PowerToggle
            }
            4 {
                Get-480IP
            }
            5 {
                New-480SnapshotFrom-Name
            }
            6 { 
                Set-480NetworkAdapters
            }
            7 {
                $end = $true
                Write-Host "Exiting..." -ForegroundColor Green
                return
            }
            default {
                $end = $true
                Write-Host "Invalid input. Exiting..." -ForegroundColor Red
                return
            }
        }
    }
}