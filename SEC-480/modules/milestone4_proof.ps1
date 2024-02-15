# Choose a vCenter Server to connect to
$vcenterServer = "vcenter.joey.local"

$vcenterServerInput = Read-Host -Prompt "Which vCenter server would you like to connect to? [vcenter.joey.local]"

# This is a conditional that ChatGPT helped me come up with
if(![string]::IsNullOrWhiteSpace($vcenterServerInput)) {
    $vcenterServer = $vcenterServerInput
}

Connect-VIServer -Server $vcenterServer

# Base folder
$baseFolder = "BASEVM"

$baseFolderInput = Read-Host -Prompt "Folder name where base VM is located: [BASEVM]"

if(![string]::IsNullOrWhiteSpace($baseFolderInput)) {
    $baseFolder = $baseFolderInput
}

# Get a list of VMs
$VMsInFolder = Get-Folder -Name $baseFolder | Get-VM

$VMs = $VMsInFolder | Select-Object -ExpandProperty "Name" # -ExpandProperty will return the VM Names as string objects, rather than as a "Name" property of an object

# Create the list of VMs
$VMList = [System.Collections.Generic.List[string]]::new()

# Build & print the list, this might be redudnant because I think $VMsInFolder is already a list
$1 = 1
Write-Host "-=-=-= VM LIST =-=-=-"
foreach ($VM in $VMs) {
    Write-Host "$1. $VM"
    $VMList.Add($VM)
    $1 = $1 + 1
}
$1 = $1 - 1

# Choose target base VM
$vmInput = Read-Host "What is the index of the VM to use as a base?"
if ($vmInput -ge 1 -and $vmInput -le $1) {
    
} else {
    Write-Host "Invalid input, goodbye"
    exit
}

$vmIndex = [int]$vmInput - 1
$vmPick = $VMList[$vmIndex]
Write-Host "You chose $vmPick"


# Full clone or linked clone?
$cloneType = Read-Host "[F]ull clone or [L]inked clone:"

# Code for Full clone process
if ($cloneType -eq "F" -or "f") {
    # Get the IP of our ESXI server:
    $vmhost = Get-VMHost -Name "192.168.7.27"

    # Create a variable that holds the target base VM:
    $vm = Get-VM -Name $vmPick

    # Get name of new linked VM:
    $linkedClone = "{0}.linked" -f $vm.name

    # Grab the snapshot reference:
    $snapshot = Get-Snapshot -VM $vm -Name "Base"



    # Pick a datastore:
    $dsList = Get-Datastore | Select-Object -ExpandProperty "Name"


    Write-Host "-=-=-= DATASTORE LIST =-=-=-"
    $2 = 1
    foreach ($dsName in $dsList) {
        Write-Host "$2. $dsName"
        $2 = $2 + 1
    }
    $2 = $2 - 1

    $dsPick = Read-Host "What is the number of the datastore you would like to use? "

    if ($dsPick -ge 1 -and $dsPick -le $2) {

    } else {
        Write-Host "Invalid input, goodbye"
        exit
    }

    $dsPick = $dsPick - 1

    $ds = Get-DataStore -Name $dsList[$dsPick]

    Write-Host "Linked Clone Name: $linkedClone"
    Write-Host "Source VM for Clone: $vm"
    Write-Host "Reference Snapshot: $snapshot"
    Write-Host "Target VMHost: $vmhost"
    Write-Host "Target Datastore: $ds"

    # Create the linked clone:
    $linkedvm = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

    $systemName = Read-Host "What is the OS name? (e.g. 'ubuntu' or 'server2019')"

    $num = "x"
    $numInput = Read-Host "What version number is this base? Please choose one that has not been used already! [x]"
    if(![string]::IsNullOrWhiteSpace($numInput)) {
        $num = $numInput
    }

    $newVmName = "{0}.base.v{1}" -f $systemName, $num

    # Create the new VM:
    $newvm = New-VM -Name $newVmName -VM $linkedClone -VMHost $vmhost -Datastore $ds

    # Grab a snapshot:
    $newvm | new-snapshot -Name "Base"

    # Remove temporary linked clone:
    $linkedvm | Remove-VM

# Code for Linked clone process
} elseif ($cloneType -eq "L" -or "l") {
    # Get the IP of our ESXI server:
    $vmhost = Get-VMHost -Name "192.168.7.27"
    
    # Create a variable that holds the target base VM:
    $vm = Get-VM -Name $vmPick
    
    # Get name of new linked VM:
    $linkedClone = "{0}.linked" -f $vm.name
    
    # Grab the snapshot reference:
    $snapshot = Get-Snapshot -VM $vm -Name "Base"
    
    
    
    # Pick a datastore:
    $dsList = Get-Datastore | Select-Object -ExpandProperty "Name"
    
    
    Write-Host "-=-=-= DATASTORE LIST =-=-=-"
    $2 = 1
    foreach ($dsName in $dsList) {
        Write-Host "$2. $dsName"
        $2 = $2 + 1
    }
    $2 = $2 - 1
    
    $dsPick = Read-Host "What is the number of the datastore you would like to use? "
    
    if ($dsPick -ge 1 -and $dsPick -le $2) {
    
    } else {
        Write-Host "Invalid input, goodbye"
        exit
    }
    $dsPick = $dsPick - 1

    $ds = Get-DataStore -Name $dsList[$dsPick]
    
    # Create the linked clone:
    $linkedvm = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds

# Else exit
} else {
    Write-Host "Invalid input, goodbye"
    exit
}

