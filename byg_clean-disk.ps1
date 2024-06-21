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
        [string]$Path = "C:\Log\CleanDisk.log"
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
            Copy-Item "C:\Log\CleanDisk.log" "C:\Log\CleanDisk_old.log" -force 
            New-Item -path "C:\Log\CleanDisk.log" -type file -force 
        }

        $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Verbose $Message
        "$date $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

function Delete-ComputerRestorePoints{
	[CmdletBinding(SupportsShouldProcess=$True)]param(  
	    [Parameter(
	        Position=0, 
	        Mandatory=$true, 
	        ValueFromPipeline=$true
		)]
	    $restorePoints
	)
	begin{
		$fullName="SystemRestore.DeleteRestorePoint"
		#check if the type is already loaded
		$isLoaded=([AppDomain]::CurrentDomain.GetAssemblies() | foreach {$_.GetTypes()} | where {$_.FullName -eq $fullName}) -ne $null
		if (!$isLoaded){
			$SRClient= Add-Type   -memberDefinition  @"
		    	[DllImport ("Srclient.dll")]
		        public static extern int SRRemoveRestorePoint (int index);
"@  -Name DeleteRestorePoint -NameSpace SystemRestore -PassThru
		}
	}
	process{
		foreach ($restorePoint in $restorePoints){
			if($PSCmdlet.ShouldProcess("$($restorePoint.Description)","Deleting Restorepoint")) {
		 		[SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($restorePoint.SequenceNumber)
			}
		}
	}
}
#Capture current free disk space on Drive C
Write-Log "Capture current free disk space on Drive C"
$FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB

#Deleting System Restore Points
Write-Log "Deleting System Restore Points"
Get-ComputerRestorePoint | Delete-ComputerRestorePoints

#Removing System and User Temp Files
Write-Log "Removing System and User Temp Files"
Remove-Item -Path "$env:windir\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:windir\minidump\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:windir\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Package\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "C:\`$Recycle.bin\*\" -Recurse -Force -exclude "desktop.ini"
Remove-Item -Path "$env:windir\SoftwareDistribution.old" -Force -Recurse -ErrorAction SilentlyContinue

#Removing Windows Updates Downloads
Write-Log "Removing Windows Updates Downloads"
Stop-Service wuauserv -Force
Stop-Service TrustedInstaller -Force
Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item $env:windir\Logs\CBS\* -force -recurse -ErrorAction SilentlyContinue
Get-ChildItem -Path "$env:windir\Installer\`$PatchCache`$" -Recurse -Force | ?{$_.LastWriteTime -lt (get-date).AddMonths(-2)} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Start-Service wuauserv
Start-Service TrustedInstaller

#Log Free Space
$FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
Write-Log "Free Space Before: {0} $FreespaceBefore"
Write-Log "Free Space After: {0} $FreespaceAfter"


