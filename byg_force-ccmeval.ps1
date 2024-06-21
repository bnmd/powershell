<#
.SYNOPSIS
	Force CCM Eval
.DESCRIPTION
	Code to set 'SendAlways' in registry
    Run in MCM tool
.EXAMPLE
.LINK
	https://github.com/bnmd
.NOTES
	Timeout: 1800
	Author: BYG | License: BYG
	Last update: 2019-07-24
	Status: Tested / Not Tested / Failed
	From https://smsagent.blog/tag/client-check-result-no-results/
#>

$SendAlways = {
    Param($Value)
    $Path = "HKLM:\Software\Microsoft\CCM\CcmEval"
 
    Try
    {
        $null = New-ItemProperty -Path $Path -Name 'SendAlways' -Value $Value -Force -ErrorAction Stop
    }
    Catch
    {
        $_
    }
}
 
# Run against local computer

    If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning "This cmdlet must be run as administrator against the local machine!"
        Return
    }
 
    Write-Verbose "Enabling 'SendAlways' in registry"
    $Result = Invoke-Command -ArgumentList "TRUE" -ScriptBlock $SendAlways
 
    If (!$Result.Exception)
    {
        Write-Verbose "Triggering CM Health Evaluation task"
        Invoke-Command -ScriptBlock { schtasks /Run /TN "Microsoft\Configuration Manager\Configuration Manager Health Evaluation" /I }
 
        Write-Verbose "Waiting for ccmeval to finish"
        do {} while (Get-process -Name ccmeval -ErrorAction SilentlyContinue)
 
        Write-Verbose "Disabling 'SendAlways' in registry"
        Invoke-Command -ArgumentList "FALSE" -ScriptBlock $SendAlways
    }
    Else
    {
        Write-Error $($Result.Exception.Message)
    }
