<# 
説明 : 本スクリプトは、csvからの情報を元に仮想マシンを作成するスクリプトである。
         とりあえず２台のvCenter上での実行を確認済み。
　　　複数のvCenterのシステムユーザ。パスワードは同一としている。
関数：
ChangeCPU <仮想マシン名> <変更後のCPUサイズ>
ChangeMem <仮想マシン名> <変更後のMemサイズ>
ChangeDisk <仮想マシン名> <変更後のDiskサイズ>
MakeMachine --- 仮想マシンを作成。
---------------------
　各種変数設定場所
#>
$LogFilename = Get-Date -Format "yyyy-MMdd-HHmmss"
$LogDir = "ログディレクトリを指定してね"
$Connect1StServer = "1台目のvCenter"
$Connect2ndServer = "2代目のvCenter"
$ConnectUser = "ログインユーザ名"
$ConnectPassword = "パスワード"
$Adminpas = "P@ssw0rd" 　　　　　#カスタマイズしたWindowsマシンのデフォルトパスワード。
$1stScript = "初期起動時に流したいスクリプトPATH"
 
$AdminFullName = "管理者の名前"　　　　 　#WindowsOS の管理者に入れる名前
$OrganizationName　= "管理者の組織名"　 #WindowsOS の組織に入れる名前
$PrimaryDNS = "" #プライマリDNS
$SecondaryDNS = "" #セカンダリDNS
$TimeZone　= "Tokyo" #タイムセット
$WorkGroup　= "WORKGROUP" #ワークグループ名。
 
#
#--------------------- 
 
#PowerCLIコードを扱える様にするためのスナップインを追加。
#VDS≪ポートグループ≫をコマンドより変更するため、VDSスナップインも追加する
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.VimAutomation.vds
 
# 乱数を生成
$RANDOM = Get-Random 1000
 
# ファイル変数作成
$FILE = $Args[0]
 
# Unicodeにファイルを変換するためのファイル名を変数に格納する
# ファイル名が被らないように乱数を利用
$FILE_UNI = "$FILE.$RANDOM"
 
# 引数の確認
if(!$FILE) {
Write-Host "引数にファイルを指定していません。"
Write-Host "CSVファイルを引数で指定してください。"
exit 1
}
 
# ファイルの存在確認
if(Test-Path $FILE) {
Write-Host "$FILE の存在が確認できました。"
} else {
Write-Host "$FILE の存在が確認できませんでした。"
Write-Host "処理を中断します。"
exit 1
}
 
# 文字コードをUnicodeへ変換(SJISだと文字化けする)
Get-Content $FILE | Out-File $FILE_UNI -Encoding UNICODE
 
#複数vCenterサーバへの接続許可設定（本セッションのみ） 
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false
 
# vCenterサーバへ接続
Connect-VIServer -Server $Connect1StServer -User $ConnectUser -Password $ConnectPassword
Connect-VIServer -Server $Connect2ndServer -User $ConnectUser -Password $ConnectPassword
 
 
 
# CSV インポート
$vms = Import-CSV $FILE_UNI
 
 
 
 
function ChangeCPU
{
    Set-VM -VM $args[0] -NumCpu $args[1] -Confirm:$false
    if($? -eq $True){
        Write-Output "項番 $ListNum の$VMName 端末のCPU数を変更しました" | Out-File -Append "$LogDir\Create$LogFilename.txt"
    }
}
 
function ChangeMem
{
    Set-VM -VM $args[0] -MemoryGB $args[1] -Confirm:$false
    if($? -eq $True){
        Write-Output "項番 $ListNum の$VMName 端末のメモリ数を変更しました" | Out-File -Append "$LogDir\Create$LogFilename.txt"
    }
}
 
function ChangeDisk
{
    Get-HardDisk -VM $args[0] | Set-HardDisk -CapacityGB $args[1] -Datastore $args[2] -Server $args[3] -Confirm:$false
    if($? -eq $True){
        Write-Output "項番 $ListNum の$VMName 端末のディスクサイズを変更しました。OS側で拡張作業をして下さい。" | Out-File -Append "$LogDir\Create$LogFilename.txt"
    }
}
function WindowsMakeSettings{
<# WindowsOS の場合、OSCustomizationSpecに、
　　組織名、管理者名、ワークグループ、タイムゾーン、Sid変更、初回起動時のスクリプトや、管理者パスワードを指定可能。
　　ネットワーク（IPアドレスなど）の設定については、OSCustomizationNicMappingコマンドレットで指定する必要がある。
#>
# OSの基本情報設定部分
    $custSpec = New-OSCustomizationSpec -Type NonPersistent -OSType $OSType -OrgName $OrganizationName -FullName $AdminFullName `
    -Workgroup $WorkGroup -TimeZone $TimeZone -ChangeSid -GuiRunOnce $1stScript -AdminPassword $Adminpas
 
    # ネットワークの設定部分、但し仮想マシンに設定するポートグループはここでは設定できない。カスタマイズ時のIPアドレス等
    $custSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP `
    -IpAddress $Ipaddress -SubnetMask $Subnetmask -Dns $PrimaryDNS,$SecondaryDNS -DefaultGateway $Gateway
 
    New-VM -Name $VMName `
            -Template $TemplateName `
            -VMHost $vSphereHost `
            -Datastore $Datastore `
            -Server $Site `
            -Location $VMFolder `
            -OSCustomizationSpec $custSpec
}
function LinuxMakeSetting{
<# LinuxOS の場合、OSCustomizationSpecに、
　　Windowsのような多様な設定は行うことはできない。DNSサーバは設定可能。また、ドメインを指定することが必須。
　　ネットワーク（IPアドレスなど）の設定については、Windows同様、OSCustomizationNicMappingコマンドレットで指定する。
#>
#OSの基本設定部分
    $custSpec = New-OSCustomizationSpec -OSType $OSType -Domain "localhost" -DnsServer $PrimaryDNS,$SecondaryDNS 
    #ネットワーク設定部分
    $custSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP `
    -IpAddress $Ipaddress -SubnetMask $Subnetmask -DefaultGateway $Gateway
    #実際の仮想マシンの作成
    New-VM -Name $VMName `
        -Template $TemplateName `
        -VMHost $vSphereHost `
        -Datastore $Datastore `
        -Server $Site `
        -Location $VMFolder `
        -OSCustomizationSpec $custSpec
 
}
 
function MakeMachine
{
    try
    {
        $TemplateName = Get-Template $Template
 
        #Windows or Linux かでオプションが異なるため、分岐。
        if($OSType -eq "Windows")
        {
            WindowsMakeSettings;
            if($? -eq $True)
            {
                Write-Output "項番 $ListNum の$VMName 端末を作成しました" | Out-File -Append "$LogDir\Create$LogFilename.txt"
            }
        }
        if($OSType -eq "Linux")
        {
            LinuxMakeSetting;
            if($? -eq $True)
            {
                Write-Output "項番 $ListNum の$VMName 端末を作成しました" | Out-File -Append "$LogDir\Create$LogFilename.txt"
            }
        }
#CPU,Memory,Discのそれぞれが作成済みの仮想マシンと異なる値の時、それぞれの値をカスタマイズするための関数呼び出し
        $CheckVM = Get-VM $VMName -Server $Site
        if ($CpuNum -ne $CheckVM.NumCPU){ChangeCPU $VMName $CpuNum}
        if ($MemGB -ne $CheckVM.MemoryGB){ChangeMem $VMName $MemGB}
        if ($DiskGB -ne $CheckVM.HardDisks.CapacityGB){ChangeDisk $VMName $DiskGB $Datastore $Site}
#最後に、NWを通すため、ポートグループを仮想マシンへ設定する。
        Get-VM $VMName -Server $Site |Get-NetworkAdapter|Set-NetworkAdapter -NetworkName $PortGroup -Confirm:$false
        if($? -eq $True){
            Write-Output "項番 $ListNum のNWを変更しました。" | Out-File -Append "$LogDir\Create$LogFilename.txt"
        }
        Set-VM -VM $VMName -Server $Site -DrsAutomationLevel "Disabled" -HARestartPriority $HApolicy -Confirm:$false
        Write-Output "項番 $ListNum の$VMName 端末のDRSレベル、HAポリシーを変更しました。" | Out-File -Append "$LogDir\Create$LogFilename.txt"
        Start-VM -VM $VMName -Server $Site
        Write-Output "項番 $ListNum の$VMName 端末を起動しました。" | Out-File -Append "$LogDir\Create$LogFilename.txt"
    }
    catch [Exception] 
    {
        Write-Output " 項番 $ListNum 作成中に異常が発生しました。CSVに何がしかの問題が有ります。途中終了です。 エラーコード $error[0] が発生しました。" | Out-File -Append "$LogDir\Error$LogFilename.txt"
    }
    finally 
    { 
    }
}
 
# 仮想マシンの作成ループ処理開始
foreach ($vm in $vms) {
# 必要な情報を変数へ格納
# CSVの第一カラムをキーとして各値を取得
    $ListNum = $vm.No 
    $VMName = $vm.VMName
    $OSType = $vm.OSType
    $Ipaddress = $vm.Ipaddress
    $Subnetmask = $vm.Subnetmask
    $Gateway = $vm.Gateway
    $VMFolder = $vm.Folder
    $CpuNum = $vm.Cpu
    $DiskGB = $vm.DiskGB
    $MemGB = $vm.MemoryGB
 
    switch($vm.Site){
        "1st"{$Site = $Connect1StServer ;continue}
        "2nd"{$Site = $Connect2ndServer ;continue}
        default{Write-Output "項番 $ListNum の端末のvCenter　名が不正です。作成できません。" | Out-File -Append "$LogDir\Error$LogFilename.txt";continue } #次のマシンへ
    } 
 
#下記３項目は上記、Siteが決まらないと決定しない項目
#CSVから読み込んだパラメータを元に、Site情報と合わせて設定する。
#複数vCenterに同名の項目がある可能性があるため、vCenterの決定後、検索⇒取得する。
    $PortGroup = get-vdportgroup $vm.Portgp -Server $Site
    $vSphereHost = Get-VMHost $vm.vSphereHost -Server $Site
    $Datastore = Get-Datastore $vm.Datastore -Server $Site 
 
#PowerCLIではOSTypeがWindowsかLinuxでしか対応できないため、それ以外は除外。
    if (($OSType -ne "Windows") -and ($OSType -ne "Linux")){
        Write-Output "項番 $ListNum のOS種別がわかりません。作成しません" | Out-File -Append "$LogDir\Error$LogFilename.txt";continue
    } 
 
 
    switch($vm.OSVersion){ 
        "CSVのOSVersion" {$Template = "実在するテンプレート名";continue}
        #あとは同様にTemplateが作成されたら追加。
        default{Write-Output "項番 $ListNum のOS種別がわかりません。作成しません" | Out-File -Append "$LogDir\Error$LogFilename.txt";continue }
    }
 
    if($vm.HA -eq "on"){ #HAがONの時
        $HApolicy = "ClusterRestartPriority"
    }else{ #HAがON以外の時
        $HApolicy = "Disabled"
    }
 
#仮想マシン作成メインルーチン呼び出し。
    MakeMachine
 
 
}
 
 
 
# すべてのvCenterサーバから切断
Disconnect-VIServer -Server * -Confirm:$false
 
# Unicodeに変換したファイルを削除
Remove-Item $FILE_UNI