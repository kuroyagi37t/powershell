function global:Write-Log{
	param([String]$msg)
	$write_msg = ((Get-Date).ToString() + "`t" + $msg.ToString())
	Write-Host $write_msg -ForeGroundColor Green
	Add-Content -Path $sLogPath\ScriptLog-$sDate.log -Value $write_msg
}

function global:Write-Resultlog{
	param([String]$msg)
	$write_msg = ("`t" + $msg.ToString())
	Write-Host $write_msg -ForeGroundColor Yellow
	Add-Content -Path $sLogPath\ScriptLog-$sDate.log -Value $write_msg
}

function global:Write-SkipLog{
	param([String]$msg)
	$write_msg = ("`t" + "[SKIP] " + $msg.ToString())
	Write-Host $write_msg -ForeGroundColor White
	Add-Content -Path $sLogPath\ScriptLog-$sDate.log -Value $write_msg
}

function global:Write-ErrorLog{
	param([String]$msg)
	$write_msg = ("`t" + "[ERROR] " + $msg)
	$globalErrorFlag = 1
	Write-Host $write_msg -ForeGroundColor Red
	Add-Content -Path $sLogPath\ScriptLog-$sDate.log -Value $write_msg
}

function global:OutputError{
		if ($Error){
				$globalErrorDetail = $error[0].ToString()
				Write-ErrorLog("[詳細] " + $error[0].ToString())
				$error[0] = ""
			}
}
