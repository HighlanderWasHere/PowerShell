# Specify the source and destination OUs
$sourceOU = "OU=SourceOU,DC=domain,DC=com";
$destinationOU = "OU=DestinationOU,DC=domain,DC=com";
 
# Get all users from the source OU
$users = Get-ADUser -Filter * -SearchBase $sourceOU
 
# Move each user to the destination OU
foreach ($user in $users) {
Move-ADObject -Identity $user.DistinguishedName -TargetPath $destinationOU
Write-Host "Moved user $($user.Name) to $destinationOU"
}
