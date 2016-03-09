システムテスト



function eventlog_test 
{
	Get-EventLog -list
	Get-EventLog application -EntryType error |Format-List 
	Get-EventLog system -EntryType error |format-List 
}

function Check-SystemInfo
{
    $systemInfo = @{}
    # Date
    # チェック実行日時
    $systemInfo["CheckDateTime"] = Get-Date -Format "yyyyMMdd_HHmmss"

    # Environment
    # ホスト名
    $systemInfo["EnvComputername"] = $env:computername
    # Windowsディレクトリ
    $systemInfo["EnvUsername"] = $env:windir

    # OS
    $os = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_OperatingSystem"
    # OS名称
    $systemInfo["OsCaption"] = $os.Caption
    # OSバージョン
    $systemInfo["OsVersion"] = $os.Version
    # OSアーキテクチャ（ビット数）
    $systemInfo["OsArchitecture"] = $os.OSArchitecture
    # OSインストール日
    $systemInfo["OsInstallDate"] = $os.InstallDate
    # 最終起動日時
    $systemInfo["OsLastBootUpTime"] = $os.LastBootUpTime

    # Computer
    $computer = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_ComputerSystem"
    # メーカー
    $systemInfo["ComputerManufacturer"] = $computer.Manufacturer
    # モデル
    $systemInfo["ComputerModel"] = $computer.Model
    # Windowsドメイン（ワークグループ）
    $systemInfo["ComputerDomain"] = $computer.Domain
    # 所有者（通常PCを初期セットアップ時に作成したアカウント名が表示される）
    $systemInfo["PrimaryOwnerName"] = $computer.PrimaryOwnerName

    # BIOS
    $bios = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_BIOS"
    # シリアル番号（ユーザ名とコンピュータ名は利用者が指定できるので端末の一意性を特定する情報）
    # VirtualBoxだと0が出力されてる
    $systemInfo["BiosSerialNumber"] = $bios.SerialNumber

    return $systemInfo
}

function LocalUser_test
{
	$result = @()
	$accountObjList =  Get-CimInstance -ClassName Win32_Account
	$userObjList = Get-CimInstance -ClassName Win32_UserAccount
	foreach($userObj in $userObjList)
	{  
    	$IsLocalAccount = ($userObjList | ?{$_.SID -eq $userObj.SID}).LocalAccount
    	if($IsLocalAccount)
    	{
			$query = "WinNT://{0}/{1},user" -F $env:COMPUTERNAME,$userObj.Name
			$dirObj = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $query
			$PasswordExpirationDate = $dirObj.InvokeGet("PasswordExpirationDate")
			$PasswordExpirationRemainDays = ($PasswordExpirationDate - (Get-Date)).Days
			$obj = New-Object -TypeName PsObject
			Add-Member -InputObject $obj -MemberType NoteProperty -Name "UserName" -Value $userObj.Name
			Add-Member -InputObject $obj -MemberType NoteProperty -Name "PasswordExpirationDate" -Value $PasswordExpirationDate
			Add-Member -InputObject $obj -MemberType NoteProperty -Name "PasswordExpirationRemainDays" -Value $PasswordExpirationRemainDays
			Add-Member -InputObject $obj -MemberType NoteProperty -Name "IsAccountLocked" -Value ($dirObj.InvokeGet("IsAccountLocked"))
			$result += $obj
		}
	}
	$result
}


function eventlog_test 
{
	Get-EventLog application -EntryType error |format-list 
	Get-EventLog system -EntryType error |format-list 
}
1.9
Get-WmiObject Win32_PnpEntity | ?{ $_.ConfigManagerErrorCode -ne 0 } | ft Caption,PNPDeviceID,ConfigManagerErrorCode -AutoSize




