Import-Module C:\usersystem\scripts\afteradd\PSFTP\PSFTP
Import-Module C:\usersystem\scripts\afteradd\SSH-Sessions\SSH-Sessions

C:\usersystem\scripts\afteradd\exportlog.ps1

## SSH 環境変数
[string]$SSH_Server="172.28.201.145"
[string]$SSH_User="root"
[string]$SSH_Pass="Usk6v9EE"
[string]$SSH_Port="65522"

[string]$CR="`n"
[string]$CRLF="`r`n"

## ファイルサーバ変数
[string]$WINFS="waka-nascl01u1"                            ##ファイルサーバ クラスター名
[string]$target="\\waka-nascl01u1\"                        ##ディレクトリパス置換用文字列 置換前
[string]$replace="x:\vol\data-userdata_stu-tea_rw\"        ##ディレクトリパス置換用文字列 置換後
[string]$PS_user="stu\administrator"
[string]$PS_pass="Usk6v9E"
$secPassword = ConvertTo-SecureString $PS_pass -AsPlainText -Force
$WinCredential = New-Object System.Management.Automation.PSCredential($PS_user,$secPassword)
[string]$MYDOM=(Get-ADDomain).name
[string]$MYDOM_DN=$(Get-ADDomain).DistinguishedName
[string]$MYDOM_FSMO=$(Get-ADDomain).RIDMaster

[string]$Win_Move_Path=$replace.TrimEnd("\")+"\taihi\"
[string]$Lin_Move_Path="/vol1/taihi/"

## CSV 環境変数
[string]$CSV_HeaderSTR="adhomedir,uid,group,option04,option03"
## CSV読み込み
[string]$CSV_Header = $CSV_HeaderStr -split ","

##Log用変数
$timestamp={Get-Date -Format "yyyyMMdd-HHmmss"}
[string]$basedir=Convert-Path $(Split-Path $MyInvocation.InvocationName -Parent)
[string]$psName=Split-Path $MyInvocation.InvocationName -Leaf
[string]$psBaseName=$psName  -replace "\.ps1$", ""
[string]$sLogPath=join-path $basedir "Logs"
[string]$sDataPath=join-path $basedir "Data"
[string]$sDate=$timestamp.Invoke()

[string]$MSG_Process_Start=":CSVファイルの処理を開始します。->"
[string]$EMSG_AccChk_NOTEXIST=":アカウントがADに登録されていません->"
[string]$MSG_AccChk_EXIST=":アカウントがADに登録されています->"
[string]$EMSG_Set_ADGroup=":既にグループに登録されています。->"
[string]$EMSG_ADGroup_NotFound=":ADグループが存在しません->"
[string]$EMSG_ADGroup=":ADグループの登録時にエラーが発生しました->"
[string]$MSG_ADD_ADGroup=":ADグループに登録しました。->"
[string]$MSG_ADD_ADGroup_SKIP=":既にグループに登録されています。->"
[string]$MSG_ADGroup_SKIP="ADグループが存在しません。->"
[string]$MSG_Set_PrimaryGrp=":プライマリグループへの追加終了"
[string]$EMSG_Set_PrimaryGrp_Error=":プライマリグループの変更ができません。->"
[string]$EMSG_PrimaryGrp_Error=":プライマリグループに所属していないため変更ができません。->"
[string]$MSG_FTP_Conn="FTPサーバーに接続します。->"
[string]$EMSG_FTP_Conn="FTPサーバーの処理中にエラーがありました。->"
[string]$MSG_GETCSV_OLD_EXIST=":OLD_CSVファイルがロカールに存在するためFTP取得はSKIPします。->"
[string]$MSG_GETCSV_CSV_EXIST=":CSVファイルがロカールに存在するためFTP取得はSKIPします。->"
[string]$MSG_GETCSV_CSV=":FTPサーバーよりCSVファイルを取得します。->"
[string]$MSG_DELCSV_CSV_EXIST=":CSVファイルがロカールに存在するためFTP削除はSKIPします。->"
[string]$MSG_DELCSV_OLD_NOT_EXIST=":OLD_CSVファイルがロカールに存在するしない為FTP削除はSKIPします。->"
[string]$MSG_DELCSV_CSV=":FTPサーバーのCSVファイルを削除します。->"
[string]$MSG_HomeDir_SKIP=":ユーザーディレクトリが存在するため、処理をSKIPします->"
[string]$MSG_HomeDir_Create=":("+$WINFS+")ユーザーディレクトリ作成->"
[string]$MSG_HomeDir_public=":("+$WINFS+")public_htmlディレクトリ作成->"
[string]$MSG_HomeDir_private=":("+$WINFS+")private_htmlディレクトリ作成->"
[string]$MSG_HomeDir_grant=":("+$WINFS+")ユーザーディレクトリNTFS権限変更->"
[string]$MSG_HomeDir_setown=":("+$WINFS+")ユーザーディレクトリ所有者変更->"
[string]$MSG_HomeDir_robocopy=":("+$WINFS+")ユーザーディレクトリのrobocopy->"
[string]$EMSG_HomeDir_Create=":("+$WINFS+")ユーザーディレクトリの作成できませんでした。->"
[string]$MSG_HomeDir_Move=":("+$WINFS+")ユーザーディレクトリを退避しました。"
[string]$MSG_HomeDir_Move_Skip=":("+$WINFS+")ユーザーディレクトリがないため退避をSKIPします->"
[string]$EMSG_HomeDir_Move=":("+$WINFS+")ユーザーディレクトリを退避できませんでした。->"

## FTP  環境変数
$FTP_Server="163.51.200.140"
$FTP_User="bostadmin"
$FTP_Pass="32sFAGKm"
$FTP_Passwd=ConvertTo-SecureString –String $FTP_Pass –AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $FTP_User,$FTP_Passwd
$FTP_Session = "FromAWS_"+$timestamp.Invoke()
$NEW_CSV_PATH="/add"
$DEL_CSV_PATH="/dell"
$FTP_NEW_CSV_PATH = $FTP_Server + $NEW_CSV_PATH
$FTP_DEL_CSV_PATH = $FTP_Server + $DEL_CSV_PATH
$Local_DownLoad_Path="usersystem\scripts\afteradd\data\"
$Local_DownLoad_Drive="C:"

Function make_folder
{
##毎日AM 1:00実行
    Start-Transcript -Append ($sLogPath+"\make_homefolder_log-"+$sDate+".log")
    GET_CSV $NEW_CSV_PATH         ###FTPサーバからCSV取得処理 登録CSV
    Create_HomeDir
    DEL_CSV $NEW_CSV_PATH         ###FTPサーバのCSV削除処理   登録CSV 
    Stop-Transcript
}

Function move_folder
##毎日AM 3:00実行
{
    Start-Transcript -Append ($sLogPath+"\move_homefolder_log-"+$sDate+".log")
    GET_CSV $DEL_CSV_PATH         ###FTPサーバからCSV取得処理 削除CSV
    Move_HomeDir
    DEL_CSV $DEL_CSV_PATH         ###FTPサーバのCSV削除処理   削除CSV
    Stop-Transcript
}

Function Create_HomeDir
{
    ## CSV  一覧取得
    $csv_list = Get-ChildItem -Path  (Join-Path $sDataPath "useradd*.csv") -Exclude "*_old.csv","*_OLD.csv"
    foreach ($csvfile in $csv_list)
    {
    ## レコード  内容取得 (1行目 SKIP)
    ##    $csvdata = Get-Content  $csvfile.fullname |Select-Object -Skip 1 | ? {$_.trim() -ne "" } |ConvertFrom-Csv -Header $CSV_Header
        Write-Resultlog ($timestamp.Invoke()+$MSG_Process_Start+$csvfile.fullname)
        Get-Content  $csvfile.fullname |Select-Object -Skip 1 | ? {$_.trim() -ne "" } |ConvertFrom-Csv -Header adhomedir,uid,group,option04,option03 | ForEach -Begin {$CNT=1} {
            Write-Resultlog ("------------"+$CRLF+"        "+$timestamp.Invoke()+"("+$CNT.tostring()+") [Create_HomeDir] UID:"+$_.uid+" Home:"+$_.adhomedir+" GRP:"+$_.group +$CRLF+"        ------------")
    		if (Check-Account $_.uid) 
            {
                Add-wakaADGroup $_.uid $_.group                    ##AD Group 登録処理 
                Create_WindowsHomeDir $_.uid $_.group $_.adhomedir ## Windows Home (waka-nas01)作成
                Create_LinuxHomeDir  $_.uid $_.group $_.adhomedir ## Linux Home (waka-nfs01)作成  
            }
            $CNT++
        }
    ## CSV 処理済みファイル名変更
        Start-Sleep -Seconds 5
        Rename-File $csvfile.FullName  ($csvfile.Name.Replace(".csv","_old.csv"))
    }
}

Function Move_HomeDir
{
    ## CSV  一覧取得
    $csv_list = Get-ChildItem -Path  (Join-Path $sDataPath "userdel*.csv") -Exclude "*_old.csv","*_OLD.csv"
    foreach ($csvfile in $csv_list)
    {
    ## レコード  内容取得 (1行目 SKIP)
    ##    $csvdata = Get-Content  $csvfile.fullname |Select-Object -Skip 1 | ? {$_.trim() -ne "" } |ConvertFrom-Csv -Header $CSV_Header
        Write-Resultlog ($timestamp.Invoke()+$MSG_Process_Start+$csvfile.fullname)
        $Win_Target_Path=$Win_Move_Path + $timestamp.Invoke() + "\"
        $Lin_Target_Path=$Lin_Move_Path + $timestamp.Invoke() + "/"

        Get-Content  $csvfile.fullname |Select-Object -Skip 1 | ? {$_.trim() -ne "" } |ConvertFrom-Csv -Header adhomedir,uid,group,option04,option03 | ForEach -Begin {$CNT=1} {
            Write-Resultlog ("------------"+$CRLF+"        "+$timestamp.Invoke()+"("+$CNT.tostring()+") [Move_HomeDir] UID:"+$_.uid+" Home:"+$_.adhomedir+" GRP:"+$_.group +$CRLF+"        ------------")
    		if (Check-Account $_.uid)                            ## ユーザーがいるとき 
#    		if (!Check-Account $_.uid)                           ## ユーザーがいないとき 
            {
                Move_WindowsHomeDir $_.uid $_.adhomedir $Win_Target_Path   ## Windows Home (waka-nas01)退避
                Move_LinuxHomeDir  $_.uid $_.group $Lin_Target_Path        ## Linux Home (waka-nfs01)退避  
            }
            else 
            {
                 Write-SkipLog ($timestamp.Invoke()+$MSG_AccChk_EXIST+$account)
            }
            $CNT++
        }
    ## CSV 処理済みファイル名変更
        Start-Sleep -Seconds 5
        Rename-File $csvfile.FullName  ($csvfile.Name.Replace(".csv","_old.csv"))
    }
}

Function Main
{
#DBG用 PowerShell ISE 起動で、[F5]実行
##  実行後は、すべてコメントにしておくこと(間違えて、引数なしで、実行しても影響ないように)
###Add-wakaADGroup "tea-test3" "teachar"
#Create_LinuxHomeDir  "tea-test3" "teachar" 
#Create_WindowsHomeDir "tea-test3" "teachar" "\\waka-nascl01u1\tea\tea-test3"
#Create_WindowsHomeDir "csb-test3"  "gene" "\\waka-nascl01u1\stu\gene\csb-test3"
#Create_WindowsHomeDir "bio-test3" "bio"  "\\waka-nascl01u1\stu\bio\bio-test3"
# \\waka-nascl01u1\stu\master\master-test3,master-test3,master,master-test3,master
#\\waka-nascl01u1\stu\doctor\doctor-test3,doctor-test3,doctor,doctor-test3,doctor
#Create_WindowsHomeDir "doctor-test3" "doctor" "\\waka-nascl01u1\stu\doctor\doctor-test3"
#Create_LinuxHomeDir  "doctor-test3" "doctor"
#GET_CSV $NEW_CSV_PATH
#DEL_CSV $NEW_CSV_PATH 
#GET_CSV $DEL_CSV_PATH
#Create_HomeDir
##            $Win_Target_Path=$Win_Move_Path + $timestamp.Invoke()
##            $Lin_Target_Path=$Lin_Move_Path + $timestamp.Invoke()
#Move_WindowsHomeDir "tea-test3" "\\waka-nascl01u1\tea\tea-test3" $Win_Target_Path
#Move_LinuxHomeDir "tea-test3" "teachar"  $Lin_Target_Path
#Add_ADGroup_ADSI "info-test1" "StudentUsers"
}

Function GET_CSV
{
	[OutputType([String])]
	[CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True,Position = 0)]
        [String]$FTP_Path
    )
    Process 
    {
##        Set-FTPConnection -Server $FTP_Server -Credential $cred -Session $FTP_Session -KeepAlive  -UsePassive   ## FTP接続
        Try
        {
            Set-FTPConnection -Server $FTP_Server -Credential $cred -Session $FTP_Session -KeepAlive    ## FTP接続
            Write-Resultlog ($timestamp.Invoke()+$MSG_FTP_Conn+$FTP_Server)    
            $FTP_LIST=Get-FTPChildItem -Session $FTP_Session -Path $FTP_PATH
            $FTP_LIST |ForEach-Object {
                $Local_File = Join-Path $Local_Download_Drive $Local_Download_Path |Join-Path -ChildPath $_.Name
                if (-not (Test-path -Path $Local_File))
                {
                    $LOCAL_OLD_FILE = $LOCAL_FILE.Replace(".csv","_old.csv")
                    if (-not (Test-path -Path $LOCAL_OLD_FILE))
                    {
                        Get-FTPItem -Session $FTP_Session -Path $_.FullName -LocalPath $Local_File
                        Write-ResultLog ($timestamp.Invoke()+$MSG_GETCSV_CSV+$LOCAL_FILE)
                    }
                    else
                    {
                        Write-SkipLog ($timestamp.Invoke()+$MSG_GETCSV_OLD_EXIST+$LOCAL_OLD_FILE)
                    }    
                }
                else
                {
                    Write-SkipLog ($timestamp.Invoke()+$MSG_GETCSV_CSV_EXIST+$LOCAL_FILE)
                } 
            }
        }
        Catch
        {
            Write-ErrorLog ($timestamp.Invoke()+$EMSG_FTP_Conn+$FTP_Server)
            Write-ErrorLog ("[詳細]:"+$Error[0].toString())
        }
    }
}

Function DEL_CSV
{
	[OutputType([String])]
	[CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True,Position = 0)]
        [String]$FTP_Path
    )
    Process 
    {
        Try
        {
            Set-FTPConnection -Server $FTP_Server -Credential $cred -Session $FTP_Session -KeepAlive  -UsePassive
            Write-Resultlog ($timestamp.Invoke()+$MSG_FTP_Conn+$FTP_Server)    
            $FTP_LIST=Get-FTPChildItem -Session $FTP_Session -Path $FTP_PATH
            $FTP_LIST |ForEach-Object {
                $Local_File = Join-Path $Local_Download_Drive $Local_Download_Path |Join-Path -ChildPath $_.Name
                if (-not (Test-path -Path $Local_File))
                {
                    $LOCAL_OLD_FILE = $LOCAL_FILE.Replace(".csv","_old.csv")
                    if (Test-path -Path $LOCAL_OLD_FILE)
                    {
                        Remove-FTPItem -Session $FTP_Session -Path ($FTP_PATH+"/"+$_.Name)
                        Write-ResultLog ($timestamp.Invoke()+$MSG_DELCSV_CSV+$_.FullName)
                    }
                    else
                    {
                        Write-SkipLog ($timestamp.Invoke()+$MSG_DELCSV_OLD_NOT_EXIST+ $LOCAL_OLD_FILE)
                    }    
                }
                else
                {
                    Write-SkipLog ($timestamp.Invoke()+$MSG_DELCSV_CSV_EXIST+$Local_File)
                } 
            }
        }    
        Catch
        {
            Write-ErrorLog ($timestamp.Invoke()+$EMSG_FTP_Conn+$FTP_Server)
            Write-ErrorLog ("[詳細]:"+$Error[0].toString())
        }
    }
}
##
## ADアカウントチェック処理 
##
Function Check-Account 
{
	[OutputType([String])]
	[CmdletBinding()]
	Param
    (
        [Parameter(Mandatory=$True,Position = 0)]
        [String]$Account
    )

    Begin 
    {
        [int]$Private:SkipCnt=0
    }
	Process 
    {
		$userFilterString = "samAccountName -eq `"" + $Account + "`""
        Try 
        {
            $rt = Get-ADUser -Filter $userFilterString
    		if ($rt -eq $null)                                               ## ADにアカウントがない場合
            {
                Write-SkipLog ($timestamp.Invoke()+$EMSG_AccChk_NOTEXIST+$account)
                ++$SkipCnt
            }
        }
        Catch
        {
            Write-ErrorLog ("[詳細]:"+$Error[0].toString())
        }
        return $rt
	}
}

Function Add-wakaADGroup 
{
    [CmdletBinding()]
	Param (
			[string]$username=$(Throw "Error: Please enter a username!"),
            [string]$groupname
		)
	Process
	{
		if (Check-Account $username) 
        {
            if ($groupname -eq "teachar")
            {
                $grpTBL = @("TeacherUsers","PrintAdmins","linux_teachers")              ##教員用ADグループ    
                $PGroupName = "linux_teachers"
            }
            elseif ($groupname -eq "doctor")
            {
                $grpTBL = @("StudentUsers","linux_doctors","doctorGroup")               ##学生用(Doctor)ADグループ  
                $PGroupName = "linux_doctors"
            }
            elseif ($groupname -eq "master")
            {
                $grpTBL = @("StudentUsers","linux_masters","masterGroup")               ##学生用(Doctor)ADグループ  
                $PGroupName = "linux_masters"
            }
            else
            {
                $grpTBL = @("StudentUsers",("linux_"+$groupname),($groupname+"Group"))  ##学生用ADグループ  
                $PGroupName = ("linux_"+$groupname)
            }
            ## ADグループ登録処理
            ForEach ($ggg in $grpTBL) {
                Try
                {
                    if ($ggg -eq "StudentUsers")
                    {          
                        # StudentUsersのメンバー数超過対応 
                        $GroupDN=$(Get-ADGroup -Identity $ggg).DistinguishedName
                        $RT=([ADSIsearcher]"(&(objectclass=user)(sAMAccountName=$username)(memberof=$GroupDN))").findall() |Select Path  ##ADグループにアカウントが存在するか
                        if ($RT.length -eq 0)                                                                                            ##存在しないときADグループに登録   
                        {
                    	    $connection = "LDAP://$GroupDN"
                            $UserDN=$(Get-ADUser -Identity $username).DistinguishedName
                            $User = "LDAP://$UserDN"
                        	$Group = [adsi]"$connection"
                        	$Group.Add($User)
                            $Group=""
                            Write-Resultlog ($timestamp.Invoke()+$MSG_ADD_ADGroup+"User:"+$username+" ADGroup:"+$ggg)
                        }
                        else
                        {
                            Write-SkipLog ($timestamp.Invoke()+$MSG_ADD_ADGroup_SKIP+"User:"+$username+" ADGroup:"+$ggg)
                        }
                    }
                    else
                    {
                        $rt = Get-ADGroupMember -Identity $ggg |Where { $_.SamAccountName -eq $username }    ##ADグループにアカウントが存在するか
                        if ($rt -eq $null)
                        {
                            Add-ADGroupMember -Identity $ggg  -Member $username                  ##存在しないときADグループに登録
                            Write-Resultlog ($timestamp.Invoke()+$MSG_ADD_ADGroup+"User:"+$username+" ADGroup:"+$ggg)
                        }
                        else
                        {
                            Write-SkipLog ($timestamp.Invoke()+$MSG_ADD_ADGroup_SKIP+"User:"+$username+" ADGroup:"+$ggg)
                        }
                    }
                }
                Catch
                {
                    Write-ErrorLog ($timestamp.Invoke()+$EMSG_ADGroup+"User:"+$username+" ADGroup:"+$ggg)
                    Write-ErrorLog ("[詳細]:"+$Error[0].toString())                    
                }
            }
            ## AD プライマリグループ登録処理
            $UserDistinguishedName = (Get-ADUser -Identity $username -ErrorAction Stop).DistinguishedName
            $rt = Get-ADGroupMember -Identity $PGroupName |Where { $_.SamAccountName -eq $username }
            if ($rt -ne $null)
            {
            ## 登録するADグループのPrimaryGroupTokenを取得    
                $PrimaryGroupID = (Get-ADGroup -Identity $PGroupName  -Properties PrimaryGroupToken  -ErrorAction Stop).PrimaryGroupToken
                Try
                {
            ## 登録するアカウントのPrimaryGroupの設定    
    		        Set-ADObject -Identity "$UserDistinguishedName" -replace @{PrimaryGroupID=$PrimaryGroupID}
                    Write-Resultlog ($timestamp.Invoke()+$MSG_Set_PrimaryGrp+"User:"+$username+" PrimaryGroup:"+$PGroupName)
                }
                Catch
                {
                    Write-ErrorLog ($timestamp.Invoke()+$EMSG_Set_PrimaryGrp_Error+"User:"+$username+" PrimaryGroup:"+$PGroupName+" PrimaryGroupID:"+$PrimaryGroupID)
                    Write-ErrorLog ("[詳細]:"+$Error[0].toString())
                    }
            }
            else
            {
                Write-ErrorLog ($timestamp.Invoke()+$EMSG_PrimaryGrp_Error+"User:"+$username+" PrimaryGroup:"+$PGroupName+" PrimaryGroupID:"+$PrimaryGroupID)
                Write-ErrorLog ("[詳細]:"+$Error[0].toString())
            }    
		}
	}
}
Function Add_ADGroup_ADSI
{
    [CmdletBinding()]
    Param
    (
        [string]$UserName_adsi,
        [string]$GroupName_adsi
    )
    Process
    {
                    $GroupDN=$(Get-ADGroup -Identity $GroupName_adsi).DistinguishedName
                    $RT=([ADSIsearcher]"(&(objectclass=user)(sAMAccountName=$UserName_adsi)(memberof=$GroupDN))").findall() |select Path
                    if ($RT.length -eq 0) 
                    {
                	    $connection = "LDAP://$GroupDN"
                        $UserDN=$(Get-ADUser -Identity $UserName_adsi).DistinguishedName
                        $User = "LDAP://$UserDN"
                    	$Group = [adsi]"$connection"
                    	$Group.Add($User) 
                        Write-Resultlog ($timestamp.Invoke()+$MSG_ADD_ADGroup+"User:"+$username_adsi+" ADGroup:"+$groupName_adsi)
                    }
                    else
                    {
                        Write-SkipLog ($timestamp.Invoke()+$MSG_ADD_ADGroup_SKIP+"User:"+$username_adsi+" ADGroup:"+$groupName_adsi)

                    }
    }
}

#========================================================
# File Server Function 
#========================================================
Function Create_WindowsHomeDir 
{
    [CmdletBinding()]
	Param (
			[string]$username=$(Throw "Error: Please enter a username!"),
			[string]$groupname="Domain Users",
			[string]$ADHomeDir
		)
    Begin
    {
        $PSSession = New-PSSession $WINFS -Credential $WinCredential  
    }
	Process
	{
        try
        {
            $HomeDirPath = $ADHomeDir.Replace($target,$replace)
            $HomeDirPath_PUB = $HomeDirPath.TrimEnd('\')+"\public_html"
            $HomeDirPath_PRI = $HomeDirPath.TrimEnd('\')+"\private_html"
            $ADHomeDir.Replace($target,$replace)
            $DOMUserName = $MYDom+'\'+$username
###            echo $groupname
            if ($groupname -eq "teachar")
            {
            ##教員用 Windows HomeDir作成処理
				$RT=Invoke-Command -Session $PSSession -ScriptBlock {Test-Path $args[0]} -ArgumentList $HomeDirPath    ###ディレクトリ存在Check
				if (!$RT) {                                                                                            ### ないとき
					Invoke-Command -Session $PSSession -ScriptBlock {mkdir $args[0]} -ArgumentList $HomeDirPath
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_Create+$HomeDirPath)
					Invoke-Command -Session $PSSession -ScriptBlock {mkdir $args[0]} -ArgumentList $HomeDirPath_PUB
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_public+$HomeDirPath_PUB)
					Invoke-Command -Session $PSSession -ScriptBlock {mkdir $args[0]} -ArgumentList $HomeDirPath_PRI
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_private+$HomeDirPath_PRI)
					Invoke-Command -Session $PSSession -ScriptBlock {powershell c:\nti\grant_icacls_f.ps1 $args[0] $args[1]} -ArgumentList $HomeDirPath,$DomUsername
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_grant+$HomeDirPath)
					Invoke-Command -Session $PSSession -ScriptBlock {icacls $args[0] /setowner $args[1] /C /T } -ArgumentList $HomeDirPath,$DomUsername
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_setown+$HomeDirPath)
				}
				else 
				{
		            Write-SkipLog ($timestamp.Invoke()+$MSG_HomeDir_Skip+$HomeDirPath)
				}
            }
            else
            {
            ##学生用 Windows HomeDir作成処理
				$RT=Invoke-Command -Session $PSSession -ScriptBlock {Test-Path $args[0]} -ArgumentList $HomeDirPath    ###ディレクトリ存在Check
				if (!$RT) {                                                                                            ### ないとき
					$HomeDefaultPath = (Split-Path $HomeDirPath -Parent)+"\home_default\"
					if ($groupname -eq "doctor")
					{
						$DOMGroupName = $MYDom+"\linux_doctors"
					}
					elseif ($groupname -eq "master")
					{
						$DOMGroupName = $MYDom+"\linux_masters"
					}
					else
					{
						$DOMGroupName = $MYDom+'\linux_'+$groupname
					}
					Invoke-Command -Session $PSSession -ScriptBlock {mkdir $args[0]} -ArgumentList $HomeDirPath
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_Create+$HomeDirPath)
					Invoke-Command -Session $PSSession -ScriptBlock {robocopy.exe /S /E /W:1 /R:1  $args[0]  $args[1]} -ArgumentList $HomeDefaultPath,$HomeDirPath
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_robocopy+$HomeDirPath)
					Invoke-Command -Session $PSSession -ScriptBlock {mkdir $args[0]} -ArgumentList $HomeDirPath_PRI
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_private+$HomeDirPath_PRI)
					Invoke-Command -Session $PSSession -ScriptBlock {powershell c:\nti\grant_icacls_f.ps1 $args[0] $args[1]} -ArgumentList $HomeDirPath,$DomUsername
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_grant+$HomeDirPath+" "+$DomUsername+":フルコントロール")
					Invoke-Command -Session $PSSession -ScriptBlock {powershell c:\nti\grant_icacls_rx.ps1 $args[0] $args[1]} -ArgumentList $HomeDirPath,$DomGroupName
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_grant+$HomeDirPath+" "+$DomGroupName+":読み取り/実行")
					Invoke-Command -Session $PSSession -ScriptBlock {icacls $args[0] /setowner $args[1] /C /T } -ArgumentList $HomeDirPath,$DomUsername
					Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_setown+$HomeDirPath)
				}
				else 
				{
		            Write-SkipLog ($timestamp.Invoke()+$MSG_HomeDir_Skip+$HomeDirPath)				
				}
            }
        }
        catch
        {
            Write-ErrorLog ($timestamp.Invoke()+$EMSG_HomeDir_Create+$HomeDirPath)
            Write-ErrorLog ("[詳細]:"+$Error[0].toString())
        }
    } 
    End
    {
        Remove-PSSession $PSSession
    }
}

Function Create_LinuxHomeDir 
{
	Param (
			[string]$username=$(Throw "Error: Please enter a username!"),
			[string]$groupname,
			[string]$HomeDirPath="Domain Users"
		)
    Begin {
        $RT=New-SshSession -ComputerName $SSH_Server -Username $SSH_User -Password $SSH_Pass -Port $SSH_Port
        Write-Resultlog $RT.replace($CR,$CRLF)
    }
	Process
	{
        Try
        {
            $RT=Invoke-SSHCommand  -ComputerName $SSH_Server -Command "/usr/local/bin/MakeHomeDir.sh $UserName $groupname"
            Write-Resultlog $RT.replace($CR,$CRLF)
        }
        catch
        {
            Write-ErrorLog ($timestamp.Invoke()+"[詳細]"+$error[0].ToString())
        }
    }
    End {
        $RT=Remove-SshSession -ComputerName $SSH_Server
        Write-Resultlog $RT.replace($CR,$CRLF)
    }
}

Function Move_WindowsHomeDir 
{
    [CmdletBinding()]
	Param (
			[string]$username=$(Throw "Error: Please enter a username!"),
			[string]$ADHomeDir,
            [string]$TargetDir
		)
    Begin
    {
        $PSSession = New-PSSession $WINFS -Credential $WinCredential  
    }
	Process
	{
        try
        {
            $HomeDirPath = $ADHomeDir.Replace($target,$replace)
            $ADHomeDir.Replace($target,$replace)
            $DOMUserName = $MYDom+'\'+$username
###            echo $groupname
			$RT=Invoke-Command -Session $PSSession -ScriptBlock {Test-Path $args[0]} -ArgumentList $HomeDirPath    ###Homeディレクトリ存在Check
			if ($RT) {                                                                                             ###あるとき
    			$RT=Invoke-Command -Session $PSSession -ScriptBlock {Test-Path $args[0]} -ArgumentList $TargetDir  ###退避先ディレクトリ存在Check
                if (!$RT) {                                                                                        ###ないとき  
    				Invoke-Command -Session $PSSession -ScriptBlock {New-Item $args[0] -ItemType Directory } -ArgumentList $TargetDir
                }
				Invoke-Command -Session $PSSession -ScriptBlock {Move-Item $args[0] -Destination $args[1]} -ArgumentList $HomeDirPath,$TargetDir
				Write-Resultlog ($timestamp.Invoke()+$MSG_HomeDir_Move+$HomeDirPath+"->"+$TargetDir)
			}
			else 
			{
	            Write-SkipLog ($timestamp.Invoke()+$MSG_HomeDir_Move_Skip+$HomeDirPath)
			}
        }
        catch
        {
            Write-ErrorLog ($timestamp.Invoke()+$EMSG_HomeDir_Move+$HomeDirPath)
            Write-ErrorLog ("[詳細]:"+$Error[0].toString())
        }
    } 
    End
    {
        Remove-PSSession $PSSession
    }
}

Function Move_LinuxHomeDir 
{
	Param (
			[string]$username=$(Throw "Error: Please enter a username!"),
			[string]$groupname="Domain Users",
            [string]$TargetDir
		)
    Begin {
        $RT=New-SshSession -ComputerName $SSH_Server -Username $SSH_User -Password $SSH_Pass -Port $SSH_Port
        Write-Resultlog $RT.replace($CR,$CRLF)
    }
	Process
	{
        Try
        {
            $RT=Invoke-SSHCommand  -ComputerName $SSH_Server -Command "/usr/local/bin/MoveHomeDir.sh $UserName $groupname $TargetDir"
            Write-Resultlog $RT.replace($CR,$CRLF)
        }
        catch
        {
            Write-ErrorLog ($timestamp.Invoke()+"[詳細]"+$error[0].ToString())
        }
    }
    End {
        $RT=Remove-SshSession -ComputerName $SSH_Server
        Write-Resultlog $RT.replace($CR,$CRLF)
    }
}
Function Rename-File
{
	[OutputType([String])]
	[CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True,Position = 0)]
        [String]$FilePath,
        [Parameter(Mandatory=$True,Position = 1)]
        [String]$NewFileName
    )
    Process 
    {
        if(Test-Path -LiteralPath $FilePath -PathType Leaf)
        {
            $newFilePath = Join-Path -Path (Split-Path $FilePath -Parent) -ChildPath $NewFileName
            Move-Item -LiteralPath $FilePath -Destination $newFilePath
        }
        else 
        {
            Write-SkipLog $ERRMSG_RenFile_File_NOT_EXIST+$FilePath
        }
    }
}
<#
Function Move_Home
{
##MAIN
    $SUCMSG_START | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
    #バックアップ対象のフォルダがない場合は処理を停止
    if((Test-Path $target_dir) -eq $false)
    {
        $ERRMSG_FOLDER_EXIST | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
        exit 1
    }
    #退避先のユーザ種別フォルダがない場合は処理を停止
    if((Test-Path $bkup_user_type_dir) -eq $false)
    {
        $ERRMSG_BKUP_USER_FOLDER_EXIST | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
        exit 1
    }

    #退避先に同名のユーザフォルダが存在する場合は処理を停止
    if((Test-Path $bkup_target_dir) -eq $true)
    {
        $ERRMSG_BKUP_FOLDER_EXIST | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
        exit 1
}

#フォルダ退避処理
try{
  Move-Item $target_dir -destination $bkup_target_dir
}
catch{
  $ERRMSG_FOLDER_MOVE | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
  $error | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
  exit 1
}
$SUCMSG_FOLDER_MOVE | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE

#タイムスタンプを現在の時刻にする (Linux の touch 相当)
try{
  $(Get-Item $bkup_target_dir).LastWriteTime = Get-Date
}
catch{
  $ERRMSG_TIMESTAMP | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
  $error | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
  exit 1
}
$SUCMSG_TIMESTAMP | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
$SUCMSG_ALL | Out-File -Append -Encoding 'utf8' -FilePath $LOG_FILE
exit 0
}

Function Check-Path
{
    ForEach ($cpath in $args)
    {
        if (-not (Test-Path -Path $cpath))
        {
            Write-ErrorLog $ERRMSG_File_Not_EXIST$cpath
        }
    }    
}

Function Check-Exist-Path
{
    ForEach ($cpath in $args)
    {
        if (Test-Path -Path $cpath)
        {
            Write-ErrorLog $ERRMSG_File_Already_EXIST$cpath
        }
    }
}

Function FTP_Parts
{
 	[OutputType([String])]
	[CmdletBinding()]
    Param
    (
        $Parts = $null,
        $Separator = ''
    )
    Process 
    {
        [String]$s = ''
        $Parts | Skip-Null | ForEach-Object {
            $v = $_.ToString()
            if ($s -ne '')
           {
                if (-not ($s.EndsWith($Separator)))
                {
                    if (-not ($v.StartsWith($Separator)))
                    {
                        $s += $Separator
                    }
                    $s += $v
                }
                elseif ($v.StartsWith($Separator))
                {
                    $s += $v.SubString($Separator.Length)
                }
            }
            else
            {
                $s = $v
            }
        }
        $s
    }
}
#>
filter Skip-Null { $_|?{ $_ } }


#main
switch ($args[0])
{
    ##実行パラメータで、Function呼び出し
    "make_homefolder" { make_folder }
    "move_homefolder" { move_folder }
    default { main }
}
