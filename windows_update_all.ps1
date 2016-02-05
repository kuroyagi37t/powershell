$ErrorActionPreference = "Stop"
 
$AutoRestart = $true
$AutoRestartIfPending = $true
$LogPath = Split-Path $MyInvocation.MyCommand.Path  -Parent
$LogFile = "WindowsUpdateShell.log"
 
function Write-WindowsUpdateLog ($Message)
{
    $Output = "{0} {1}" -f (Get-Date), $Message
    Write-Output $Output
    $output | Out-File (Join-Path $LogPath -ChildPath $LogFile) -Append -Encoding utf8
}

try
{
    Write-WindowsUpdateLog "Checking for available updates Start"
    #Checking for available updates 
    $updateSession = new-object -com "Microsoft.Update.Session"
    $criteria="IsInstalled=0 and Type='Software' and BrowseOnly = 0" 
    $updates=$updateSession.CreateupdateSearcher().Search($criteria).Updates 
    $downloader = $updateSession.CreateUpdateDownloader()           
    $downloader.Updates = $Updates
    Write-WindowsUpdateLog "Checking for available updates End"
 
  
    #If no updates available, do nothing 
    if ($downloader.Updates.Count -ne "0") { 
        #If updates are available, download and install 
        Write-WindowsUpdateLog "Downloading $($downloader.Updates.count) updates"  
  
        $resultcode= @{0="Not Started"; 1="In Progress"; 2="Succeeded"; 3="Succeeded With Errors"; 4="Failed" ; 5="Aborted" } 
        $Result= $downloader.Download() 
  
        if (($Result.Hresult -eq 0) -and (($result.resultCode -eq 2) -or ($result.resultCode -eq 3)) ) { 
            $updatesToInstall = New-object -com "Microsoft.Update.UpdateColl"
            foreach ($Update in $Updates | where {$_.isdownloaded} ){
                $updatesToInstall.Add($Update) | out-null
                Write-WindowsUpdateLog $Update.Title
            }
  
            $installer = $updateSession.CreateUpdateInstaller()        
            $installer.Updates = $updatesToInstall
            Write-WindowsUpdateLog "Update Install Start"     
            $installationResult = $installer.Install()
            Write-WindowsUpdateLog "Update Install End"     
   
            #Reboot if autorestart is enabled and one or more updates are requiring a reboot 
            if ($autoRestart -and $installationResult.rebootRequired) { 
                Write-WindowsUpdateLog "Status is Reboot Required. Reboot Start"
                Restart-Computer -Force
                Exit
            }        
        } 
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"){ 
        if ($AutoRestartIfPending) {
            Write-WindowsUpdateLog "Status is Auto Restart Pending. Reboot Start"
            Restart-Computer -Force
        }        
    }
}
catch
{
    Write-WindowsUpdateLog $_
    Write-WindowsUpdateLog "Windows Update Error"
}
