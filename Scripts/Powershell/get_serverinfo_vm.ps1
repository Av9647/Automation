
Install-WindowsFeature RSAT-AD-PowerShell
$ErrorActionPreference = "SilentlyContinue"

#list.txt must contain list of server names as FQDN with no whitespaces. e.g. g8w00960a.corp.hpicloud.net
$servers = Get-Content -Path "E:\Servers.txt"

$LoopCount = 0
$serverCount = $servers.Count

$result = foreach ($server in $servers) {
	$PercentComplete = [Math]::Round(($LoopCount++ / $serverCount * 100), 1)
	Write-Progress -Activity "ServerInfo collection in progress.." -PercentComplete $PercentComplete -Status "$PercentComplete% Complete" -CurrentOperation "Server: $server"
	$output = [ordered] @{
		'ServerName'            = $null
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
		'OrganizationalUnit'    = $null
	}
	$output.ServerName = (Get-ADComputer -Identity $server.Substring(0, $server.IndexOf('.'))).DNSHostName
	$output.LogicalCores = (Get-WmiObject -ComputerName $server Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
	$output.Processor = (Get-WmiObject -ComputerName $server Win32_Processor).Name
	$output.'Memory (GB)' = ((Get-CimInstance -ComputerName $server -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum) / 1GB
	$output.PhysicalCores = (Get-WmiObject -ComputerName $server Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
	$output.Manufacturer = (Get-WmiObject -ComputerName $server Win32_computersystem).Manufacturer 
	$output.Model = (Get-WmiObject -ComputerName $server Win32_computersystem).Model 
	$output.IPAddress = (Get-CimInstance -ComputerName $server -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'").IPAddress[0]
	$output.OperatingSystem = (Get-CimInstance -ComputerName $server -ClassName Win32_OperatingSystem).Caption
	$output.'C:DriveCapacity (GB)' = [Math]::Round((((Get-CimInstance -ComputerName $server -ClassName Win32_LogicalDisk -Filter " DeviceID = 'C:' ").Size) / 1GB), 2)
	$output.'C:DriveFreeSpace (GB)' = [Math]::Round((((Get-CimInstance -ComputerName $server -ClassName Win32_LogicalDisk -Filter " DeviceID = 'C:' ").FreeSpace) / 1GB), 2)
	$output.OrganizationalUnit = (Get-ADComputer -Identity $server.Substring(0, $server.IndexOf('.'))).DistinguishedName
	[pscustomobject] $output
} 

$result | Export-Csv -Path E:\ServerInfo.csv -NoTypeInformation
Uninstall-WindowsFeature RSAT-AD-PowerShell
