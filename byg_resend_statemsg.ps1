<#
.SYNOPSIS
	Resend statemsg
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

$UpdatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore
$UpdatesStore.RefreshServerComplianceState()