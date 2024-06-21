<#
.SYNOPSIS
	démarrer Branchcache sur DP
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

Set-Service -Name PeerDistSvc -StartupType Automatic
$svcStatus = Get-Service PeerDistSvc | Select-Object -Property Name, StartType, Status
if ($svcStatus.Status -ne 'Running'){start-service -Name PeerDistSvc}