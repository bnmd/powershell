<#
.SYNOPSIS
	Get bits service status 
.DESCRIPTION
    Run in MCM tool
.EXAMPLE
.LINK
	https://github.com/bnmd
.NOTES
	Timeout: 1800
	Author: BYG | License: BYG
	Last update: 2019-06-13
	Status: Tested / Not Tested / Failed
#>

get-service bits | select name,status, starttype
get-service branchcache | select name,status, starttype