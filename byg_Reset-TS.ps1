<#
.SYNOPSIS
	Reset-TS
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
		[string]$Path = "C:\Log\Reset_TS.log"

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
$TS = Get-WmiObject -Namespace ROOT\ccm\SoftMgmtAgent -Query "SELECT * FROM CCM_TSExecutionRequest where ContentID ='PAP007CF'"

Write-Log "Found ContentID:$($TS.ContentID) | PackageName:$($TS.MIFPackageName) | CompletionState: $($TS.CompletionState) | Adv: $($TS.OptionalAdvertisements) | RunningState: $($TS.RunningState) | State: $($TS.State)"