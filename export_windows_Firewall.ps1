$ArrayInbound=@()
$ArrayOutbound=@()

Get-NetFireWallRule|Sort DisplayGroup|Foreach {
	$NFSecF=Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $_
	$NFAppF=Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_
	$NFSerF=Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $_
	$NFAddF=Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $_
	$NFPorF=Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_

	$Properties=@{
		"DisplayName"=$_.DisplayName
		"DisplayGroup"=$_.DisplayGroup
		"Profile"=$_.Profile
		"Direction"=$_.Direction
		"Enabled"=$_.Enabled
		"Action"=$_.Action
		"OverrideBlockRules"=$NFSecF.OverrideBlockRules
		"Program"=$NFAppF.Program
		"Service"=$NFSerF.Service
		"LocalAddress"=($NFAddF.LocalAddress -join ";")
		"RemoteAddress"=($NFAddF.RemoteAddress -join ";")
		"Protocol"=$NFPorF.Protocol
		"LocalPort"=$NFPorF.LocalPort
		"RemotePort"=$NFPorF.RemotePort
		"IcmpType"=$NFPorF.IcmpType
		"RemoteUser"=$NFSecF.RemoteUser
		"RemoteComputer"=$NFSecF.RemoteComputer
		"LocalUser"=$NFSecF.LocalUser
		"Owner"=$NFSecF.Owner
		"Package"=$NFAppF.Package
	}

	IF ($_.Direction -eq "Inbound") {
		$ArrayInbound+=(New-Object -typename PSObject -property $Properties|Select @{name="名前";Expression={$_.DisplayName}},`
		@{name="グループ";Expression={$_.DisplayGroup}},@{name="プロファイル";Expression={$_.Profile}},`
		@{name="有効";Expression={$_.Enabled}},@{name="操作";Expression={$_.Action}},`
		@{name="優先";Expression={$_.OverrideBlockRules}},@{name="プログラム";Expression={$_.Program}},`
		@{name="ローカルアドレス";Expression={$_.LocalAddress}},@{name="リモートアドレス";Expression={$_.RemoteAddress}},`
		@{name="プロトコル";Expression={$_.Protocol}},@{name="ローカルポート";Expression={$_.LocalPort}},`
		@{name="リモートポート";Expression={$_.RemotePort}},@{name="承認されているユーザー";Expression={$_.RemoteUser}},`
		@{name="承認されているコンピューター";Expression={$_.RemotePort}},@{name="承認されているローカルプリンシパル";Expression={$_.LocalUser}},`
		@{name="ローカルユーザーオーナー";Expression={$_.Owner}},@{name="アプリケーションパッケージ";Expression={$_.Package}})
		Write-Host $_.DisplayName "(受信の規則) を記録しました。"
	}
	ElseIF ($_.Direction -eq "Outbound") {			
		$ArrayOutbound+=(New-Object -typename PSObject -property $Properties|Select @{name="名前";Expression={$_.DisplayName}},`
		@{name="グループ";Expression={$_.DisplayGroup}},@{name="プロファイル";Expression={$_.Profile}},`
		@{name="有効";Expression={$_.Enabled}},@{name="操作";Expression={$_.Action}},`
		@{name="優先";Expression={$_.OverrideBlockRules}},@{name="プログラム";Expression={$_.Program}},`
		@{name="ローカルアドレス";Expression={$_.LocalAddress}},@{name="リモートアドレス";Expression={$_.RemoteAddress}},`
		@{name="プロトコル";Expression={$_.Protocol}},@{name="ローカルポート";Expression={$_.LocalPort}},`
		@{name="リモートポート";Expression={$_.RemotePort}},@{name="承認されているユーザー";Expression={$_.RemoteUser}},`
		@{name="承認されているコンピューター";Expression={$_.RemotePort}},@{name="承認されているローカルプリンシパル";Expression={$_.LocalUser}},`
		@{name="ローカルユーザーオーナー";Expression={$_.Owner}},@{name="アプリケーションパッケージ";Expression={$_.Package}})
		Write-Host $_.DisplayName "(送信の規則) を記録しました。"
	}
}

$ArrayInbound|Export-CSV Inbound-FirewallRule.csv -NoTypeInformation -encoding Default
$ArrayOutbound|Export-CSV Outbound-FirewallRule.csv -NoTypeInformation -encoding Default
					
