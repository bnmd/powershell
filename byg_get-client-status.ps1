<#
.SYNOPSIS
	Force resend install client status
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

$path = (Get-WmiObject -ComputerName $env:computername -namespace root\ccm\statemsg -class ccm_statemsg -filter "topictype=800").__path
set-wmiinstance -path $path -argument @{MessageSent="False"}