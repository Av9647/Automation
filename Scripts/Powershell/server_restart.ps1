
# list.txt must contain list of server names as FQDN with no whitespaces. e.g. g7w11232g.auth.hpicorp.net
# Alternative command : Invoke-CimMethod -ComputerName $server -ClassName 'Win32_OperatingSystem' -MethodName 'Reboot'
$Output = @()
$servers = Get-content "E:\Servers.txt"
$LoopCount = 0
$serverCount = $servers.Count
foreach ($server in $servers) {
	$PercentComplete = [Math]::Round(($LoopCount++ / $serverCount * 100), 1)
	Write-Progress -Activity "Server restart in progress.." -PercentComplete $PercentComplete -Status "$PercentComplete% Complete" -CurrentOperation "Server: $server"
	if (Test-Connection -ComputerName $server -Count 1) {
		Write-Host "$server is online.. Initiating restart" -ForegroundColor Green
		Restart-Computer $server -Force
		$Output += "$server was online and restarted"
	}
	else {
		Write-Host "$server is offline" -ForegroundColor Red
		$Output += "$server was offline"
	} 
}
$Output | Out-file "E:\RestartLog.csv" 
