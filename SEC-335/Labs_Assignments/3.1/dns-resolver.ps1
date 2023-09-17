# Made by Joey Taubert. Credit to ChatGPT for assisting me with checking if the value of a varaible is null, and for providing me with the -ExpandProperty flag.

# Grabs the second and third input provided at the command line
param($network, $server)

# This for loop iterates through .1-.254 IPs, assuming that the first three octects are provided
for ($ip = 1; $ip -le 254; $ip++){
    $ipv4 = $network + "." + $ip
    $name = Resolve-DnsName -DnsOnly $ipv4 -Server $server -ErrorAction Ignore | select  -ExpandProperty NameHost 
        # Only print if a FQDN was found
        if ($name -ne $null){
        Write-Host "$ipv4 $name"
        } 
}