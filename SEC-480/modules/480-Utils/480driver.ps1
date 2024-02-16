Import-Module '480-Utils' -Force

480Banner

$conf = Get-480Config -config_path "/home/joey/Tech-Journal/SEC-480/modules/480-Utils/480.json"
480Connect -server $conf.vcenter_server

Select-VM -folder "BASEVM"

