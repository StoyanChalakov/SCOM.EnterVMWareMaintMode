param (
    [Parameter(mandatory=$true)][string]$computername,
    [Parameter(mandatory=$false)][int]$hours=1,
    [Parameter(mandatory=$false)][string]$comment
 )

#Clear error cache, import SCOM PowerShell module
$error.clear()
Import-Module OperationsManager

#Calculate the end date of the maintenance mode. If no value is supplied during execution a default value of 1 hour will be used.
 $start = get-date
 $end = $start.addhours($hours)

# Get the class of the object, which needs to be set in MM and the object itself (both for System.Computer and Veeam Virtual Machines)
 $class = Get-SCOMClass -name System.Computer
 $veeamclass = Get-SCOMClass -name Veeam.Virt.Extensions.VMware.VMGUEST
 $object = Get-SCOMClassInstance -Class $class | where {$_.displayname -eq $computername}
 $veeamobject = Get-SCOMClassInstance -Class $veeamclass | where {$_.'[Veeam.Virt.Extensions.VMware.VMGUEST].guestHostName' -like "*$computername*"}

 # Check if the objects exist
if ((!$object) -and (!$veeamobject)) {
    $host.SetShouldExit(100)
    exit
}
else{

 if(($mmobject.inmaintenancemode -eq $false) -and ($veeamobject.inmaintenancemode -eq $false)) {
        Start-SCOMMaintenanceMode -Instance $object,$veeamobject -EndTime $end -Comment $comment
 }
 else{
    if (($object.inmaintenancemode -eq $true) -and ($veeamobject.inmaintenancemode -eq $false)) {
        Start-SCOMMaintenanceMode -Instance $veeamobject -EndTime $end -Comment $comment
    }
    elseif (($object.inmaintenancemode -eq $false) -and ($veeamobject.inmaintenancemode -eq $true)) {
        Start-SCOMMaintenanceMode -Instance $object -EndTime $end -Comment $comment
    }
    else {
        exit
    }
  }
}
