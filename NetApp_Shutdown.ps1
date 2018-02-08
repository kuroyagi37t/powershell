Import-Module .\SSH-Sessions
#Import the PowerCLI module

## 環境変数
[string]$SSH_user= "poweradmin"                             ### NetApp Login ID
[string]$SSH_pass= ""                                       ### NetApp Login Password
[string]$SSH_key= "sshkey\cccvm1.pem"                       ### NetApp Login RSA Key File
[string]$SSH_Server = "133.101.89.41"                       ### NetApp (SP) Host IP
[string]$ssh_port= "22"                                     ### NetApp SSH Port  
[string]$ssh_cmd= "system node halt -node * -f true"        ### NetApp Cluster Shutdown CMD 

$timestamp=$(Get-Date -Format "yyyyMMdd-HHmmss")
[string]$CR="`n"
[string]$CRLF="`r`n"

# 詳細ログファイルパス
if(!$LogFile){ [string]$global:LogFile = "./Logs/ScriptLog_"+$(Get-Date -Format "yyyyMMdd-HHmmss")+".log" }
# イベントログソース名
if(!$EvevtSource){ [string]$global:EvevtSource = "IIJ_SCRIPT NetApp Shutdown"}

#-----------------------------------------------
# Logメソッド
# エラーメッセージログ吐き出し用メソッド
Function Message-ErrorLogFile ([String]$Message = ""){
    if($Message -ne ""){
        "Time : $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")" | Out-File -encoding UTF8 -FilePath $LogFile -Append
        "ErrorMessage : $($Message)" | Out-File -encoding UTF8 -FilePath $LogFile -Append
        Write-Host $Message
    }
    $Error | Out-File -encoding UTF8 -FilePath $LogFile -Append
    $Error.Clear()
}
# インフォメッセージログ吐き出し用メソッド
Function Message-LogFile ([String]$Message = ""){
    if($Message -ne ""){
        "Time : $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")" | Out-File -encoding UTF8 -FilePath $LogFile -Append
        "InfoMessage : $($Message)" | Out-File -encoding UTF8 -FilePath $LogFile -Append
    }
}
# メッセージボックスポップアップ用メソッド
Function Message-Popup ([String]$Message = "",[String]$Title = "ScriptMessage"){
    Add-Type -Assembly System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title)
}

# イベントログ発行用メソッド
Function Message-EventLog ([String]$Message,[String]$Type = "Information", [int]$ID = 0, [String]$Source = $EvevtSource){
    if ([System.Diagnostics.EventLog]::SourceExists($Source) -eq $false){
        New-EventLog -LogName Application -Source $Source
    }
    Write-EventLog -LogName Application -EntryType $Type -Source $Source -EventId $ID -Message $Message
}


Function Stop-NetApp-Cluster {
    Begin {
        $RT=New-SshSession -ComputerName $SSH_Server -Username $SSH_User -KeyFile $SSH_Key -Port $SSH_Port
        Message-LogFile $RT.replace($CR,$CRLF)
    }
	Process	{
        Try {
            $RT=Invoke-SSHCommand  -ComputerName $SSH_Server -Command $ssh_cmd
            Message-LogFile $RT.replace($CR,$CRLF)
            Message-EventLog -Category "NetApp Cluster is shutdown" -Message $RT.replace($CR,$CRLF) -ID 1
        }
        Catch {
            Message-ErrorLogFile $RT.replace($CR,$CRLF)
        }
    }
    End {
        $RT=Remove-SshSession -ComputerName $SSH_Server
        Message-LogFile $RT.replace($CR,$CRLF)
    }
}

Stop-NetApp-Cluster

exit
