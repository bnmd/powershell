<#
.SYNOPSIS
	Check-TS-Upgrade1909 
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

Function Write-Log
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullorEmpty()]
		[Alias("LogContent")]
		[string]$Message,
		[Parameter(Mandatory = $false)]
		[Alias("LogPath")]
		[string]$Path = "C:\Log\Reset_TS..log"

	)
	Begin
	{
		
	}
	Process
	{
		If (!(Test-Path $Path))
		{
			$LogPath = New-Item -Path $Path -ItemType File -Force
		}
		$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		Write-Verbose $Message
		"$date $Message" | Out-File -FilePath $Path -Append
	}
	End
	{
	}
}

Write-Log "-----------------------------------------------------------------------------------------------"
$InfosTS = Get-WmiObject -Namespace ROOT\ccm\SoftMgmtAgent -Query "SELECT * FROM CCM_TSExecutionRequest where ContentID ='PAP007CE'"
$ID = $InfosTS.ContentID
$Statut = $InfosTS.CompletionState
write-log "Status TS Avant Script $ID : $Statut" 

# Retrieve the name of the task sequence that should be executed
Write-Log "Reset TS"
    Set-Service smstsmgr -StartupType manual
    Start-Service smstsmgr
    start-sleep -Seconds 5 
     if (Get-CimInstance -Namespace root/ccm -ClassName SMS_MaintenanceTaskRequests )
        {
Write-Log "Remove-CimInstance"
        Get-CimInstance -Namespace root/ccm -ClassName SMS_MaintenanceTaskRequests | Remove-CimInstance
        }
    if (Get-WmiObject -Namespace Root\CCM\SoftMgmtAgent -Class CCM_TSExecutionRequest)
        {
Write-Log "Remove-WmiObject"
        Get-WmiObject -Namespace Root\CCM\SoftMgmtAgent -Class CCM_TSExecutionRequest | Remove-WmiObject
        }
    if ((Get-Process CcmExec -ea SilentlyContinue) -ne $Null) {Get-Process CcmExec | Stop-Process -Force}
    #stop-service ccmexec
Write-Log "STOP ccmexec"
    if ((Get-Process TSManager -ea SilentlyContinue) -ne $Null) {Get-Process TSManager| Stop-Process -Force}
    #Stop-Service smstsmgr
Write-Log "STOP smstsmgr"
    Start-Sleep -Seconds 5
    Restart-Service -Name CcmExec -Force   
    Start-Service ccmexec
    Start-Sleep -Seconds 5
Write-Log "START ccmexec"
    Start-Service smstsmgr
    Start-Sleep -Seconds 20
Write-Log "START smstsmgr"
    if ((Get-Process TSManager -ea SilentlyContinue) -ne $Null) {Get-Process TSManager| Stop-Process -Force}
    Start-Sleep -Seconds 20
    if ((Get-Process CcmExec -ea SilentlyContinue) -ne $Null) {Get-Process CcmExec | Stop-Process -Force}
    Start-Sleep -Seconds 15
    Start-Service ccmexec
Write-Log "START ccmexec"
    start-sleep -Seconds 60
    Start-Process -FilePath C:\windows\ccm\CcmEval.exe
    #Trigger  Machine  Policy  Update
    Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}" |Out-Null
    Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000022}" |Out-Null
$InfosTS = Get-WmiObject -Namespace ROOT\ccm\SoftMgmtAgent -Query "SELECT * FROM CCM_TSExecutionRequest where ContentID ='PAP007CE'"
$ID = $InfosTS.ContentID
$Statut = $InfosTS.CompletionState
write-log "Status TS Après Script $ID : $Statut" 