[string]$BASEURL = "https://storage-dag.iijgio.com"
[string]$ACCESS_KEY = "G84OE1Q79MQ0R56IR738"  ### tomoya-ueda@iij.ad.jp
[string]$SECRET_KEY = "hHrBA7QosY/hGBm+xwZf+sIu1PwiuewjYi5906fn"
#[string]$ACCESS_KEY="4YJCTKUABAU246672888" ### mizutani@iij.ad.jp
#[string]$SECRET_KEY="3jBL3VZ7LYYUstFC2bxS1VlLeaUx9LSzv733urzG"
[string]$sig_date = get-date (get-date).AddHours(-9) -Format r 




[string]$http_verb = "GET"
#[string]$message="GET`n`n`n" + $sig_Date + "`n/"
[string]$message="GET`n`n`n" + $sig_Date + "`n/?space"

$hmacsha = New-Object System.Security.Cryptography.HMACSHA1
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($SECRET_KEY)
$SIGNATURE = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($message))
$SIGNATURE = [Convert]::ToBase64String($SIGNATURE)


[string]$authheader = "IIJGIO " + $ACCESS_KEY + ":" + $SIGNATURE

echo $authheader
$Headers = @{}
$Headers.Add('Date', $sig_date)
$headers.Add("Authorization",$authheader)
##$RET=Invoke-WebRequest -Uri $BASEURL -Headers $Headers
##$aa=([xml]$RET.Content).ListAllMyBucketsResult
##$aa.Owner.DisplayName
##$aa.Buckets.Bucket.Name

$URI=$BASEURL+"/?space"
$URI
$RET=Invoke-WebRequest -Uri $URI -Method Get -Headers $Headers
#$RET=Invoke-WebRequest -Uri $BASEURL -Method Get -Headers $Headers
$aa=([xml]$RET.Content).StorageSpaceInfo
$aa.ContractUsed
$aa.AccountUsed
exit
