<#
.SYNOPSIS
	SCCM Client Health Check and Tshoot 
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
        [string]$PathLog = "C:\Log\CheckClientSCCMetWMI.log"
    )
    Begin
    {
                              
    }
    Process
    {

        If (!(Test-Path $PathLog))
        {
            $LogPath = New-Item -Path $PathLog -ItemType File -Force
        }

        If ((Get-ItemProperty $PathLog).length -gt 5000000)
        { 
            Copy-Item "C:\Log\CheckClientSCCMetWMI.log" "C:\Log\CheckClientSCCMetWMI.log" -force 
            New-Item -path "C:\Log\CheckClientSCCMetWMI.log" -type file -force 
        }

        $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Verbose $Message
        "$date $Message" | Out-File -FilePath $PathLog -Append
    }
    End
    {
    }
}

############### Fill the details ##########################################
$path = "C:\Windows\ccmsetup"
$mp_address = "bcnssrv150.bouygues-construction.com"
$site_code = "PAP"

############################### Main Code ####################################
$machinename = hostname
$SMSCli = [wmiclass] "root\ccm:sms_client"

############################### Check if WMI is working #######################
if((Get-WmiObject -Namespace root\ccm -Class SMS_Client) -and (Get-WmiObject -Namespace root\ccm -Class SMS_Client))
{
	$WMI_Status = "Working"
	Write-Log "WMI Working"
}else
{
	Stop-Service -Force winmgmt -ErrorAction SilentlyContinue
   	cd  C:\Windows\System32\Wbem\
   	del C:\Windows\System32\Wbem\Repository.old -Force -ErrorAction SilentlyContinue
   	ren Repository Repository.old -ErrorAction SilentlyContinue
   	Start-Service winmgmt 
	Write-Log "Repair WMI"
}

############################# Check if SCCM Client is installed ##################
If(Get-Service -Name CcmExec)
{
	$Client_Status = "Yes"
	Write-Log "Client Installed"
	########### Check if services are running ################################
	$CcmExec_Status = Get-Service -Name CcmExec | %{$_.status}
	$BITS_Status = Get-Service -Name BITS | %{$_.status}
	$wuauserv_Status = Get-Service -Name wuauserv | %{$_.status}
	$Winmgmt_Status = Get-Service -Name Winmgmt | %{$_.status}
	$RRegistry_Status = Get-Service -Name RemoteRegistry | %{$_.status}


	if($CcmExec_Status -eq "Stopped")
	{
		Get-Service -Name CcmExec | Start-Service
		Write-Log "Start-Service CcmExec"

	}

	if($BITS_Status -eq "Stopped")
	{
		Get-Service -Name BITS | Start-Service
		Write-Log "Start-Service BITS"
	}

	if($wuauserv_Status -eq "Stopped")
	{
		Get-Service -Name wuauserv | Start-Service
		Write-Log "Start-Service Wuauserv"
	}

	if($Winmgmt_Status -eq "Stopped")
	{
		Get-Service -Name Winmgmt | Start-Service
		Write-Log "Start-Service Winmgmt"
	}

	
	
	$MachinePolicyRetrievalEvaluation = "{00000000-0000-0000-0000-000000000021}"
	$SoftwareUpdatesScan = "{00000000-0000-0000-0000-000000000113}"
	$SoftwareUpdatesDeployment = "{00000000-0000-0000-0000-000000000108}"

	#################### check if Scan cycles are working ###################
	$machine_status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $MachinePolicyRetrievalEvaluation
	$software_status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $SoftwareUpdatesScan
	$softwaredeploy_Status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $SoftwareUpdatesDeployment

	if($machine_status -and $software_status -and $softwaredeploy_Status)
	{
		$machine_Rstatus = "Successful"
		Write-Log "SCCM Client Successful"
	}else
	{
		$repair = $SMSCli.RepairClient()
		Write-Log "Repair SCCM Client"
	}

}else
{
	############## Install SCCM Client ###############################
	C:\Windows\ccmsetup\ccmsetup.exe /mp:$mp_address SMSSITECODE=$site_code
	Write-Log "Install Client SCCM"	
}


####################################################################################################
