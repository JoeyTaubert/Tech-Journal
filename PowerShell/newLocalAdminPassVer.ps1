$User = Read-Host "Set a username"

$Password = Read-Host "Set a password" -AsSecurestring

$PasswordV = Read-Host "Verify the password" -AsSecureString

if ( $Password -ceg $PasswordV ) {

New-LocalUser -Name $User -Password SPassword

Add-LocalGroupMember -Group "Administrators" -Member $User

} else {

Read-Host "Password verification failed, press «Enters and try again"

}
