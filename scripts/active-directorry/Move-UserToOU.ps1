# Specify the source and destination OUs
$sourceOU = &quot;OU=SourceOU,DC=domain,DC=com&quot;
$destinationOU = &quot;OU=DestinationOU,DC=domain,DC=com&quot;
 
# Get all users from the source OU
$users = Get-ADUser -Filter * -SearchBase $sourceOU
 
# Move each user to the destination OU
foreach ($user in $users) {
Move-ADObject -Identity $user.DistinguishedName -TargetPath $destinationOU
Write-Host &quot;Moved user $($user.Name) to $destinationOU&quot;
}
