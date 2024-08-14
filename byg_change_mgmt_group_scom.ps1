<#
.SYNOPSIS
	SCOM - Change management group 
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
If (Get-Service HealthService){
	$ManagementServerPool=@("BCNVSRV718.bycc.com", "BCNVSRV719.bycc.com", "BCNVSRV784.bycc.com")
	$ManagementGroupName="SCOMPROD"
	$ManagementServerName=Get-Random $ManagementServerPool
	$NewObject = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
	$NewObject.RemoveManagementGroup("$ManagementGroupName")
	$NewObject = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
	$NewObject.AddManagementGroup("$ManagementGroupName", "$ManagementServerName",5723)
	Stop-Service HealthService
	Remove-Item "C:\Program Files\Microsoft Monitoring Agent\Agent\Health Service State"  -Recurse -Force
	Start-Service HealthService
	}else{
	exit
	}