### 環境変数

### 日付処理(先月の月末日の取得)
$LastMM=(get-date).AddMonths(-1).toString("MM")
$LastYY=(get-date).AddMonths(-1).toString("yyyy")
$LastYY2=(get-date).AddMonths(-1).toString("yy")
$LastDD=[DateTime]::ParseExact((get-date).toString("yyMM"),"yyMM",$null).AddDays(-1).toString("dd")

###$ZipPath     = "C:\work\"
#$ZipPath     = "C:\Users\Administrator\Desktop\"
$ZipPath     = "C:\Users\iijadmin\Desktop\"
$ZipFileName = "庁内配信ログ_" + $LastYY + $LastMM + ".zip"
$ZipFile     = $ZipPath + $ZipFileName
$LogPath     = "C:\Program Files (x86)\Wowza Media Systems\Wowza Streaming Engine 4.7.7\logs\"
$LogFileName = "wowzastreamingengine_access.*"
<#
### Zip ファイル作成
$fso = New-Object -ComObject Scripting.FileSystemObject
$zip = $fso.CreateTextFile($ZipFile, $true)
$zip.Write("PK")
$zip.Write([char]5)
$zip.Write([char]6)
for ($i = 1; $i -le 18; $i++){ $zip.Write([char]0) }
$zip.Close()
$sh = New-Object -ComObject Shell.Application
$zip = $sh.NameSpace($ZipFile)

### 圧縮処理
$LogFileList = $LogPath+$LogFileName+$LastYY+"-"+$LastMM+"*"
$LogFiles    = gci $LogFileList -name 
foreach ($LogFile in $LogFiles) {
  write-output("Zip... "+$LogFile);
  $zip.CopyHere($LogPath+$LogFile);

  Start-sleep -milliseconds 1000;
}

$LogPath_IIS     = "C:\inetpub\logs\LogFiles\W3SVC1\"
$LogFileList_IIS = $LogPath_IIS+"u_ex"+$LastYY2+$LastMM+"*"
$LogFiles_IIS    = gci $LogFileList_IIS -name 
foreach ($LogFile_IIS in $LogFiles_IIS) {
  write-output("Zip... "+$LogFile_IIS);
  $zip.CopyHere($LogPath_IIS+$LogFile_IIS);

  Start-sleep -milliseconds 1000;
}
#>

### 圧縮処理
$LogFileList = $LogPath+$LogFileName+$LastYY+"-"+$LastMM+"*"
Compress-Archive -Path $LogFileList -DestinationPath $ZipFile

