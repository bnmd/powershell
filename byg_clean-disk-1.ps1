<#
.SYNOPSIS
	Clean disk remotely 
.DESCRIPTION
	Clean disk remotely 
    Run in MCM tool
.EXAMPLE
	PS> ./byg_clean-disk.ps1
.LINK
	https://github.com/bnmd
.NOTES
	Author: BYG | License: BYG
	Last update: 2019-02-28
	Status: Tested / Not Tested / Failed
#>

$SageStateFlag = "StateFlags0911"
$Base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$CleanMgr = "$env:WINDIR\System32\cleanmgr.exe"

$ExcludeList =@(
"DownloadsFolder"
"BranchCache"
"Device Driver Packages"
)

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
        [string]$Path = "C:\Log\CleanDisk__v1.1.log"
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

        If ((Get-ItemProperty $Path).length -gt 5000000)
        { 
            $Old = "C:\Log\" + [System.IO.Path]::GetFileNameWithoutExtension($Path) + "_Old.log"
            Copy-Item $Path $Old -force 
            New-Item -path $Path -type file -force 
        }

        $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Verbose $Message
        "$date $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}


Start-Transcript -Path C:\log\Clean_Migration_Folder_v1.1.log -Append -Force



#Starting Script
#Get Locations list : it doesn't matter which WinVer. Behavior detect : folder list change dipending on Winversion

#Capture current free disk space on Drive C
Write-Log "Capture current free disk space on Drive C"
$FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB


$Results = Get-ChildItem $Base

If(!$?)
{
	#error
	Write-Error "Unable to retrieve data from the registry"
}
ElseIf($? -and $null -eq $results)
{
	#nothing there
	Write-Host "Didn't find anything in HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches which is odd"
}
Else
{
	ForEach($result in $results)
	{
        $Location = $Result.Name.Split("\")[-1]	
	    If($Location -inotin $ExcludeList)
	    {
            $Path = "$Base\$Location"
		    Write-Host "Setting ""$Location"" to 2"
		    $null = New-ItemProperty -Path $Path -Name $SageStateFlag -Value 2 -PropertyType DWORD -Force -EA 0
				
		    If(!$?)
		    {
			    Write-Warning "`tUnable to set $Path"
		    }
	    }
    }
	Write-Host "Script ended Successfully"
}


If (Test-Path -Path $CleanMgr){
    Start-Process -FilePath $CleanMgr -Wait -ArgumentList "/sagerun:911" -WindowStyle Hidden

}else{
    
    Write-Log "file $CleanMgr not found!!"
}

$FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
Write-Log "Free Space Before: {0} $FreespaceBefore"
Write-Log "Free Space After: {0} $FreespaceAfter"


Stop-Transcript