[string]$BaseHost="storage-dag.iijgio.com"
[string]$BASEURL="https://"+$BaseHost
##[string]$ACCESS_KEY="4YJCTKUABAU246672888"             ###tomoya-ueda@iij.ad.jp
##[string]$SECRET_KEY="3jBL3VZ7LYYUstFC2bxS1VlLeaUx9LSzv733urzG"
##[string]$ACCESS_KEY="G84OE1Q79MQ0R56IR738"                         ###mizutani@iij.ad.jp
##[string]$SECRET_KEY="hHrBA7QosY/hGBm+xwZf+sIu1PwiuewjYi5906fn"
##[string]$ACCESS_KEY="0LOZB7XJ8FW3TOSJXZS1"                         ###mizutani@iij.ad.jp
##[string]$SECRET_KEY="rlA5Z3pahoKCgK6ZLGRVgMHID3zmYHqcKiBn2bT5"

Function Convert-Size {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][double]$Value,
        [int]$Precision = 1
    )
    Process {
        Switch ($Value) {
             { $_ -gt 1PB } {$Value = $Value/1PB;[string]$UNIT="PB";break}
             { $_ -gt 1TB } {$Value = $Value/1TB;[string]$UNIT="TB";break}
             { $_ -gt 1GB } {$Value = $Value/1GB;[string]$UNIT="GB";break}
             { $_ -gt 1MB } {$Value = $Value/1MB;[string]$UNIT="MB";break}
             { $_ -gt 1KB } {$Value = $Value/1KB;[string]$UNIT="KB";break}
             default {[string]$UNIT="Byte"}
        }
        return ([string][Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero) + $UNIT)
    }
}

Function Set-Signature
{
    [CmdletBinding()]
	Param (
			[Parameter(Mandatory=$True)][string]$Str,
            [Parameter(Mandatory=$True)][string]$Sign_Date,
            [Parameter(Mandatory=$True)][string]$Access_Key,
            [Parameter(Mandatory=$True)][string]$Secret_Key
	)
	Process {
        $hmacsha = New-Object System.Security.Cryptography.HMACSHA1
        $hmacsha.Key = [Text.Encoding]::ASCII.GetBytes($Secret_Key)
        $Signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($str))
        $Signature = [Convert]::ToBase64String($Signature)
        [string]$AuthHeader = "IIJGIO " + $Access_Key + ":" + $Signature 
        $SignHeader = @{}
        $SignHeader.Add('Date',$Sign_date)
        $SignHeader.Add('Authorization',$AuthHeader)
        $SignHeader
    }
}

Function Get-SpaceInfo
{
    [CmdletBinding()]
	Param (
            [Parameter(Mandatory=$True)][string]$Access_Key,
            [Parameter(Mandatory=$True)][string]$Secret_Key
	)
	Process {
        [string]$Sign_date = get-date (get-date).AddHours(-9) -Format r 
        [string]$str="GET`n`n`n" + $Sign_Date + "`n/?space"
        $Header = Set-Signature -Str $str -Sign_Date $Sign_date -Access_Key $ACCESS_KEY -Secret_Key $SECRET_KEY
        $RT = Invoke-WebRequest -Uri ($BASEURL + "/?space") -Method Get -Headers $Header
        $Content=([xml]$RT.Content).StorageSpaceInfo
        Convert-Size -Value $Content.ContractUsed
        Convert-Size -Value $Content.AccountUsed
    }
}

Function Get-BucketsInfo
{
    [CmdletBinding()]
	Param (
            [Parameter(Mandatory=$True)][string]$Access_Key,
            [Parameter(Mandatory=$True)][string]$Secret_Key
	)
	Process {
        [string]$Sign_date = get-date (get-date).AddHours(-9) -Format r 
        [string]$str="GET`n`n`n" + $Sign_Date + "`n/"
        $Header = Set-Signature -Str $str -Sign_Date $Sign_date -Access_Key $ACCESS_KEY -Secret_Key $SECRET_KEY
        $RT = Invoke-WebRequest -Uri $BASEURL -Method Get -Headers $Header
        $Content=([xml]$RT.Content).ListAllMyBucketsResult
        $Content.Owner.DisplayName
        foreach($Bucket in $Content.Buckets.Bucket) {
            $Bucket.Name
            if ((get-date $Bucket.CreationDate) -gt (get-date).addmonths(-2)) {echo -n "***"} 
            (get-date $Bucket.CreationDate).ToString("yyyy/MM/dd HH:mm:ss")
        }
    }
}

Function Get-CSV
{
    $incsv=@{}
    $incsv=Import-csv .\dag_acc.csv
    foreach ($i in $incsv) {
        Get-BucketsInfo -Access_Key $i.ACCESS_KEY -Secret_Key $i.SECRET_KEY
        Get-SpaceInfo -Access_Key $i.ACCESS_KEY -Secret_Key $i.SECRET_KEY
    }
}
Get-CSV
exit

[string]$Sign_date = get-date (get-date).AddHours(-9) -Format r 
[string]$str="GET`n`n`n" + $Sign_Date + "`n/"
$Header = Set-Signature -Str $str -Sign_Date $Sign_date -Access_Key $ACCESS_KEY -Secret_Key $SECRET_KEY
$RT = Invoke-WebRequest -Uri $BASEURL -Method Get -Headers $Header
#$rt
#[xml]$RT.Content
$Content=([xml]$RT.Content).ListAllMyBucketsResult
#$Content
$Content.Owner.DisplayName
$Content.Buckets.Bucket
#[string]$CreationDate=$Content.Buckets.Bucket.CreationDate
#$CreationDate
#[string]$aaa=(get-date $CreationDate).ToString("yyyy/MM/dd HH:mm:ss")
#$aaa
#[string]$CreationDate=$Content.Buckets.Bucket.CreationDate.Substring(0,19).Replace('T','')
#$CreationDate
#[DateTime]::ParseExact($CreationDate,"yyyy-MM-ddHH:mm:ss",$null).addhours(9)
##[DateTime]::ParseExact($Content.Buckets.Bucket.CreationDate.Substring(0,10).Replace('T',' '),"yyyy-MM-dd", $null)

(get-date $Content.Buckets.Bucket.CreationDate).ToString("yyyy/MM/dd HH:mm:ss")

exit

foreach ( $bucket in $Content.Buckets.Bucket.Name) {
    [string]$str="GET /?space" +"`n`n`n" + $sig_Date + "`n/"

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA1
    $hmacsha.Key = [Text.Encoding]::ASCII.GetBytes($SECRET_KEY)
    $SIGNATURE = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($str))
    $SIGNATURE = [Convert]::ToBase64String($SIGNATURE)

    [string]$AuthHeader = "IIJGIO " + $ACCESS_KEY + ":" + $SIGNATURE
    $Header = @{}
    $Header.Add('Date',$sig_date)
    $Header.Add('Authorization',$AuthHeader)

    $RT2 = Invoke-WebRequest -Uri $BASEURL -Headers $Header
     $RT2
   $bucket
}

#5$Content.Buckets.Bucket.CreationDate


Function Convert-DateTimeToUnixTime($dateTime){
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    [Int]($dateTime-$origin).TotalSeconds
}
Function canonicalized_resource([string]$force_path_style){
    [string]$result=""
    if ($bucket -ne '') {
        $result = "/"
        $result += $bucket + "/"
    } elseif ($resouce -ne "/" ){
        $result = $resouce
    }
    $result += "?"
    retrun $result 
}
Function signature([string]$secret,[string]$A) {
    [string]$http_verb = "GET"
    [string]$content_md5 = "`n"
    [string]$content_type = $signature_content_type
    [string]$sig_date = get-date (get-date).AddHours(-9) -Format r 
    [string]$canonicalized_iijgio_headers = ""
    [string]$to_sign = $http_verb + $content_md5 + $content_type + $sig_date + $canonicalized_iijgio_headers + $canonicalized_resource
    $sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA1")
    $sha.Key = [System.Text.Encoding]::UTF8.Getbytes($secret)
    $sign = [Convert]::Tobase64String($sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${to_sign})))
}

#[string]$secret=$SECKEY
##$sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA1")
#$sha.Key = [System.Text.Encoding]::UTF8.Getbytes($secret)
#$digest = [string]$sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${str}))
#$sign = [Convert]::Tobase64String($digest)
#$sign = $($sign.substring(0,$sign.Length -1) + "%3D")
#echo $("str:" + $str)
#echo $("digst:" + $digest)
#echo $("sign:" + $sign)

##$bytes= [System.Text.Encoding]::UTF8.GetBytes($userpass)
##$encodedlogin=[Convert]::ToBase64String($bytes)
#$URI=$($URI_Base + "?Expires=" + $epocDate + "&IIJGIOAccessKeyId=" + $ACCKEY + "&Signature=" + $sign)
#echo $("URI:" + $URI)
#Invoke-WebRequest -Uri $URI

# Success
#$Headers = @{}
#$Headers.Add('Authorization', "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request SignedHeaders=host;range;x-amz-date, Signature=fe5f80f77d5fa3beca038a248ff027d0445342fe2855ddc963176630326f1024")
#Invoke-WebRequest -Uri www.google.com -Headers $Headers
