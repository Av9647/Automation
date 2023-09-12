
Install-WindowsFeature RSAT-AD-PowerShell 
$ErrorActionPreference = "SilentlyContinue"

# list.txt must contain list of server names as FQDN with no whitespaces. e.g. g7w11232g.inc.hpicorp.net
$servers = Get-Content -Path "E:\Servers.txt"

$LoopCount = 0
$serverCount = $servers.Count

$result = foreach ($server in $servers) {
	$hostname = $server.Substring(0, $server.IndexOf('.'))
	$PercentComplete = [Math]::Round(($LoopCount++ / $serverCount * 100), 1)
	Write-Progress -Activity "ServerInfo collection in progress.." -PercentComplete $PercentComplete -Status "$PercentComplete% Complete" -CurrentOperation "Server: $server"
	$output = [ordered] @{
		'ServerName'            = $null
		'ClusterName'           = $null
		'LogicalCores'          = $null
		'Processor'             = $null
		'Memory (GB)'           = $null
		'PhysicalCores'         = $null
		'Manufacturer'          = $null
		'Model'                 = $null
		'IPAddress'             = $null
		'OperatingSystem'       = $null
		'C:DriveCapacity (GB)'  = $null
		'C:DriveFreeSpace (GB)' = $null
		# 'UserProfileSize (MB)' = $null
		'OrganizationalUnit'    = $null
	}
	$output.ServerName = (Get-ADComputer -Identity $hostname).DNSHostName
	$output.ClusterName = Invoke-Command -ComputerName $hostname -ScriptBlock { (Get-Cluster).Name + "." + (Get-Cluster).Domain }
	$output.LogicalCores = (Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $hostname).NumberOfLogicalProcessors
	$output.Processor = (Get-CimInstance -ClassName CIM_Processor -ComputerName $hostname | Select-Object -first 1).Name
	$output.'Memory (GB)' = ((Get-CimInstance -ComputerName $hostname -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum) / 1GB
	$output.PhysicalCores = (Get-CimInstance -ClassName Win32_Processor -ComputerName $hostname | Measure-Object -Property NumberOfCores -Sum).Sum
	$output.Manufacturer = (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $hostname).Manufacturer 
	$output.Model = (Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $hostname -Property Model).Model 
	$output.IPAddress = (Get-CimInstance -ComputerName $hostname -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'").IPAddress[0]
	$output.OperatingSystem = (Get-CimInstance -ComputerName $hostname -ClassName Win32_OperatingSystem).Caption
	$output.'C:DriveCapacity (GB)' = [Math]::Round((((Get-CimInstance -ComputerName $hostname -ClassName Win32_LogicalDisk -Filter " DeviceID = 'C:' ").Size) / 1GB), 2)
	$output.'C:DriveFreeSpace (GB)' = [Math]::Round((((Get-CimInstance -ComputerName $hostname -ClassName Win32_LogicalDisk -Filter " DeviceID = 'C:' ").FreeSpace) / 1GB), 2)
	# $output.'UserProfileSize (MB)' = [Math]::Round((((Get-ChildItem -Path \\$hostname\c$\Users -Recurse -File | Measure-Object -Property Length -Sum).Sum) / 1MB),2)
	$output.OrganizationalUnit = (Get-ADComputer -Identity $hostname).DistinguishedName
	[pscustomobject] $output
} 

$result | Export-Csv -Path E:\ServerInfo.csv -NoTypeInformation
Uninstall-WindowsFeature RSAT-AD-PowerShell
