#Set username
$User = Read-Host "Enter the username"

#Set password
$Password = Read-Host "Enter the password" -AsSecureString

#Create user with specified creds
New-LocalUser -Name $User -Password $Password

#Add user to admin group
Add-LocalGroupMember -Group "Administrators" -Member $User