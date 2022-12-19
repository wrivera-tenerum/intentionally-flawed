param (
    [string]$vcenter = 10.0.0.255
)


Add-PSSnapin VMware.VimAutomation.Core

#connect to vCenter
Connect-VIServer -server $vcenter -ErrorAction SilentlyContinue
clear

Write-Host "Deleting previously created temp files."
Remove-Item c:\users\temp2.csv -force -ErrorAction SilentlyContinue
Remove-Item c:\users\temp1.csv -force -ErrorAction SilentlyContinue
Remove-Item c:\users\temp.csv -force -ErrorAction SilentlyContinue


Write-host ""
Write-Host "-------------------------------------------------"
Write-Host "Collecting Storage Data from Hosts"
Write-Host "-------------------------------------------------"
Write-host ""

Write-Host "Getting List of hosts from vCenter."
$VMHostList = Get-VMHost


foreach ($hostentry in $VMHostList)
{
    $DiskStats = Get-Stat -Stat (
    "disk.commandsAveraged.average",
    "disk.numberReadAveraged.average",
    "disk.numberWriteAveraged.average",
    "disk.totalLatency.average",
    "disk.totalReadLatency.average",
    "disk.totalWriteLatency.average",
    "disk.usage.average",
    "disk.read.average",
    "disk.write.average",
    "disk.totalLatency.average",
    "disk.kernelLatency.average",
    "disk.queueLatency.average",
    "disk.deviceLatency.average"
    ) -Entity $hostentry -Realtime -MaxSamples 1 -instance naa.* | export-csv C:\users\temp.csv -Append
    

    

    $DiskList = Get-VMHost -Name $hostentry | Get-Datastore | Where-Object {$_.ExtensionData.Info.GetType().Name -eq "VmfsDatastoreInfo"} |
    ForEach-Object {
        if ($_)
        {
	        $Datastore = $_
	        $Datastore.ExtensionData.Info.Vmfs.Extent | Select-Object -Property @{Name="Name";Expression={$Datastore.Name}}, DiskName | Export-csv c:\users\temp1.csv -Append
        }
 
    } 
    
    Write-Host "Storage stats collected from $hostentry."

}

Write-host "Finished Collecting Host Storage Data."

Write-host ""
Write-Host "-------------------------------------------------"
Write-host "Cleaning Up Host Storage Data"
Write-Host "-------------------------------------------------"
Write-host ""

#importing temp CSVs.
$DiskStats1 = Import-csv C:\users\temp.csv
$DiskList1  = Import-csv C:\users\temp1.csv




#New array for cleaned up data.
$NewStorageData = @()

#loop through all the stats collected from each host.
foreach ($DiskStatEntry in $DiskStats1) {
    
    #Set the NewDiskName variable in the event that it isn't matched to a human readable name below.
    $NewDiskName = $DiskStatEntry.Instance

    #find the matching plaintext name for this LUN ID.
    foreach ($DiskListEntry in $DiskList1) {
        if($DiskListEntry.DiskName -match $DiskStatEntry.Instance)
        {
            #If there is a match, define the NewDiskName variable as the plaintext name.
            $NewDiskName = $DiskListEntry.Name
            
        }
      
    }

    #Defining additional variables for the row entry in the CSV.
    $Metric= $DiskStatEntry.MetricID
    $Unit=$DiskStatEntry.Unit
    $MetricValue=$DiskStatEntry.Value
    $VMHHost=$DiskStatEntry.Entity
    $Description=$DiskStatEntry.Description
    $TimeStamp=$DiskStatEntry.Timestamp



    if($NewDiskName -like "naa.*" -and $MetricValue -eq 0)
    {
        #This is an old metric for a LUN no longer attached to the host which is why it can't match its ID to a name. So we're going to exclude it to not let it skew our stats.

    }
    else{
        #Creating the entry in the table.
        $NewEntry = New-Object System.Object
        $NewEntry | Add-Member -MemberType NoteProperty -Name "LUN" -Value $NewDiskName
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Metric" -Value $Metric
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Unit" -Value $Unit
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Value" -Value $MetricValue
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Host" -Value $VMHHost
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Description" -Value $Description
        $NewEntry | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $TimeStamp

        #Appending the entry to the table.
        $NewStorageData += $NewEntry

    }

    

}
#Exporting to CSV
write-host ""
Write-Host "-------------------------------------------------"
Write-host "Exporting Host Storage Stats to CSV"
Write-Host "-------------------------------------------------"
Write-host ""
$CurrentDate = $(get-date -f yyyy-MM-dd)

$NewStorageData | Export-Csv -NoTypeInformation -path c:\users\Host-diskstats-$CurrentDate.csv
write-host "Data exported to c:\users\Host-diskstats-$CurrentDate.csv."



$HostStorageCompiled = Import-Csv -path c:\users\Host-diskstats-$CurrentDate.csv



Write-Host "Getting List of VMs from vCenter."
$VMtList = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}
Write-host ""
Write-Host "-------------------------------------------------"
Write-Host "Collecting Storage Data from VMs"
Write-Host "-------------------------------------------------"
Write-host ""

foreach ($VMentry in $VMtList1)
{
    $DiskStats = Get-Stat -Stat (
    "disk.read.average",
    "disk.write.average",
    "disk.usage.average",
    "disk.numberReadAveraged.average",
    "disk.numberWriteAveraged.average",
    "disk.commandsAveraged.average",
    "disk.maxTotalLatency.latest"
    ) -Entity $VMentry -Realtime -MaxSamples 1 | export-csv C:\users\temp2.csv -Append -ErrorAction SilentlyContinue
    

    
    
    Write-Host "Storage stats collected from $VMentry."

}

Write-host "Finished Collecting Storage Data from VMs."

Write-host ""
Write-Host "-------------------------------------------------"
Write-host "Cleaning Up VM Storage Data"
Write-Host "-------------------------------------------------"
Write-host ""

Write-Host "Please be patient, this will take a while. Go grab some coffee."
Write-Host ""
Write-Host ""
Write-Host "Like seriously... a really long time. You're going to think it isn't doing anything. Just keep waiting."
$DiskStats2 = Import-csv C:\users\temp2.csv


#New array for cleaned up data.
$NewVMStorageData = @()

$FinishedEntry = ""


#loop through all the stats collected from each host.
foreach ($DiskStatEntry in $DiskStats2) {
    
    #Set the NewDiskName variable in the event that it isn't matched to a human readable name below.
    $NewDiskName = $DiskStatEntry.Instance

    #find the matching plaintext name for this LUN ID.
    foreach ($DiskListEntry in $DiskList1) {
        if($DiskListEntry.DiskName -match $DiskStatEntry.Instance)
        {
            #If there is a match, define the NewDiskName variable as the plaintext name.
            $NewDiskName = $DiskListEntry.Name
            
        }
      
    }

    #Defining additional variables for the row entry in the CSV.
    $Metric= $DiskStatEntry.MetricID
    $Unit=$DiskStatEntry.Unit
    $MetricValue=$DiskStatEntry.Value
    $VMachine=$DiskStatEntry.Entity
    $Description=$DiskStatEntry.Description
    $TimeStamp=$DiskStatEntry.Timestamp



    if($NewDiskName -like "naa.*" -and $MetricValue -eq 0)
    {
       
    }
    else{
        #Creating the entry in the table.
        $NewEntry = New-Object System.Object
        $NewEntry | Add-Member -MemberType NoteProperty -Name "VM" -Value $VMachine
        $NewEntry | Add-Member -MemberType NoteProperty -Name "LUN" -Value $NewDiskName
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Metric" -Value $Metric
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Unit" -Value $Unit
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Value" -Value $MetricValue
        $NewEntry | Add-Member -MemberType NoteProperty -Name "Description" -Value $Description
        $NewEntry | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $TimeStamp

        #Appending the entry to the table.
        $NewVMStorageData += $NewEntry

    }



    If($FinishedEntry -eq $VMachine -Or $FinishedEntry -eq "")
    {
        #If the variable FinishedEntry equal the recently defined vMachine variable or is blank, then that means tis is another metric of the same VM, and it isn't finished, so we do nothing.
    }
    else
    {
        #If it doesn't match, then we indicate that it's finished, and redefine the variable for the next entry in the loop.
        Write-host "Collection of storage data for $FinishedEntry finished."
        $FinishedEntry = $VMachine
        
    }

    

}
#Exporting to CSV
write-host ""
Write-Host "-------------------------------------------------"
Write-host "Exporting VM Storage Stats to CSV"
Write-Host "-------------------------------------------------"
Write-host ""
$CurrentDate = $(get-date -f yyyy-MM-dd)

$NewVMStorageData | Export-Csv -NoTypeInformation -path c:\users\VM-diskstats-$CurrentDate.csv
write-host "Data exported to c:\users\VM-diskstats-$CurrentDate.csv."



$VMStorageCompiled = Import-Csv -path c:\users\VM-diskstats-$CurrentDate.csv

