

Invoke-Expression (Invoke-RestMethod https://raw.github.com/guitarrapc/PowerShellUtil/master/Install-JapaneseUI/Install-JapaneseUI.ps1);Install-JapaneseUI -targetOSVersion Windows2012R2 -credential (Get-Credential)

function Write-WindowsUpdateLog ($Message)
{
    $Output = "{0} {1}" -f (Get-Date), $Message
    Write-Output $Output
    $output | Out-File (Join-Path $LogPath -ChildPath $LogFile) -Append -Encoding utf8
}

function Install-JapaneseUI
{
    param
    (
        [parameter(
            mandatory = 1,
            position = 0)]
        [ValidateSet("Windows2012","Windows2012R2")]
        [string]
        $targetOSVersion,

        [parameter(
            mandatory = 0,
            position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $winTemp = "C:\Windows\Temp",

        [parameter(
            mandatory = 0,
            position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        $outputRunOncePs1 = "C:\Windows\Temp\SetupLang.ps1",

        [parameter(
            mandatory = 1,
            position = 3)]
        [System.Management.Automation.PSCredential]
        $credential,

        [parameter(
            mandatory = 0,
            position = 4)]
        [switch]
        $force = $false

        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $disableautosizepage = $false

        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $enblekdump = $false

        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $disablerdp = $false

        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $rdpport = 33389

        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $disabletzjst = $false
        
        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $disablepowercfghigh = $false
        
        [parameter(
        	mandatory = 0
        	)]
        [switch]
        $disableipv6 = $false
    )

    begin
    {
        $ErrorActionPreference = "Stop"
        $confirm = !$force

        # Set Language Pack URI
        switch ($targetOSVersion)
        {
            "Windows2012"   {
                                [uri]$lpUrl = "http://fg.v4.download.windowsupdate.com/msdownload/update/software/updt/2012/10"
                                $lpFile = "windowsserver2012-kb2607607-x64-jpn_d079f61ac6b2bab923f14cd47c68c4af0835537f.cab"
                            }
            "Windows2012R2" {
                                [uri]$lpurl = "http://fg.v4.download.windowsupdate.com/c/msdownload/update/software/updt/2014/11"
                                $lpfile = "windows8.1-kb3012997-x64-ja-jp-server_b2eb77d3887eeb847ee2f27128e76ebeda852b26.cab"
                            }
        }

        $languagePackURI = "$lpurl/$lpfile"

        # set AutoLogin Configuration
        $autoLogonPath = "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $adminUser = $credential.GetNetworkCredential().UserName
        $adminPassword = $credential.GetNetworkCredential().Password

        # This will run after Installation done and restarted Computer, then first login
        $RunOncePath = "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        $runOnceCmdlet = "
            Set-WinUILanguageOverride ja-JP;                                          # Change Windows UI to Japanese
            Set-WinHomeLocation 122;                                                  # Change Region to Japan
            Set-WinSystemLocal ja-JP                                                  # Set Non-Unicode Program Language to Japanese
            Set-ItemProperty -Path '$autoLogonPath' -Name 'AutoAdminLogon' -Value '0' # Disable AutoAdminLogon
            Remove-ItemProperty -Path '$autoLogonPath' -Name 'DefaultUserName'        # Remove UserName
            Remove-ItemProperty -Path '$autoLogonPath' -Name 'DefaultPassword'        # Remove Password
            Restart-Computer"
    }

    process
    {
        # Japanese UI
        Write-Verbose "Change Win User Language as ja-JP, en-US"
        Set-WinUserLanguageList ja-jp,en-US -Force

        # Set Japanese LanguagePack
        Write-Verbose ("Downloading JP Language Pack from '{0}' to '{1}'" -f $languagePackURI, $winTemp)
        Start-BitsTransfer -Source $languagePackURI -Destination $winTemp

        Write-Verbose ("Installing JP Language Pack from '{0}'" -f $winTemp)
        Add-WindowsPackage -Online -PackagePath (Join-Path $wintemp $lpfile -Resolve)

        Write-Verbose ("Output runonce cmd to execute PowerShell as '{0}'" -f $outputRunOncePs1)
        $runOnceCmdlet | Out-File -FilePath $outputRunOncePs1 -Encoding ascii

        Write-Verbose ("Set RunOnce registry")
        Set-ItemProperty -Path $RunOncePath -Name "SetupLang" -Value "powershell.exe -ExecutionPolicy RemoteSigned -file $outputRunOncePs1"

        # Set Japanese Keyboard : English - LayerDriver JPN : kbd101.dll
        Set-ItemProperty 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -Name 'LayerDriver JPN' -Value 'kbd106.dll'

        # Auto Login Settings
        Set-ItemProperty -Path $autoLogonPath -Name "AutoAdminLogon"  -Value "1"
        Set-ItemProperty -Path $autoLogonPath -Name "DefaultUserName" -Value $adminUser
        Set-ItemProperty -Path $autoLogonPath -Name "DefaultPassword" -Value $adminPassword

		# TimeZone
		tzutil.exe /s "Tokyo Standard Time"


        # Restart
        Write-Verbose ("Restart Computer, Make sure Login to")
        Restart-Computer -Confirm:$confirm -Force:$force
    }
}

function Firewall_rule
{

if (-not(Get-NetFirewallRule | where Name -eq PowerShellRemoting-In))
{
	New-NetFirewallRule `
		-Name PowerShellRemoting-In `
		-DisplayName PowerShellRemoting-In `
		-Description "Windows PowerShell Remoting required to open for public connection. not for private network." `
		-Group "Windows Remote Management" `
		-Enabled True `
		-Profile Any `
		-Direction Inbound `
		-Action Allow `
		-EdgeTraversalPolicy Block `
		-LooseSourceMapping $False `
		-LocalOnlyMapping $False `
		-OverrideBlockRules $False `
		-Program Any `
		-LocalAddress Any `
		-RemoteAddress Any `
		-Protocol TCP `
		-LocalPort 5985 `
		-RemotePort Any `
		-LocalUser Any `
		-RemoteUser Any 
}
else
{
		Write-Verbose "Windows PowerShell Remoting port TCP 5985 was alredy opend. Show Rule"
		Get-NetFirewallPortFilter -Protocol TCP | where Localport -eq 5985
}





}

function VMEM_Set
{
	if ($disableautosizepage) {
		write-host "Determining system RAM and setting pagefile..."
		$RAM = Get-WmiObject -Class Win32_OperatingSystem | Select TotalVisibleMemorySize
		$RAM = ($RAM.TotalVisibleMemorySize / 1kb).tostring("F00")
		write-host "disable pagefile automanage"
		wmic computersystem set AutomaticManagedPagefile=False
		Write-Host "removing old pagefile"
		wmic pagefileset delete
		write-host "creating new pagefile on C:\"
		wmic pagefileset create name=“c:\pagefile.sys”
		write-host "set size"
		$PageFile = Get-WmiObject -Class Win32_PageFileSetting
		$PageFile.InitialSize = $RAM+257
		$PageFile.MaximumSize = $RAM+257
		[void]$PageFile.Put()
	}
	else
	{
		write-host "disable pagefile automanage"
		wmic computersystem set AutomaticManagedPagefile=true
	}
}

function RDP_Port
{
### RDPの待ち受けポートを変更する。
	process
	{
		Set-ItemProperty 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp -Name 'PortNumber' -Value '33389'
	}
}

function disable-windowsupdate
{
### WindowsUpdate を無効化する
	$AutoUpdate = new-object -ComObject "Microsoft.Update.AutoUpdate"
	$AutoUpdate.Settings.NotificationLevel = 1
}

function startup-delay-time-set
{
#	$computer = Get-WmiObject -Class win32_computersystem 
#	$computer.SystemStartupDelay 
#	$computer.SystemStartupDelay = 5 
#	$computer.put() 
}

function set-windows-error-report-option
{
### Windows エラーリポートを無効化する。
	c:\windows\system32\serverweroption /disable
}

function get-windows-error-report-option
{
### Windows エラーリポートを無効化する。
	c:\windows\system32\serverweroption /query
}

Function set-ceip-option
{
### カスタマーエクスペリエンスを無効化する。
	c:\windows\system32\serverceipoption /disable
}

Function Get-ceip-option
{
### カスタマーエクスペリエンスを無効化する。
	c:\windows\system32\serverceipoption /query
}

Function set-eventlog-size
{
### イベントログサイズを変更する
	limit-eventlog -logname Application -maximumsize 256mb -overflowaction donotoverwrite
}

Function get-eventlog-size
{
	Get-EventLog -list
}

Function Get-Eventlog-test
{
	Get-Eventlog-size
	Get-Eventlog application -EntryType error
	Get-Eventlog -EntryType error
}

Function add-windowsfeature-option
{
	add-windwosfeature snmp-service
	add-windwosfeature snmp-wmi-provider
	add-windwosfeature windows-server-backup
### IIS
### ADD-WindowsFeature Web-Server
### ADD-WindowsFeature Web-MGMT-Tools
### ADD-WindowsFeature Web-CGI
}



function powercfg-set
{
	$PGUID = powercfg /L|findstr "高パフォーマンス" | % {$_.Split(" ")[2]}
	powercfg /S $PGUID
}

function powercfg-get
{
	posercfg /L
}

function set-time-zone
{
	tzutil.exe /s "Tokyo Standard Time"

}

function get-time-zone
{
	tzutil.exe /g

}

function serversetup
{
	
}


function Get-Service_list
{
   Get-WMIObject Win32_Service |Select-Object Caption,State,StartMode |Sort-Object Caption |Export-csv -Encoding UTF8 c:\service.csv
   Get-WindowsFeature |select-object { $_.depth,$_.displayname,$_.installstate }
}

## フォルダオプション(拡張子を表示する)
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "HideFileExt" -Value 0
 
## フォルダオプション(隠しファイル、隠しフォルダ、隠しドライブを表示する)
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "Hidden" -Value 1
 


-----------------------
registryPath	Item	Value	Comment
'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server'	'fDenyTSConnection'	1	'リモートデスクトップを実行しているコンピュータからの接続を許可する'
'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'	'PortNumber'	'33389'	'RDP接続ポート変更(tcp/33389)'
'registry::HKEY_CURRENT_USERS\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'	'HideFileExt'	0	'フォルダオプション(拡張子を表示する)'
'registry::HKEY_CURRENT_USERS\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'	'Hidden'	1	'フォルダオプション(隠しファイル、隠しフォルダ、隠しドライブを表示する)'
'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'	'dontdisplaylastusername'	1	'ローカルセキュリティポリシー:対話型ログオン：最後のユーザー名を表示しない'
-----------------------
FW_Rule

イベントログサイズ変更
limit-eventlog 
--電源設定
powercfg -L |grep (高パフォーマンス)| cut -f 3 |powercfg -setactive 



メモリダンプについて

http://jp.fujitsu.com/platform/server/primergy/technical/construct/pdf/win2008-memory-dump.pdf



-------------------------

EEE Windows 2012 R2 テンプレート


■参考URL
ベースサーバ OS仕様 > Windows Server 2012 R2 for V シリーズ G2 
https://cf.iij-group.jp/pages/viewpage.action?pageId=53725727

・OS
Windows Server 2012 R2 Standard 評価版

・CPU 1
・メモリ 4GB

・コンピュータ名
WIN-5SU65JSB77I（デフォルト）

・ワークグループ
WORKGROUP

・ユーザアカウント
administrator
eee********

・パスワード
無期限

x・Windowsエラー報告
コントロールパネル > アクションセンター > メンテナンス > 問題レポートの解決策を確認 > 設定
 → レポートを送信せず、この確認画面も今後表示しません
https://121ware.com/qasearch/1007/app/servlet/relatedqa?QID=015804

x・カスタマエクスペリエンス向上プログラム
コントロールパネル > アクションセンター > アクション センターの設定を変更 > カスタマエクスペリエンス向上プログラムの設定いいえ、参加しません（デフォルト）
http://utaukitune.ldblog.jp/archives/65870405.html

x・機能の追加
Windows Server バックアップ
 → インストールしていない。(デフォルト)

x【サーバシステム】「詳細設定」
パフォーマンス > 詳細設定 > 仮想メモリ
全てのドライブのページングファイルのサイズを自動的に管理する。

x・起動と回復
オペレーティングシステムの一覧を表示する時間:
30s → 5s

x・リモートデスクトップ
システムのプロパティ > リモートタブ
リモート デスクトップを実行しているコンピュータからの接続を許可する○ → ●
ネットワークレベル認証でリモート デスクトップを実行しているコンピュータからの接続を許可する■ → □

・個人設定
背景 - デフォルト
スクリーンセイバー - なし

・電源オプション
バランス → 高パフォーマンス

x・Windows Update
設定の変更
更新プログラムを確認しない●

x・ログオン画面
田+R secpol.msc
ローカルセキュリティポリシーにおいて [対話型ログオン：最後のユーザー名を表示しない] を「有効」に設定する
(デフォルトは「無効」)。

xx・イベントログ設定 
イベントビューアー > プロパティ設定
アプリケーション、システム、セキュリティログの全てにおいて、以下の設定を行う。
　最大ログ サイズ　20480 KB → 262144 KB（256 MB)
　イベント ログが最大値に達したとき
　　イベントを上書きしないでログをアーカイブする●
　　
・ネットワーク接続：ネットワークアダプタ設定 
IPv6無効

IPv4 を IPv6 より優先にする
http://www.vwnet.jp/Windows/w7/IPv4/IPv4PriorityUP.html

・ネットワークモニタ 
ネットワークモニタツール
Download Microsoft Message Analyzer from Official Microsoft Download Center
http://www.microsoft.com/en-us/download/details.aspx?id=40308
 → インストールしない
 
・アカウントロックアウトのポリシー
デフォルト
　アカウント ロックアウトのしきい値：0 回ログオンに失敗
　ロックアウト カウンタのリセット：該当なし
　ロックアウト有効期間：該当なし

・サービス起動設定 ★
Print Spooler ：自動 → 無効

・Windowsファイアーウォール
以下を有効（許可）
　ファイルとプリンターの共有 (エコー要求 - ICMPv4 受信)
　リモート デスクトップ - ユーザー モード (TCP 受信)
　リモート デスクトップ - ユーザー モード (UDP 受信)
　リモート デスクトップ - シャドウ (TCP 受信)


・レジストリチューニング

ブラウジングリストに表示されないようにする 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Lanmanserver\parameters
		Hidden
		 → DWORD 1
		 
ソースルーティングの無効化
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		DisableIPSourceRouting
		 → DWORD　2

反応しないゲートウェイの自動検出を無効にする 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		EnableDeadGWDetect
		 → DWORD 0

ICMPリダイレクトによるOSPF生成ルートの上書きを無効にする 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		EnableICMPRedirect
		 → DWORD 0

Keep-Aliveパケットの送信間隔を適切に設定する 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		KeepAliveTime
		 → DWORD 300000（5 分）（既定：7200000 （2 時間））
	 
IRDPを無効にする 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		PerformRouterDiscovery
		 → DWORD 0
		
 IRDPとは
 http://www.infraexpert.com/study/gateway2.htm

TCP が個々のデータ セグメントを再送信する回数を設定する 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
	TcpMaxDataRetransmissions
	 → DWORD 3
		
Backinfo.exeの自動起動（デスクチップにホスト情報を表示する）
	HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\BackInfo
		BackInfo
		 → REG_SZ C:\Program Files\Tech Tools\BackInfo.exe
	※あらかじめexeファイルを置いておく
	
	
	
------------------------------------------------
<未実施>
・ネットワークモニタ
本システムでは、ネットワーク関連のトラブルシュートのためネットワークモニタツールを標準でインストールする方針とする。しかし、ネットワーク モニタ ツールは OS 標準コンポーネントから除外されているため、以下のサイトよりダウンロードし、インストールするものとする。
 Download Microsoft Message Analyzer from Official Microsoft Download Center
  http://www.microsoft.com/en-us/download/details.aspx?id=40308

・BackupAndRotateArchivedEventlogs
C:\Program Files\Tech Tools\BackupAndRotateArchivedEventLogs\BackupAndRotateArchivedEventLogs.bat