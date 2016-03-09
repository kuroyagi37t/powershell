

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
		wmic pagefileset create name=�gc:\pagefile.sys�h
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
### RDP�̑҂��󂯃|�[�g��ύX����B
	process
	{
		Set-ItemProperty 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp -Name 'PortNumber' -Value '33389'
	}
}

function disable-windowsupdate
{
### WindowsUpdate �𖳌�������
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
### Windows �G���[���|�[�g�𖳌�������B
	c:\windows\system32\serverweroption /disable
}

function get-windows-error-report-option
{
### Windows �G���[���|�[�g�𖳌�������B
	c:\windows\system32\serverweroption /query
}

Function set-ceip-option
{
### �J�X�^�}�[�G�N�X�y���G���X�𖳌�������B
	c:\windows\system32\serverceipoption /disable
}

Function Get-ceip-option
{
### �J�X�^�}�[�G�N�X�y���G���X�𖳌�������B
	c:\windows\system32\serverceipoption /query
}

Function set-eventlog-size
{
### �C�x���g���O�T�C�Y��ύX����
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
	$PGUID = powercfg /L|findstr "���p�t�H�[�}���X" | % {$_.Split(" ")[2]}
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

## �t�H���_�I�v�V����(�g���q��\������)
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "HideFileExt" -Value 0
 
## �t�H���_�I�v�V����(�B���t�@�C���A�B���t�H���_�A�B���h���C�u��\������)
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -name "Hidden" -Value 1
 


-----------------------
registryPath	Item	Value	Comment
'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server'	'fDenyTSConnection'	1	'�����[�g�f�X�N�g�b�v�����s���Ă���R���s���[�^����̐ڑ���������'
'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'	'PortNumber'	'33389'	'RDP�ڑ��|�[�g�ύX(tcp/33389)'
'registry::HKEY_CURRENT_USERS\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'	'HideFileExt'	0	'�t�H���_�I�v�V����(�g���q��\������)'
'registry::HKEY_CURRENT_USERS\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'	'Hidden'	1	'�t�H���_�I�v�V����(�B���t�@�C���A�B���t�H���_�A�B���h���C�u��\������)'
'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'	'dontdisplaylastusername'	1	'���[�J���Z�L�����e�B�|���V�[:�Θb�^���O�I���F�Ō�̃��[�U�[����\�����Ȃ�'
-----------------------
FW_Rule

�C�x���g���O�T�C�Y�ύX
limit-eventlog 
--�d���ݒ�
powercfg -L |grep (���p�t�H�[�}���X)| cut -f 3 |powercfg -setactive 



�������_���v�ɂ���

http://jp.fujitsu.com/platform/server/primergy/technical/construct/pdf/win2008-memory-dump.pdf



-------------------------

EEE Windows 2012 R2 �e���v���[�g


���Q�lURL
�x�[�X�T�[�o OS�d�l > Windows Server 2012 R2 for V �V���[�Y G2 
https://cf.iij-group.jp/pages/viewpage.action?pageId=53725727

�EOS
Windows Server 2012 R2 Standard �]����

�ECPU 1
�E������ 4GB

�E�R���s���[�^��
WIN-5SU65JSB77I�i�f�t�H���g�j

�E���[�N�O���[�v
WORKGROUP

�E���[�U�A�J�E���g
administrator
eee********

�E�p�X���[�h
������

x�EWindows�G���[��
�R���g���[���p�l�� > �A�N�V�����Z���^�[ > �����e�i���X > ��背�|�[�g�̉�������m�F > �ݒ�
 �� ���|�[�g�𑗐M�����A���̊m�F��ʂ�����\�����܂���
https://121ware.com/qasearch/1007/app/servlet/relatedqa?QID=015804

x�E�J�X�^�}�G�N�X�y���G���X����v���O����
�R���g���[���p�l�� > �A�N�V�����Z���^�[ > �A�N�V���� �Z���^�[�̐ݒ��ύX > �J�X�^�}�G�N�X�y���G���X����v���O�����̐ݒ肢�����A�Q�����܂���i�f�t�H���g�j
http://utaukitune.ldblog.jp/archives/65870405.html

x�E�@�\�̒ǉ�
Windows Server �o�b�N�A�b�v
 �� �C���X�g�[�����Ă��Ȃ��B(�f�t�H���g)

x�y�T�[�o�V�X�e���z�u�ڍאݒ�v
�p�t�H�[�}���X > �ڍאݒ� > ���z������
�S�Ẵh���C�u�̃y�[�W���O�t�@�C���̃T�C�Y�������I�ɊǗ�����B

x�E�N���Ɖ�
�I�y���[�e�B���O�V�X�e���̈ꗗ��\�����鎞��:
30s �� 5s

x�E�����[�g�f�X�N�g�b�v
�V�X�e���̃v���p�e�B > �����[�g�^�u
�����[�g �f�X�N�g�b�v�����s���Ă���R���s���[�^����̐ڑ��������遛 �� ��
�l�b�g���[�N���x���F�؂Ń����[�g �f�X�N�g�b�v�����s���Ă���R���s���[�^����̐ڑ��������遡 �� ��

�E�l�ݒ�
�w�i - �f�t�H���g
�X�N���[���Z�C�o�[ - �Ȃ�

�E�d���I�v�V����
�o�����X �� ���p�t�H�[�}���X

x�EWindows Update
�ݒ�̕ύX
�X�V�v���O�������m�F���Ȃ���

x�E���O�I�����
�c+R secpol.msc
���[�J���Z�L�����e�B�|���V�[�ɂ����� [�Θb�^���O�I���F�Ō�̃��[�U�[����\�����Ȃ�] ���u�L���v�ɐݒ肷��
(�f�t�H���g�́u�����v)�B

xx�E�C�x���g���O�ݒ� 
�C�x���g�r���[�A�[ > �v���p�e�B�ݒ�
�A�v���P�[�V�����A�V�X�e���A�Z�L�����e�B���O�̑S�Ăɂ����āA�ȉ��̐ݒ���s���B
�@�ő働�O �T�C�Y�@20480 KB �� 262144 KB�i256 MB)
�@�C�x���g ���O���ő�l�ɒB�����Ƃ�
�@�@�C�x���g���㏑�����Ȃ��Ń��O���A�[�J�C�u���遜
�@�@
�E�l�b�g���[�N�ڑ��F�l�b�g���[�N�A�_�v�^�ݒ� 
IPv6����

IPv4 �� IPv6 ���D��ɂ���
http://www.vwnet.jp/Windows/w7/IPv4/IPv4PriorityUP.html

�E�l�b�g���[�N���j�^ 
�l�b�g���[�N���j�^�c�[��
Download Microsoft Message Analyzer from Official Microsoft Download Center
http://www.microsoft.com/en-us/download/details.aspx?id=40308
 �� �C���X�g�[�����Ȃ�
 
�E�A�J�E���g���b�N�A�E�g�̃|���V�[
�f�t�H���g
�@�A�J�E���g ���b�N�A�E�g�̂������l�F0 �񃍃O�I���Ɏ��s
�@���b�N�A�E�g �J�E���^�̃��Z�b�g�F�Y���Ȃ�
�@���b�N�A�E�g�L�����ԁF�Y���Ȃ�

�E�T�[�r�X�N���ݒ� ��
Print Spooler �F���� �� ����

�EWindows�t�@�C�A�[�E�H�[��
�ȉ���L���i���j
�@�t�@�C���ƃv�����^�[�̋��L (�G�R�[�v�� - ICMPv4 ��M)
�@�����[�g �f�X�N�g�b�v - ���[�U�[ ���[�h (TCP ��M)
�@�����[�g �f�X�N�g�b�v - ���[�U�[ ���[�h (UDP ��M)
�@�����[�g �f�X�N�g�b�v - �V���h�E (TCP ��M)


�E���W�X�g���`���[�j���O

�u���E�W���O���X�g�ɕ\������Ȃ��悤�ɂ��� 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Lanmanserver\parameters
		Hidden
		 �� DWORD 1
		 
�\�[�X���[�e�B���O�̖�����
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		DisableIPSourceRouting
		 �� DWORD�@2

�������Ȃ��Q�[�g�E�F�C�̎������o�𖳌��ɂ��� 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		EnableDeadGWDetect
		 �� DWORD 0

ICMP���_�C���N�g�ɂ��OSPF�������[�g�̏㏑���𖳌��ɂ��� 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		EnableICMPRedirect
		 �� DWORD 0

Keep-Alive�p�P�b�g�̑��M�Ԋu��K�؂ɐݒ肷�� 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		KeepAliveTime
		 �� DWORD 300000�i5 ���j�i����F7200000 �i2 ���ԁj�j
	 
IRDP�𖳌��ɂ��� 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
		PerformRouterDiscovery
		 �� DWORD 0
		
 IRDP�Ƃ�
 http://www.infraexpert.com/study/gateway2.htm

TCP ���X�̃f�[�^ �Z�O�����g���đ��M����񐔂�ݒ肷�� 
	HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tcpip\parameters
	TcpMaxDataRetransmissions
	 �� DWORD 3
		
Backinfo.exe�̎����N���i�f�X�N�`�b�v�Ƀz�X�g����\������j
	HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\BackInfo
		BackInfo
		 �� REG_SZ C:\Program Files\Tech Tools\BackInfo.exe
	�����炩����exe�t�@�C����u���Ă���
	
	
	
------------------------------------------------
<�����{>
�E�l�b�g���[�N���j�^
�{�V�X�e���ł́A�l�b�g���[�N�֘A�̃g���u���V���[�g�̂��߃l�b�g���[�N���j�^�c�[����W���ŃC���X�g�[��������j�Ƃ���B�������A�l�b�g���[�N ���j�^ �c�[���� OS �W���R���|�[�l���g���珜�O����Ă��邽�߁A�ȉ��̃T�C�g���_�E�����[�h���A�C���X�g�[��������̂Ƃ���B
 Download Microsoft Message Analyzer from Official Microsoft Download Center
  http://www.microsoft.com/en-us/download/details.aspx?id=40308

�EBackupAndRotateArchivedEventlogs
C:\Program Files\Tech Tools\BackupAndRotateArchivedEventLogs\BackupAndRotateArchivedEventLogs.bat