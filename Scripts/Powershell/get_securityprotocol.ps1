
$ErrorActionPreference = "SilentlyContinue"

#List.txt must contain list of server names as FQDN with no whitespaces. e.g. g7w11232g.inc.hpicorp.net
$servers = Get-Content -Path "E:\List.txt"

$LoopCount=0
$serverCount = $servers.Count

$result = foreach ($server in $servers){
	$PercentComplete = [Math]::Round(($LoopCount++ / $serverCount*100),1)
	Write-Progress -Activity "SecurityProtocolInfo collection in progress.." -PercentComplete $PercentComplete -Status "$PercentComplete% Complete" -CurrentOperation "Server: $server"
	$output = [ordered] @{
		'ServerName' = $null
		'SecurityProtocol' = $null
	}
	$output.ServerName = $server.Substring(0, $server.IndexOf('.'))
	$output.SecurityProtocol =  Invoke-Command -ComputerName $server.Substring(0, $server.IndexOf('.')) -ScriptBlock { [Net.ServicePointManager]::SecurityProtocol }
	[pscustomobject] $output
} 

$result | Export-Csv -Path E:\SecurityProtocol.csv -NoTypeInformation
