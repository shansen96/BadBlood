<#
    .Synopsis
       Generates users, groups, OUs, computers in an active directory domain.  Then places ACLs on random OUs
    .DESCRIPTION
       This tool is for research purposes and training only.  Intended only for personal use.  This adds a large number of objects into a domain, and should never be  run in production.
    .EXAMPLE
       There are currently no parameters for the tool.  Simply run the ps1 as a DA and it begins. Follow the prompts and type 'badblood' when appropriate and the tool runs.
    .OUTPUTS
       [String]
    .NOTES
       Written by David Rowe, Blog secframe.com
       Twitter : @davidprowe
       I take no responsibility for any issues caused by this script.  I am not responsible if this gets run in a production domain. 
      Thanks HuskyHacks for user/group/computer count modifications.  I moved them to parameters so that this tool can be called in a more rapid fashion.
    .FUNCTIONALITY
       Adds a ton of stuff into a domain.  Adds Users, Groups, OUs, Computers, and a vast amount of ACLs in a domain.
    .LINK
       http://www.secframe.com/badblood
   
    #>
[CmdletBinding()]
    
param
(
   [Parameter(Mandatory = $false,
      Position = 1,
      HelpMessage = 'Supply a count for user creation default 2500')]
   [Int32]$UserCount = 2500,
   [Parameter(Mandatory = $false,
      Position = 2,
      HelpMessage = 'Supply a count for user creation default 500')]
   [int32]$GroupCount = 500,
   [Parameter(Mandatory = $false,
      Position = 3,
      HelpMessage = 'Supply the script directory for where this script is stored')]
   [int32]$ComputerCount = 100,
   [Parameter(Mandatory = $false,
      Position = 4,
      HelpMessage = 'Skip the OU creation if you already have done it')]
   [switch]$SkipOuCreation,
   [Parameter(Mandatory = $false,
      Position = 5,
      HelpMessage = 'Skip the LAPS deployment if you already have done it')]
   [switch]$SkipLapsInstall,
   [Parameter(Mandatory = $false,
      Position = 6,
      HelpMessage = 'Make non-interactive for automation')]
   [switch]$NonInteractive
)
function Get-ScriptDirectory
{
   Split-Path -Parent $PSCommandPath
}
$basescriptPath = Get-ScriptDirectory
$totalscripts = 8

$i = 0
$badblood = "badblood"

if ($badblood -eq 'badblood')
{

   $Domain = Get-addomain

   # LAPS STUFF
   if ($PSBoundParameters.ContainsKey('SkipLapsInstall') -eq $false)
   {
      Write-Progress -Activity "Random Stuff into A domain" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
      .($basescriptPath + '\AD_LAPS_Install\InstallLAPSSchema.ps1')
      Write-Progress -Activity "Random Stuff into A domain: Install LAPS" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   else {}
   
   $I++


   #OU Structure Creation
   if ($PSBoundParameters.ContainsKey('SkipOuCreation') -eq $false)
   {
      .($basescriptPath + '\AD_OU_CreateStructure\CreateOUStructure.ps1')
      Write-Progress -Activity "Random Stuff into A domain - Creating OUs" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   else {}
   $I++

   
   # User Creation
   $ousAll = Get-adorganizationalunit -filter *
   write-host "Creating Users on Domain" -ForegroundColor Green
    
   
   Write-Progress -Activity "Random Stuff into A domain - Creating Users" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   $I++
   
   .($basescriptPath + '\AD_Users_Create\CreateUsers.ps1')
   $createuserscriptpath = $basescriptPath + '\AD_Users_Create\'
   do
   {
      createuser -Domain $Domain -OUList $ousAll -ScriptDir $createuserscriptpath
      Write-Progress -Activity "Random Stuff into A domain - Creating $UserCount Users" -Status "Progress:" -PercentComplete ($x / $UserCount * 100)
      $x++
   }while ($x -lt $UserCount)

   #Group Creation
   $AllUsers = Get-aduser -Filter *
   write-host "Creating Groups on Domain" -ForegroundColor Green

   $x = 1
   Write-Progress -Activity "Random Stuff into A domain - Creating $GroupCount Groups" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   $i++
   .($basescriptPath + '\AD_Groups_Create\CreateGroup.ps1')
   $createGroupScriptPath = $basescriptPath + '\AD_Groups_Create\'
    
   do
   {
      Creategroup -Domain $Domain -OUList $ousAll -UserList $AllUsers -ScriptDir $createGroupScriptPath
      Write-Progress -Activity "Random Stuff into A domain - Creating $GroupCount Groups" -Status "Progress:" -PercentComplete ($x / $GroupCount * 100)
      $x++
   }while ($x -lt $GroupCount)
   $Grouplist = Get-ADGroup -Filter { GroupCategory -eq "Security" -and GroupScope -eq "Global" } -Properties isCriticalSystemObject
   $LocalGroupList = Get-ADGroup -Filter { GroupScope -eq "domainlocal" } -Properties isCriticalSystemObject
   
   #Computer Creation Time
   write-host "Creating Computers on Domain" -ForegroundColor Green

   $X = 1
   Write-Progress -Activity "Random Stuff into A domain - Creating Computers" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   .($basescriptPath + '\AD_Computers_Create\CreateComputers.ps1')
   $I++
   do
   {
      Write-Progress -Activity "Random Stuff into A domain - Creating $ComputerCount computers" -Status "Progress:" -PercentComplete ($x / $ComputerCount * 100)
      createcomputer
      $x++
   }while ($x -lt $ComputerCount)
   $Complist = get-adcomputer -filter *
    
   <#
   #Permission Creation of ACLs
   $I++
   write-host "Creating Permissions on Domain" -ForegroundColor Green
   Write-Progress -Activity "Random Stuff into A domain - Creating Random Permissions" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   #.($basescriptPath + '\AD_Permissions_Randomizer\GenerateRandomPermissions.ps1')
    
    
   # Nesting of objects
   $I++
   write-host "Nesting objects into groups on Domain" -ForegroundColor Green
   .($basescriptPath + '\AD_Groups_Create\AddRandomToGroups.ps1')
   Write-Progress -Activity "Random Stuff into A domain - Adding Stuff to Stuff and Things" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   AddRandomToGroups -Domain $Domain -Userlist $AllUsers -GroupList $Grouplist -LocalGroupList $LocalGroupList -complist $Complist

   # ATTACK Vector Automation

   # SPN Generation
   $I++
   write-host "Adding random SPNs to a few User and Computer Objects" -ForegroundColor Green
   Write-Progress -Activity "SPN Stuff Now" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   .($basescriptpath + '\AD_Attack_Vectors\AD_SPN_Randomizer\CreateRandomSPNs.ps1')
   CreateRandomSPNs -SPNCount 50

   write-host "Adding ASREP for a few users" -ForegroundColor Green
   Write-Progress -Activity "Adding ASREP Now" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   # get .05 percent of the all users output and asrep them
   $ASREPCount = [Math]::Ceiling($AllUsers.count * .05)
   $ASREPUsers = @()
   $asrep = 1
   do {

      $ASREPUsers += get-random($AllUsers)
      $asrep++}while($asrep -le $ASREPCount)

   # .($basescriptpath + '\AD_Attack_Vectors\ASREP_NotReqPreAuth.ps1')
   ADREP_NotReqPreAuth -UserList $ASREPUsers
      <#
   write-host "Adding Weak User Passwords for a few users" -ForegroundColor Green
   Write-Progress -Activity "Adding Weak User Passwords" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   # get .05 percent of the all users output and asrep them
   $WeakCount = [Math]::Ceiling($AllUsers.count * .02)
   $WeakUsers = @()
   $asrep = 1
   do {

      $WeakUsers += get-random($AllUsers)
      $asrep++}while($asrep -le $WeakCount)

   .($basescriptpath + '\AD_Attack_Vectors\WeakUserPasswords.ps1')
   WeakUserPasswords -UserList $WeakUsers
    #>

    # Further Active Directory configuration

    $SiteLandFillA = New-ADReplicationSite -Confirm:$false -Name "LandfillA" -PassThru
    $SiteLandFillB = New-ADReplicationSite -Confirm:$false -Name "LandfillB" -PassThru
    $SiteTrashChute = New-ADReplicationSite -Confirm:$false -Name "TrashChute" -TopologyDetectStaleEnabled:$false -PassThru
    $SiteDumpsterInAlley = New-ADReplicationSite -Confirm:$false -Name "DumpsterInAlley" -PassThru
    $SiteHyperconvergedInfrastructure = New-ADReplicationSite -Confirm:$false -Name "HyperconvergedInfrastructure" -PassThru

    New-ADReplicationSubnet -Confirm:$false -Name "192.168.1.0/24" -Site $SiteLandFillA.Name
    New-ADReplicationSubnet -Confirm:$false -Name "192.168.2.0/24" -Site $SiteLandFillB.Name
    New-ADReplicationSubnet -Confirm:$false -Name "192.168.3.0/24" -Site $SiteTrashChute.Name
    New-ADReplicationSubnet -Confirm:$false -Name "192.168.4.0/24" -Site $SiteDumpsterInAlley.Name
    New-ADReplicationSubnet -Confirm:$false -Name "192.168.5.0/24" -Site $SiteHyperconvergedInfrastructure.Name

    New-ADReplicationSiteLink -Name "LandfillA-LandfillB" -SitesIncluded "LandfillA","LandfillB" -OtherAttributes @{'cost'= 50} -Confirm:$false
    New-ADReplicationSiteLink -Name "TrashChute-Dumpster" -SitesIncluded "TrashChute","DumpsterInAlley" -OtherAttributes @{'cost'= 5} -Confirm:$false
    New-ADReplicationSiteLink -Name "HyperConvergedInfrastructure-LandFillA" -SitesIncluded "LandfillA","HyperconvergedInfrastructure" -OtherAttributes @{'cost'= 99} -Confirm:$false
    Start-Sleep -Seconds 10
    New-ADReplicationSiteLinkBridge -Name "TrashPipeline-Landfills" -SiteLinksIncluded "LandfillA-LandfillB","TrashChute-Dumpster" -Confirm:$false
}