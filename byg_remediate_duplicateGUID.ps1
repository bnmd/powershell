<#
.SYNOPSIS
	Remediate_duplicateGUID
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

#   Arret agent sccm
get-service |where{$_.name -eq 'CcmExec'}|Stop-Service -Force

if((get-service |where{$_.name -eq 'CcmExec'}).Status -eq 'Stopped'){write-host "agent sccm arreté"}
#   Suppression smscfg.ini
Get-ChildItem -Path 'C:\Windows'|where{ $_.name -eq 'SMSCFG.INI'}|Remove-Item
#   suppression des certificats
$certSMS = Get-ChildItem -Path Cert:\LocalMachine\SMS -Recurse
foreach ($cert in $certSMS){
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store SMS,localmachine
    $store.Open('ReadWrite')
    $store.Remove($cert)
    $store.Close()
    }
#   restart de l'agent sccm
get-service |where{$_.name -eq 'CcmExec'}|Start-Service
if((get-service |where{$_.name -eq 'CcmExec'}).Status -eq 'Started'){write-output "agent sccm redémarré"}