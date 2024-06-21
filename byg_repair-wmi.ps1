<#
.SYNOPSIS
	Repair WMI
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
        [string]$Path = "C:\Log\RepairWMI.log"
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
            Copy-Item "C:\Log\RepairWMI.log" "C:\Log\RepairWMI.log" -force 
            New-Item -path "C:\Log\RepairWMI.log" -type file -force 
        }

        $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Verbose $Message
        "$date $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}
Write-Log "Stopping ccmexec"
Stop-Service -Force ccmexec -ErrorAction SilentlyContinue
Write-Log "Stopping winmgt"
Stop-Service -Force winmgmt 
[String[]]$aWMIBinaries=@("unsecapp.exe","wmiadap.exe","wmiapsrv.exe","wmiprvse.exe","scrcons.exe")
foreach ($sWMIPath in @(($ENV:SystemRoot+"\System32\wbem"),($ENV:SystemRoot+"\SysWOW64\wbem"))){
    if(Test-Path -Path $sWMIPath){
        push-Location $sWMIPath
        foreach($sBin in $aWMIBinaries){
            if(Test-Path -Path $sBin){
                $oCurrentBin=Get-Item -Path  $sBin
                Write-Log " Register $sBin"
                & $oCurrentBin.FullName /RegServer
            }
            else{
                # Warning only for System32
                if($sWMIPath -eq $ENV:SystemRoot+"\System32\wbem"){
                    Write-Log "File $sBin not found!"
                }
            }
        }
        Pop-Location
    }
}
if([System.Environment]::OSVersion.Version.Major -eq 5) 
{
   foreach ($sWMIPath in @(($ENV:SystemRoot+"\System32\wbem"),($ENV:SystemRoot+"\SysWOW64\wbem"))){
   		if(Test-Path -Path $sWMIPath){
            push-Location $sWMIPath
            Write-Log " Register WMI Managed Objects"
            $aWMIManagedObjects=Get-ChildItem * -Include @("*.mof","*.mfl")
            foreach($sWMIObject in $aWMIManagedObjects){
                $oWMIObject=Get-Item -Path  $sWMIObject
                & mofcomp $oWMIObject.FullName				
            }
            Pop-Location
        }
   }
   if([System.Environment]::OSVersion.Version.Minor -eq 1)
   {
   		& rundll32 wbemupgd,UpgradeRepository
   }
   else{
   		& rundll32 wbemupgd,RepairWMISetup
   }
}
else{
    # Other Windows Vista, Server 2008 or greater
    Write-Log "Reset Repository"
    & ($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /resetrepository 
    & ($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /salvagerepository 
}
Write-Log "Starting winmgmt"
Start-Service winmgmt
Write-Log "Starting ccmexec"
Start-Service ccmexec -ErrorAction SilentlyContinue
