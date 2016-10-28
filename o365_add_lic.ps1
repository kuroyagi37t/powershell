###########################################
# This Script is for Office 365 User
# 
# Author      : t-yamauchi@iij.ad.jp
# Create Date : 2016/06/08
# Editor      : honma-s@iij.ad.jp
# Modify      : mizutani@iij.ad.jp
# Edit Date   : 2016/07/06
# Modify Date : 2016/07/20
# Modify Date : 2016/10/28  
# Test Date   : 
###########################################

#-----------------------------------------------
# Global宣言の変数

# ログファイル名作成
[string]$global:o365_connect_user="admin@ho0geho0ge.onmicrosoft.com"
[string]$global:o365_connect_pass="P@ssw0rd"
[string]$global:o365_license_sku=""
[string]$global:o365_lic_Student_OfficeProPlus="muimuni:OFFICESUBSCRIPTION_STUDENT"   ##学生用サブスクリプション Office Pro Plus Only   OU=Student
[string]$global:o365_lic_Student_ExchangeOnline="muimuni:STANDARDWOFFPACK_STUDENT"    ##学生用サブスクリプション Exchange Online Only   Not Used
[string]$global:o365_lic_Faculty_OfficeProPlus="muimuni:OFFICESUBSCRIPTION_FACULTY"   ##教員用サブスクリプション Office Pro Plus Only   OU=Teacher,Staff 
[string]$global:o365_lic_Faculty_ExchangeOnline="muimuni:STANDARDWOFFPACK_FACULTY"    ##教員用サブスクリプション Exchange Online Only   OU=Medical,Other,Teacher,Staff
<# Office 365 Education SKU
    https://blogs.technet.microsoft.com/treycarlee/2014/12/09/powershell-licensing-skus-in-office-365/
STANDARDPACK_STUDENT	    Microsoft Office 365 (Plan A1) for Students
STANDARDPACK_FACULTY	    Microsoft Office 365 (Plan A1) for Faculty
STANDARDWOFFPACK_FACULTY	Office 365 Education E1 for Faculty
STANDARDWOFFPACK_STUDENT	Microsoft Office 365 (Plan A2) for Students
STANDARDWOFFPACK_IW_STUDENT	Office 365 Education for Students
STANDARDWOFFPACK_IW_FACULTY	Office 365 Education for Faculty
EOP_ENTERPRISE_FACULTY	    Exchange Online Protection for Faculty
EXCHANGESTANDARD_STUDENT	Exchange Online (Plan 1) for Students
OFFICESUBSCRIPTION_STUDENT	Office ProPlus Student Benefit
#>

# ログファイル名作成
$global:LogDate = Get-Date -Format yyyyMMddHHmmss;

# トランスクリプトログファイルパス
Start-Transcript -Path "C:\Scripts\licenseadd\Logs\Transcript_$($LogDate).log"
$global:StartTranscript = $true

# 詳細ログファイルパス
if(!$LogFile)
{
    $global:LogFile = "C:\Scripts\licenseadd\logs\ScriptLog_$($LogDate).log"
}

# イベントログソース名
if(!$EvevtSource)
{
    $global:EvevtSource = "IIJ_SCRIPT"
}

# MSOnline接続確認Boolean
if(!$MSOnlineConnect)
{
    $global:MSOnlineConnect = $false
}

# Office365接続用クレデンシャル
if(!$Credential)
{
    $sec_password = ConvertTo-SecureString $o365_connect_pass -AsPlainText -Force
    $global:Credential = New-Object System.Management.Automation.PSCredential $o365_connect_user,$sec_password
}

# リトライカウンタ
$global:RetryCount = 0

Write-Host "LogFile -> $($LogFile)"


#-----------------------------------------------
# Logメソッド

# エラーメッセージログ吐き出し用メソッド
function Message-ErrorLogFile ([String]$Message = "")
{
    if($Message -ne "")
    {
        "Time : $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")" | Out-File -encoding UTF8 -FilePath $LogFile -Append
        "ErrorMessage : $($Message)" | Out-File -encoding UTF8 -FilePath $LogFile -Append
        Write-Host $Message
    }
    $Error | Out-File -encoding UTF8 -FilePath $LogFile -Append
    $Error.Clear()
}

# インフォメッセージログ吐き出し用メソッド
function Message-LogFile ([String]$Message = "")
{
    if($Message -ne "")
    {
        "Time : $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")" | Out-File -encoding UTF8 -FilePath $LogFile -Append
        "InfoMessage : $($Message)" | Out-File -encoding UTF8 -FilePath $LogFile -Append
    }
}

# メッセージボックスポップアップ用メソッド
function Message-Popup ([String]$Message = "",[String]$Title = "ScriptMessage")
{
    Add-Type -Assembly System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title)
}

# イベントログ発行用メソッド
function Message-EventLog ([String]$Message, [String]$Type = "Information", [int]$ID = 0, [String]$Source = $EvevtSource)
{
    if ([System.Diagnostics.EventLog]::SourceExists($Source) -eq $false)
    {
        New-EventLog -LogName Application -Source $Source
    }
    Write-EventLog -LogName Application -EntryType $Type -Source $Source -EventId $ID -Message $Message
}

#-----------------------------------------------
# Office365接続メソッド

# MSOnlineに繋がる
function LoginTo-MSOnline () 
{
    $Error.Clear()
    Message-LogFile "MS Onlineに接続します。"
    Import-Module MSOnline
    Connect-MsolService -Credential $Credential
    if($Error.Count -gt 0)
    {
        Message-ErrorLogFile "MS Onlineへの接続に失敗しました。 ($($LogFile))."
        Message-EventLog -Message "MS Onlineへの接続に失敗しました。 ($($LogFile))." -Type "Error" -ID 50
        exit
    }
    $global:MSOnlineConnect = $True
}

#-----------------------------------------------
# Office365 License 登録用メソッド

function Add-O365UserLicense($UserID)
{
    $Error.Clear()
    If(!$MSOnlineConnect)
    {
        LoginTo-MSOnline
    }

    # 利用地域を日本に設定し、ライセンスを付与する
    Set-MsolUser -UserPrincipalName $UserID -UsageLocation JP
    $UserDN=$(Get-ADUser -Filter { UserPrincipalName -eq $UserID }).DistinguishedName
    switch -Wildcard ($UserDN)
    {
        "*OU=[M|m]edical*"
        {
            Set-O365UserLicense $UserID $o365_lic_Faculty_ExchangeOnline       ##Exchange Online 
        }   
        "*OU=[O|o]ther*"
        {
            Set-O365UserLicense $UserID $o365_lic_Faculty_ExchangeOnline       ##Exchange Online 
        } 
        "*OU=[S|s]tudent*"
        {
            Set-O365UserLicense $UserID $o365_lic_Student_OfficeProPlus        ##Office ProPlus
        }
        default
        {
            Set-O365UserLicense $UserID $o365_lic_Faculty_OfficeProPlus        ##Office ProPlus
            Set-O365UserLicense $UserID $o365_lic_Faculty_ExchangeOnline       ##Exchange Online
        }
    }
}

function Set-O365UserLicense([String]$UserID,[String]$SKU)
{
    if ($SKU -ne "")
    {
        Set-MsolUserLicense -UserPrincipalName $UserID -addlicenses $SKU
        if($Error.Count -gt 0)
        {
            Message-ErrorLogFile "$($UserID)へのライセンス付与に失敗しました。 ($($LogFile))."
            Message-EventLog -Message "$($UserID)へのライセンス付与に失敗しました。" -Type "Error"　-ID 50
        }
    }
}

