# FTP接続に必要な情報を設定
$user     = 'xxxx';
$pass     = 'xxxxx';
$hostName = 'xxxxxst.cloudapp.azure.com';

# ファイルの一覧を取得する対象のディレクトリのパス
# （最後はスラッシュで終わらせる）
$targetDirectoryPath = '/home/iijadmin/add/';

# FTP接続用のURL
$ftpUrl = 'ftp://' + $hostName + $targetDirectoryPath;

# 接続
$webRequest = [System.Net.WebRequest]::Create($ftpUrl);
$webRequest.Credentials = New-Object System.Net.NetworkCredential($user, $pass);

# 実行する処理を設定
$webRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory;

try
{
    # リクエスト実行
    $response = $webRequest.GetResponse();
    $ftpDataStream = $response.GetResponseStream();
    $streamReader = New-Object System.IO.StreamReader($ftpDataStream);

    # ファイル名（文字列）のリストを取得
    $list = $streamReader.ReadToEnd();

    foreach($item in $list)
    {
        # ファイル名を出力
        Write-Host $item;
    }

    $streamReader.Close();
}
catch
{
    Write-Host 'エラーが発生しました';
    Write-Host $_;
}



------------
function Delete-File($Source,$Target,$UserName,$Password)
{

    $ftprequest = [System.Net.FtpWebRequest]::create($Source)
    $ftprequest.Credentials =  New-Object System.Net.NetworkCredential($UserName,$Password)

    if(Test-Path $Source)
    {
       "ABCDEF File exists on ftp server."
       $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
       $ftprequest.GetResponse()

       "ABCDEF File deleted."
    }

}

function Get-FTPFile ($Source,$Target,$UserName,$Password)  
{  

    # Create a FTPWebRequest object to handle the connection to the ftp server  
    $ftprequest = [System.Net.FtpWebRequest]::create($Source)  

    # set the request's network credentials for an authenticated connection  
    $ftprequest.Credentials =  
    New-Object System.Net.NetworkCredential($username,$password)  
    if(Test-Path $targetpath)
    {
        "ABCDEF File exists"
    }
    else 
    { 
        "ABCDEF File downloaded"
         $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile  

         $ftprequest.UseBinary = $true  
         $ftprequest.KeepAlive = $false  
         Delete-File $sourceuri $targetpath $user $pass
    }

    # send the ftp request to the server  
    $ftpresponse = $ftprequest.GetResponse()  

    # get a download stream from the server response  
    $responsestream = $ftpresponse.GetResponseStream()  

    # create the target file on the local system and the download buffer  
    $targetfile = New-Object IO.FileStream ($Target,[IO.FileMode]::Create)  
    [byte[]]$readbuffer = New-Object byte[] 1024  

    # loop through the download stream and send the data to the target 
    file  
    do{  
          $readlength = $responsestream.Read($readbuffer,0,1024)  
          $targetfile.Write($readbuffer,0,$readlength)  
    }  
    while ($readlength -ne 0)  

    $targetfile.close()  
}  
