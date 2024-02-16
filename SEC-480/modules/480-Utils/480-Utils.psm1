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

function 480Connect([string] $server) {
    # If this PowerCLI global variable is populated, we are already connected to a server
    $conn = $global:DefaultVIServer

    if ($conn){
        Write-Host "Already connected to $conn"
    } else {
        $conn = Connect-VIServer -Server $server
    }
}

function Get-480Config([string] $config_path) {
    $conf = $null

    if (Test-Path $config_path) {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        Write-Host "Using config file at $config_path"
    } else {
        Write-Host "Config file not found: $config_path"
    }
    return $conf
}

function Select-VM([string] $folder) {
    $selectedvm = $null
    try {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms) {
            Write-Host [$index] $vm.name
            $index += 1
        }
        $pickindex = Read-Host "Which index number do you pick?"
        # Error handling here
        $selectedvm = $vms[$pickindex - 1]
        $selectedvmname = $selectedvm.name
        Write-Host "You picked $selectedvmname"
        return $selectedvm
    } catch {
        Write-Host "Invalid folder option: $folder"
    }
}