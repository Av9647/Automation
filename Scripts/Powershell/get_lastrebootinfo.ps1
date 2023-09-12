
# list.txt must contain list of server names as FQDN with no whitespaces. e.g. g7w11232g.auth.hpicorp.net
$sharepath = "\\auth.hpicorp.net\HPI\205254_hpit-w-grpshares-inc-prd_HPITSoftwareDownloads\Microsoft\Servers\temp"
$servers = Get-Content -Path "$sharepath\Servers.txt"

$LoopCount = 0
$serverCount = $servers.Count

$result = foreach ($server in $servers) {
	$PercentComplete = [Math]::Round(($LoopCount++ / $serverCount * 100), 1)
	Write-Progress -Activity "LastRebootInfo collection in progress.." -PercentComplete $PercentComplete -Status "$PercentComplete% Complete" -CurrentOperation "Server: $server"
	$output = [ordered] @{
		'ServerName'   = $null
		'LastBootTime' = $null
	}
	$output.ServerName = $server
	$output.LastBootTime = (Get-CimInstance -ComputerName $server -ClassName Win32_OperatingSystem).lastbootuptime
	[pscustomobject] $output
} 

$result | Export-Csv -Path $sharepath\RebootInfo.csv -NoTypeInformation
