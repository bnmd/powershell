<#
.SYNOPSIS
	CleanCCmCache 
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

##*=============================================
##* INITIALIZATION
##*=============================================
#region Initialization

## Cleaning prompt history
CLS

## Global variables
$Global:Result  =@()
$Global:ExclusionList  =@()

## Initialize progress Counter
$ProgressCounter = 0

## Configure Logging
#  Set log path
$ResultCSV = 'C:\LOG\Clean-CMClientCache.log'

#  Remove previous log it it's more than 500 KB
If (Test-Path $ResultCSV) {
    If ((Get-Item $ResultCSV).Length -gt 500KB) {
        Remove-Item $ResultCSV -Force | Out-Null
    }
}

#  Get log parent path
[String]$ResultPath =  Split-Path $ResultCSV -Parent

#  Create path directory if it does not exist
If ((Test-Path $ResultPath) -eq $False) {
    New-Item -Path $ResultPath -Type Directory | Out-Null
}

## Get the current date
$Date = Get-Date

#endregion
##*=============================================
##* END INITIALIZATION
##*=============================================

##*=============================================
##* FUNCTION LISTINGS
##*=============================================
#region FunctionListings

#region Function Write-Log
Function Write-Log {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false,Position=0)]
        [Alias('Name')]
        [string]$EventLogName = 'Configuration Manager',
        [Parameter(Mandatory=$false,Position=1)]
        [Alias('Source')]
        [string]$EventLogEntrySource = 'Clean-CMClientCache',
        [Parameter(Mandatory=$false,Position=2)]
        [Alias('ID')]
        [int32]$EventLogEntryID = 1,
        [Parameter(Mandatory=$false,Position=3)]
        [Alias('Type')]
        [string]$EventLogEntryType = 'Information',
        [Parameter(Mandatory=$true,Position=4)]
        [Alias('Message')]
        $EventLogEntryMessage
    )

    ## Initialize log
    If (([System.Diagnostics.EventLog]::Exists($EventLogName) -eq $false) -or ([System.Diagnostics.EventLog]::SourceExists($EventLogEntrySource) -eq $false )) {

        #  Create new log and/or source
        New-EventLog -LogName $EventLogName -Source $EventLogEntrySource

    ## Write to log and console
    }

    #  Convert the Result to string and Write it to the EventLog
    $ResultString = Out-String -InputObject $Result -Width 1000
    Write-EventLog -LogName $EventLogName -Source $EventLogEntrySource -EventId $EventLogEntryID -EntryType $EventLogEntryType -Message $ResultString

    #  Write Result Object to csv file (append)
    $EventLogEntryMessage | Export-Csv -Path $ResultCSV -Delimiter ';' -Encoding UTF8 -NoTypeInformation -Append -Force

    #  Write Result to console
    $EventLogEntryMessage | Format-Table Name,TotalDeleted`(MB`)

}
#endregion


#region Function Remove-CacheItem
Function Remove-CacheItem {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('CacheTD')]
        [string]$CacheItemToDelete,
        [Parameter(Mandatory=$true,Position=1)]
        [Alias('CacheN')]
        [string]$CacheItemName
    )

    ## Delete cache item if it's non persisted
    If ($CacheItems.ContentID -contains $CacheItemToDelete) {

        #  Get Cache item location and size
        $CacheItemLocation = $CacheItems | Where {$_.ContentID -Contains $CacheItemToDelete} | Select -ExpandProperty Location
        $CacheItemSize =  Get-ChildItem $CacheItemLocation -Recurse -Force | Measure-Object -Property Length -Sum | Select -ExpandProperty Sum

        #  Check if cache item is downloaded by looking at the size
        If ($CacheItemSize -gt '0.00') {

            #  Connect to resource manager COM object
            $CMObject = New-Object -ComObject 'UIResource.UIResourceMgr'

            #  Using GetCacheInfo method to return cache properties
            $CMCacheObjects = $CMObject.GetCacheInfo()

            #  Delete Cache item
            $CMCacheObjects.GetCacheElements() | Where-Object {$_.ContentID -eq $CacheItemToDelete} |
                ForEach-Object {
                    $CMCacheObjects.DeleteCacheElement($_.CacheElementID)
                    Write-Host 'Deleted: '$CacheItemName -BackgroundColor Red
                }
            #  Build result object
            $ResultProps = [ordered]@{
                'Name' = $CacheItemName
                'ID' = $CacheItemToDelete
                'Location' = $CacheItemLocation
                'Size(MB)' = '{0:N2}' -f ($CacheItemSize / 1MB)
                'Status' = 'Deleted!'
            }

            #  Add items to result object
            $Global:Result  += New-Object PSObject -Property $ResultProps
        }
    }
    Else {
        Write-Host 'Already Deleted:'$CacheItemName '|| ID:'$CacheItemToDelete -BackgroundColor Green
    }
}
#endregion

#region Function Remove-CachedApplications
Function Remove-CachedApplications {

    ## Get list of applications
    Try {
        $CM_Applications = Get-WmiObject -Namespace root\ccm\ClientSDK -Query 'SELECT * FROM CCM_Application' -ErrorAction Stop
    }
    #  Write to log in case of failure
    Catch {
        Write-Host 'Get SCCM Application List from WMI - Failed!'
    }

    ## Check for installed applications
    Foreach ($Application in $CM_Applications) {

        ## Show progress bar
        If ($CM_Applications.Count -ne $null) {
            $ProgressCounter++
            Write-Progress -Activity 'Processing Applications' -CurrentOperation $Application.FullName -PercentComplete (($ProgressCounter / $CM_Applications.Count) * 100)
        }
        ## Get Application Properties
        $Application.Get()

        ## Enumerate all deployment types for an application
        Foreach ($DeploymentType in $Application.AppDTs) {

            ## Get content ID for specific application deployment type
            $AppType = 'Install',$DeploymentType.Id,$DeploymentType.Revision
            $AppContent = Invoke-WmiMethod -Namespace root\ccm\cimodels -Class CCM_AppDeliveryType -Name GetContentInfo -ArgumentList $AppType

            If ($Application.InstallState -eq 'Installed' -and $Application.IsMachineTarget -and $AppContent.ContentID) {

                ## Call Remove-CacheItem function
                Remove-CacheItem -CacheTD $AppContent.ContentID -CacheN $Application.FullName
            }
            Else {
                ## Add to exclusion list
                $Global:ExclusionList += $AppContent.ContentID
            }
        }
    }
}
#endregion

#region Function Remove-CachedPackages
Function Remove-CachedPackages {
    ## Get list of packages
    Try {
        $CM_Packages = Get-WmiObject -Namespace root\ccm\ClientSDK -Query 'SELECT PackageID,PackageName,LastRunStatus,RepeatRunBehavior FROM CCM_Program' -ErrorAction Stop
    }
    #  Write to log in case of failure
    Catch {
        Write-Host 'Get SCCM Package List from WMI - Failed!'
    }

    ## Check if any deployed programs in the package need the cached package and add deletion or exemption list for comparison
    ForEach ($Program in $CM_Packages) {

        #  Check if program in the package needs the cached package
        If ($Program.LastRunStatus -eq 'Succeeded' -and $Program.RepeatRunBehavior -ne 'RerunAlways' -and $Program.RepeatRunBehavior -ne 'RerunIfSuccess') {

            #  Add PackageID to Deletion List if not already added
            If ($Program.PackageID -NotIn $PackageIDDeleteTrue) {
                [Array]$PackageIDDeleteTrue += $Program.PackageID
            }

        }
        Else {

            #  Add PackageID to Exemption List if not already added
            If ($Program.PackageID -NotIn $PackageIDDeleteFalse) {
                [Array]$PackageIDDeleteFalse += $Program.PackageID
            }
        }
    }

    ## Parse Deletion List and Remove Package if not in Exemption List
    ForEach ($Package in $PackageIDDeleteTrue) {

        #  Show progress bar
        If ($CM_Packages.Count -ne $null) {
            $ProgressCounter++
            Write-Progress -Activity 'Processing Packages' -CurrentOperation $Package.PackageName -PercentComplete (($ProgressCounter / $CM_Packages.Count) * 100)
            Start-Sleep -Milliseconds 800
        }
        #  Call Remove Function if Package is not in $PackageIDDeleteFalse
        If ($Package -NotIn $PackageIDDeleteFalse) {
            Remove-CacheItem -CacheTD $Package.PackageID -CacheN $Package.PackageName
        }
        Else {
            ## Add to exclusion list
            $Global:ExclusionList += $Package.PackageID
        }
    }
}
#endregion

#region Function Remove-CachedUpdates
Function Remove-CachedUpdates {
    ## Get list of updates
    Try {
        $CM_Updates = Get-WmiObject -Namespace root\ccm\SoftwareUpdates\UpdatesStore -Query 'SELECT UniqueID,Title,Status FROM CCM_UpdateStatus' -ErrorAction Stop
    }
    #  Write to log in case of failure
    Catch {
        Write-Host 'Get SCCM Software Update List from WMI - Failed!'
    }

    ## Check if cached updates are not needed and delete them
    ForEach ($Update in $CM_Updates) {

        #  Show Progress bar
        If ($CM_Updates.Count -ne $null) {
            $ProgressCounter++
            Write-Progress -Activity 'Processing Updates' -CurrentOperation $Update.Title -PercentComplete (($ProgressCounter / $CM_Updates.Count) * 100)
        }

        #  Check if update is already installed
        If ($Update.Status -eq 'Installed') {

            #  Call Remove-CacheItem function
            Remove-CacheItem -CacheTD $Update.UniqueID -CacheN $Update.Title
        }
        Else {
            ## Add to exclusion list
            $Global:ExclusionList += $Update.UniqueID
        }
    }
}
#endregion

#region Function Remove-OrphanedCacheItems
Function Remove-OrphanedCacheItems {
    ## Check if cached updates are not needed and delete them
    ForEach ($CacheItem in $CacheItems) {

        #  Show Progress bar
        If ($CacheItems.Count -ne $null) {
            $ProgressCounter++
            Write-Progress -Activity 'Processing Orphaned Cache Items' -CurrentOperation $CacheItem.ContentID -PercentComplete (($ProgressCounter / $CacheItems.Count) * 100)
        }

        #  Check if update is already installed
        If ($Global:ExclusionList -notcontains $CacheItem.ContentID) {

            #  Call Remove-CacheItem function
            Remove-CacheItem -CacheTD $CacheItem.ContentID -CacheN 'Orphaned Cache Item'
        }
    }
}
#endregion

#endregion
##*=============================================
##* END FUNCTION LISTINGS
##*=============================================

##*=============================================
##* SCRIPT BODY
##*=============================================
#region ScriptBody

## Get list of all non persisted content in CCMCache, only this content will be removed
Try {
    $CacheItems = Get-WmiObject -Namespace root\ccm\SoftMgmtAgent -Query 'SELECT ContentID,Location FROM CacheInfoEx WHERE PersistInCache != 1' -ErrorAction Stop
}
#  Write to log in case of failure
Catch {
    Write-Host 'Getting SCCM Cache Info from WMI - Failed! Check if SCCM Client is Installed!'
}

## Call Remove-CachedApplications function
Remove-CachedApplications

## Call Remove-CachedApplications function
Remove-CachedPackages

## Call Remove-CachedApplications function
Remove-CachedUpdates

## Call Remove-OrphanedCacheItems function
Remove-OrphanedCacheItems

## Get Result sort it and build Result Object
$Result =  $Global:Result | Sort-Object Size`(MB`) -Descending

#  Calculate total deleted size
$TotalDeletedSize = $Result | Measure-Object -Property Size`(MB`) -Sum | Select -ExpandProperty Sum

#  If $TotalDeletedSize is zero write that nothing could be deleted
If ($TotalDeletedSize -eq $null -or $TotalDeletedSize -eq '0.00') {
    $TotalDeletedSize = 'Nothing to Delete!'
}
Else {
    $TotalDeletedSize = '{0:N2}' -f $TotalDeletedSize
    }

#  Build Result Object
$ResultProps = [ordered]@{
    'Name' = 'Total Size of Items Deleted in MB: '+$TotalDeletedSize
    'ID' = 'N/A'
    'Location' = 'N/A'
    'Size(MB)' = 'N/A'
    'Status' = ' ***** Last Run Date: '+$Date+' *****'
}

#  Add total items deleted to result object
$Result += New-Object PSObject -Property $ResultProps

## Write to log and console
Write-Log -Message $Result

## Let the user know we are finished
Write-Host 'Processing Finished!' -BackgroundColor Green -ForegroundColor White

Remove-Item -Path "$env:windir\ccmcache\*" -Force -Recurse -ErrorAction SilentlyContinue

#endregion
##*=============================================
##* END SCRIPT BODY
##*=============================================