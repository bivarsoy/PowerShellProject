#
# Name: BackupADLDSInstanceDb.ps1
# 
# Derived from Create_IFM_Dump.ps1 by Author: Tony Murray, Version: 1.0, Date: 20/04/2009
# Comment: PowerShell script to create AD LDS IFM backup. To be run nightly as a scheduled task.
#

# Declare command line arguments
param(
    [string]$ADLDSInstance = "ADLDSInstanceName",
    [string]$IFMDir = "BackupPath",
    [string]$KeepMaxDays = "15"
)

# Declare variables
$IFMName = "adamntds.dit"
$ArchiveDir = "Archive"
$cmd = $env:SystemRoot + "\system32\dsdbutil.exe"
$flags = "`"ac i $ADLDSInstance`" ifm `"create full $IFMDir\$ADLDSInstance`" q q"
$date = get-Date -f "yyyyMMdd"
$backupfile = $date + "_adamntds.dit"
$DumpIFM = "{0} {1}" -f $cmd,$Flags
$ArchiveLimit = (Get-Date).AddDays(-$KeepMaxDays)

############
# Start Main

# If any of the variables still have their default values they have not been overridden by the caller
if ($ADLDSInstance -eq "ADLDSInstanceName" -or $IFMDir -eq "BackupPath")
{
write-host "One or more arguments are missing"
write-host "Syntax is"
write-host "BackupADLDSInstanceDB.ps1 -$ADLDSInstance -$IFMDir eg. C:\Backup\ADLDS> -KeepMaxDays i.e. default is 15 days"
exit 1
}

# Create the folder if it doesn’t exist 
if(test-path -path $IFMDir)
{
write-host "The folder $IFMDir already exists"

  if(test-path -path $IFMDir\$ArchiveDir)
  {
  $limit = (Get-Date).AddDays(-$KeepMaxDays)
  # Delete files older than the $limit.
  Get-ChildItem -Path $IFMDir\$ArchiveDir -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force

  # Assupmtion here is one file per day (file name unique per yyyymmdd
  Move-Item $IFMDir\$ADLDSInstance\* $IFMDir\$ArchiveDir
  }

}
else
{
New-Item $IFMDir -type directory
New-Item $IFMDir\$ArchiveDir -type directory
}
    
# Clear the IFM folder (Dsdbutil needs folder to be empty before writing to it) 
if(test-path -path $IFMDir\$ADLDSInstance)
{
Remove-Item $IFMDir\$ADLDSInstance\*
}

# Run Dsdbutil.exe to create the IFM dump file 
Invoke-expression $DumpIFM

# Rename the dump file to give the backup a unique name
rename-item $IFMDir\$ADLDSInstance\$IFMName -newname $backupfile
"C:\Backup\ADLDS\Kollsys-Test\adamntds.dit"

# End Main
##########