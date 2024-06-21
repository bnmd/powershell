<#
.SYNOPSIS
	reinstall client sccm on preprod 
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

C:\Windows\ccmsetup\ccmsetup.exe /forceinstall /mp:https://x920.bygcc.com SITECODE=PPS FSP=BCNVSRV675 SMSMP=https://x920.bygcc.com