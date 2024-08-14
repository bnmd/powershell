<#
.SYNOPSIS
	CheckLastUpdate 
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
		[string]$Path = "C:\Log\Result_update_100.log"

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
Write-Log "listing.."

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$HistoryCount = $Searcher.GetTotalHistoryCount()
$Updates = $Searcher.QueryHistory(1,$HistoryCount) 
Foreach ($Update in $Updates){
$Date = $Update.Date
$Title = $Update.Title
$Description = $UPdate.Description
Write-Log "$Date ! $Title ! $Description"
}