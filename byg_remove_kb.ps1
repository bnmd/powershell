<#
.SYNOPSIS
	Remove KB
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
		[string]$Path = "C:\Log\RemoveKB_HS.log"

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

Write-Log "Windows Operating System Hotfix KB remover"
#$HotFixCheck = "KB4539571"
#$HotFixRemove = "4539571"
$AllHotFix = (Get-Hotfix).HotFixID
Write-Log "List All KB: $ALLHotFix"
#$hotfixlist = Get-Hotfix | Where-Object { $_.HotFixID -like $HotFixCheck }
#if($hotfixlist -eq $null) { Write-Log "No KB4539571 installed"}
#else
Foreach ($hotfix in $AllHotFix)
{
Write-Log "KB FOUNED : $hotfix"
Write-Log "Uninstalling $HotFix"
wusa.exe /uninstall /KB:$HotFix /quiet /norestart
Write-Log "$HotFix uninstalled"
}