$User = Read-Host "Enter username for passwordless local account"

New-LocalUser -Name $User -NoPassword 

Set-Localuser -Name $User -PasswordNeverExpires:$true