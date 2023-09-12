
$Output = @()

# Setup files and list.txt need to be placed in $sharepath
$sharepath = "\\auth.hpicorp.net\HPI\205254_hpit-w-grpshares-inc-prd_HPITSoftwareDownloads\Microsoft\Servers\temp"

# FQDNs of servers are specified in list.txt without whitespaces, for example - g7w11232g.auth.hpicorp.net
$servers = Get-content "$sharepath\Servers.txt"

$LoopCount = 0
$serverCount = $servers.Count
foreach ($server in $servers) {
	$PercentComplete = [Math]::Round(($LoopCount++ / $serverCount * 100), 1)
	Write-Progress -Activity "Installation in progress.." -PercentComplete $PercentComplete -Status "$PercentComplete% Complete" -CurrentOperation "Server: $server"
	if (Test-Connection -ComputerName $server -Count 1) {
		$Output += "Installing setup on $server"
		Write-Host "Installing setup on $server" -ForegroundColor Green

		# Setup files get copied to $directory on $server
		$directory = "\\$server\c$\temp\temp1"
		If (!(test-path $directory)) {
			$null = New-Item -ItemType Directory -Force -Path $directory
		}
		Copy-Item -Path $sharepath\*.exe, $sharepath\*.msi -Destination $directory
		foreach ($f in Get-ChildItem $directory) {
			$Output += "Installing $f"
			Write-Host "Installing $f.."
		}

		# Remotely running setup from same $directory
		$null = Invoke-Command -ComputerName $server -ScriptBlock {
			foreach ($f in Get-ChildItem "c:\temp\temp1\") {
				switch ([IO.Path]::GetExtension($f)) {
					".exe" { $null = Start-Process -Wait -FilePath "c:\temp\temp1\$f" -ArgumentList "/silent /S /v /qn" -passthru; Break }
					".msi" { msiexec /i c:\temp\temp1\$f /quiet /qn /norestart; Break }
				}			
			}
		} -InDisconnectedSession
		do { Start-Sleep -Seconds 5 }
		until ($null -eq (Get-WMIobject -Class Win32_process -Filter "Name='msiexec'" -ComputerName $server | Where-Object { $_.Name -eq "msiexec" }).ProcessID)
		Get-ChildItem  -Path $directory -Recurse  | Remove-Item -Force -Recurse
		Remove-Item $directory -Force -Recurse
		$Output += "Installation completed on $server"	
		Write-Host "Installation completed on $server" -ForegroundColor Green
	}
 else {
		Write-Host "$server is offline" -ForegroundColor Red
		$Output += "$server was offline"
	} 
}

# Storing SetupLog on $sharepath
$Output | Out-file "$sharepath\SetupLog.csv"
