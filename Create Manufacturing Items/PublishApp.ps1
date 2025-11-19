$BCVersion = "200"
$Servicetier="BC"+$BCVersion
$AppName="Create Manufacturing Items"
$Path="C:\Install\Create Manufacturing Items\Bech-Andersen Consult ApS_Create Manufacturing Items_1.0.0.0.app"
$AppPath = 'C:\Program Files\Microsoft Dynamics 365 Business Central\' + $BCVersion + '\Service\NavAdminTool.ps1'

Import-Module $AppPath
# Publish app to database
Publish-NAVApp -ServerInstance $Servicetier -Path $Path -SkipVerification
Sync-NAVApp -ServerInstance $Servicetier -Name $AppName 
# Install in tenant
Install-NAVApp  -ServerInstance $Servicetier -Name $AppName 