�V�X�e���e�X�g



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
    # �`�F�b�N���s����
    $systemInfo["CheckDateTime"] = Get-Date -Format "yyyyMMdd_HHmmss"

    # Environment
    # �z�X�g��
    $systemInfo["EnvComputername"] = $env:computername
    # Windows�f�B���N�g��
    $systemInfo["EnvUsername"] = $env:windir

    # OS
    $os = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_OperatingSystem"
    # OS����
    $systemInfo["OsCaption"] = $os.Caption
    # OS�o�[�W����
    $systemInfo["OsVersion"] = $os.Version
    # OS�A�[�L�e�N�`���i�r�b�g���j
    $systemInfo["OsArchitecture"] = $os.OSArchitecture
    # OS�C���X�g�[����
    $systemInfo["OsInstallDate"] = $os.InstallDate
    # �ŏI�N������
    $systemInfo["OsLastBootUpTime"] = $os.LastBootUpTime

    # Computer
    $computer = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_ComputerSystem"
    # ���[�J�[
    $systemInfo["ComputerManufacturer"] = $computer.Manufacturer
    # ���f��
    $systemInfo["ComputerModel"] = $computer.Model
    # Windows�h���C���i���[�N�O���[�v�j
    $systemInfo["ComputerDomain"] = $computer.Domain
    # ���L�ҁi�ʏ�PC�������Z�b�g�A�b�v���ɍ쐬�����A�J�E���g�����\�������j
    $systemInfo["PrimaryOwnerName"] = $computer.PrimaryOwnerName

    # BIOS
    $bios = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_BIOS"
    # �V���A���ԍ��i���[�U���ƃR���s���[�^���͗��p�҂��w��ł���̂Œ[���̈�Ӑ�����肷����j
    # VirtualBox����0���o�͂���Ă�
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




