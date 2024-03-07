Import-Module '480-Utils' -Force

480Banner
480Connect -server "vcenter.joey.local"

# 480Cloner -config_path /home/joey/Tech-Journal/SEC-480/modules/480-Utils/480.json 

# New-480SnapshotFrom-Name -vmName dc1

# Set-480NetworkAdapters
# Set-NetworkAdapters -vname awx
# 480PowerToggle -vname awx -powerAction "Off"