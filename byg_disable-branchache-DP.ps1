<#
.SYNOPSIS
	disable branchcache on server 
.DESCRIPTION
    Run in MCM tool
.EXAMPLE
.LINK
	https://github.com/bnmd
.NOTES
	Timeout: 1800
	Author: BYG | License: BYG
	Last update: 2019-02-28
	Status: Tested / Not Tested / Failed
#>

Set-Service -Name PeerDistSvc -StartupType disabled
$svcStatus = Get-Service PeerDistSvc | Select-Object -Property Name, StartType, Status
if ($svcStatus.Status -eq 'Running'){stop-service -Name PeerDistSvc}
write-output "service: $($svcStatus.starttype) , statut: $($svcStatus.status)"