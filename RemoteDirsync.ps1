# This script allows us to initiate a forced DirSync from our local workstation. 
# It requires the -AdminName parameter is passed with the domain\username admin cred. 
# To run Dirsync (remotely or otherwise), the user needs to be part of the FIMAdmins of FimSyncAdmins group in AD.


param (
    [string]$AdminName = $(throw "-username is required.")
)


#Attributes
$DirsyncServer = "srv-stp-dc03.some_domain_name"  # FQDN of the Dirsync Server

$path = "C:\Users\$env:username\Documents\WindowsPowerShell\" # The Folder to store the credentials (with the trailing \)
$CredsFile = $path + "YMPowershellCreds.txt" # The file that will contain the securestring

#Check for Stored Credentials
if((Test-Path $path) -eq 0)
{
#First run: Create the path
    mkdir $path;
}

#checking to see if the credfile is present.
$FileExists = Test-Path $CredsFile
if  ($FileExists -eq $false) {
    Write-Host 'Credential file not found. Enter your password:' -ForegroundColor Yellow
    Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File $CredsFile
    $password = get-content $CredsFile | convertto-securestring
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName,$password}
else
    {Write-Host 'Using your stored credential file' -ForegroundColor Green
    $password = get-content $CredsFile | convertto-securestring
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName,$password}
# Initiate Remote Dirsync Command
Invoke-Command -credential $Cred1 -ComputerName $DirsyncServer -ScriptBlock { Import-Module DirSync; Start-OnlineCoexistenceSync }
