##環境設定
$ScriptWorkDir="c:\iij\work"
$ProxyAddr="http://proxy.iiji.jp:8080"
$ansibleServer="192.168.188.10"

# $Start_Service_Name = "WinRM"
# $Start_Service_Nameの起動チェック (※Ansibleのスクリプトに同梱されている)
#if (-not((Get-Service |?{$_.name -match $Start_Service_Name}|%{$_.Status}) -match "Running" )) {
#    Start-Service –Name $Start_Service_Name –PassThru
#    Write-Host "WinRM Service Start " 
#}
# $ScriptWorkDirの存在チェック
if (-not(test-path (split-path $ScriptWorkDir -parent) )) { 
    new-item (split-path $ScriptWorkDir -parent) -type directory |out-null
    Write-Host "ディレクトリ : "(split-path $ScriptWorkDir -parent)"を作成しました"
}
if (-not(test-path $ScriptWorkDir )) {
    new-item  $ScriptWorkDir -type directory | out-null
    Write-Host "ディレクトリ : $ScriptWorkDir を作成しました"
}
#Ansible 初期設定powershellダウンロード&実行
Invoke-WebRequest -Proxy $ProxyAddr -Uri https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -OutFile $(join-path $ScriptWorkDir "ConfigureRemotingForAnsible.ps1")

Write-Host  "Ansible 初期設定用 powershell を実行します。"
powershell -ExecutionPolicy RemoteSigned -File $(join-path $ScriptWorkDir "ConfigureRemotingForAnsible.ps1")

# Windows Firewall  WinRM用Portが開放されているかチェック
if (-not((Get-Item WSMan:\localhost\Listener\*\Port |% {$_.Value}) -contains "5985")) {Write-Host "Windows FirewallでTCP/5985が開放されていません。"}
if (-not((Get-Item WSMan:\localhost\Listener\*\Port |% {$_.Value}) -contains "5986")) {Write-Host "Windows FirewallでTCP/5986が開放されていません。"}

# WinRM Trusted Hostの登録
if (-not((Get-Item wsman:\localhost\Client\TrustedHosts | % {$_.Value}) -eq $null)) {
    $ansibleServer+=","+(Get-Item wsman:\localhost\Client\TrustedHosts | % {$_.Value})
    Write-Host "現在登録されているTrustedHostsに $ansibleServer を追加します。"
}
Set-Item wsman:\localhost\Client\TrustedHosts -Value $ansibleServer -Force
Write-Host "現在登録されているWinRM TrustedHostsは "(Get-Item wsman:\localhost\Client\TrustedHosts | % {$_.Value})" です。"
