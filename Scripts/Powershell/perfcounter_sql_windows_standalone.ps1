
$insert = @'
	INSERT INTO [Powershell].[dbo].[PerfCounters_Windows](Timestamp, System, Cpu_Usage, Memory_Usage, Memory_PagesSec, Memory_CacheMBytes, PagingFile_Usage, Cdrive, Edrive, Fdrive, 
	PhysicalDisk_IdleTime, PhysicalDisk_AvgRead, PhysicalDisk_AvgWrite, PhysicalDisk_DiskQueueLength, NetworkInterface1_BytesTotal, NetworkInterface2_BytesTotal, 
	NetworkInterface1_QueueLength, NetworkInterface2_QueueLength)
	VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}')
'@

while ($true) {
	$TotalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum
	$AvailMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
	$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$Server = hostname
	$Cpu_Usage = [float][Math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue, 2)
	$Memory_Usage = [float][Math]::Round(104857600 * $AvailMem / $TotalRam, 2)    
	$Memory_PagesSec = [float][Math]::Round((Get-Counter '\Memory\Pages/sec').CounterSamples.CookedValue, 2)
	$Memory_CacheMBytes = [float][Math]::Round(((Get-Counter '\Memory\Cache Bytes').CounterSamples.CookedValue / 1048576), 2)
	$PagingFile_Usage = [float][Math]::Round((Get-Counter '\Paging File(_Total)\% Usage').CounterSamples.CookedValue, 2)	
	$Cdrive = [float][Math]::Round(100 - (Get-Counter '\LogicalDisk(C:)\% Free Space').CounterSamples.CookedValue, 2)	
	$Edrive = [float][Math]::Round(100 - (Get-Counter '\LogicalDisk(E:)\% Free Space').CounterSamples.CookedValue, 2)	
	$Fdrive = [float][Math]::Round(100 - (Get-Counter '\LogicalDisk(F:)\% Free Space').CounterSamples.CookedValue, 2)	
	$PhysicalDisk_IdleTime = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\% Idle Time').CounterSamples.CookedValue, 2)
	$PhysicalDisk_AvgRead = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Read').CounterSamples.CookedValue, 2)
	$PhysicalDisk_AvgWrite = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Write').CounterSamples.CookedValue, 2)
	$PhysicalDisk_DiskQueueLength = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length').CounterSamples.CookedValue, 2)
	$NetworkInterface1_BytesTotal = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Bytes Total/sec').CounterSamples.CookedValue)[0], 2)
	$NetworkInterface2_BytesTotal = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Bytes Total/sec').CounterSamples.CookedValue)[1], 2)
	$NetworkInterface1_QueueLength = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Output Queue Length').CounterSamples.CookedValue)[0], 2)
	$NetworkInterface2_QueueLength = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Output Queue Length').CounterSamples.CookedValue)[1], 2) 
	Try {
		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
		$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
		$conn.Open()
		$cmd = $conn.CreateCommand()
		$cmd.CommandText = $insert -f $Timestamp, $Server, $Cpu_Usage, $Memory_Usage, $Memory_PagesSec, $Memory_CacheMBytes, $PagingFile_Usage, $Cdrive, $Edrive, $Fdrive, 
		$PhysicalDisk_IdleTime, $PhysicalDisk_AvgRead, $PhysicalDisk_AvgWrite, $PhysicalDisk_DiskQueueLength, $NetworkInterface1_BytesTotal, $NetworkInterface2_BytesTotal, 
		$NetworkInterface1_QueueLength, $NetworkInterface2_QueueLength
		$cmd.ExecuteNonQuery()
		$conn.Close()
	}
	Catch {
		# Throw $_
		$csv_path = 'D:\Log.csv'
		if ((Test-Path -Path $csv_path -PathType Leaf) -eq $false) {
			$csvfile = {} | Select-Object "Timestamp", "System", "Cpu_Usage", "Memory_Usage", "Memory_PagesSec", "Memory_CacheMBytes", "PagingFile_Usage", "Cdrive", "Edrive", "Fdrive", 
			"PhysicalDisk_IdleTime", "PhysicalDisk_AvgRead", "PhysicalDisk_AvgWrite", "PhysicalDisk_DiskQueueLength", "NetworkInterface1_BytesTotal", "NetworkInterface2_BytesTotal", 
			"NetworkInterface1_QueueLength", "NetworkInterface2_QueueLength" | Export-Csv $csv_path -NoTypeInformation
		}
		$csvfile = Import-Csv $csv_path
		$csvfile = {} | Select-Object "Timestamp", "System", "Cpu_Usage", "Memory_Usage", "Memory_PagesSec", "Memory_CacheMBytes", "PagingFile_Usage", "Cdrive", "Edrive", "Fdrive", 
		"PhysicalDisk_IdleTime", "PhysicalDisk_AvgRead", "PhysicalDisk_AvgWrite", "PhysicalDisk_DiskQueueLength", "NetworkInterface1_BytesTotal", "NetworkInterface2_BytesTotal", 
		"NetworkInterface1_QueueLength", "NetworkInterface2_QueueLength"
		$csvfile.Timestamp = $Timestamp
		$csvfile.System = $Server
		$csvfile.Cpu_Usage = $Cpu_Usage
		$csvfile.Memory_Usage = $Memory_Usage
		$csvfile.Memory_PagesSec = $Memory_PagesSec
		$csvfile.Memory_CacheMBytes = $Memory_CacheMBytes
		$csvfile.PagingFile_Usage = $PagingFile_Usage
		$csvfile.Cdrive = $Cdrive
		$csvfile.Edrive = $Edrive
		$csvfile.Fdrive = $Fdrive
		$csvfile.PhysicalDisk_IdleTime = $PhysicalDisk_IdleTime
		$csvfile.PhysicalDisk_AvgRead = $PhysicalDisk_AvgRead
		$csvfile.PhysicalDisk_AvgWrite = $PhysicalDisk_AvgWrite
		$csvfile.PhysicalDisk_DiskQueueLength = $PhysicalDisk_DiskQueueLength
		$csvfile.NetworkInterface1_BytesTotal = $NetworkInterface1_BytesTotal
		$csvfile.NetworkInterface2_BytesTotal = $NetworkInterface2_BytesTotal
		$csvfile.NetworkInterface1_QueueLength = $NetworkInterface1_QueueLength
		$csvfile.NetworkInterface2_QueueLength = $NetworkInterface2_QueueLength
		$csvfile | Export-CSV $csv_path –Append -NoTypeInformation
	}
	Start-Sleep -s 10
}

################################################################################################################################################################

# CREATE TABLE PerfCounters_Windows (
# [Timestamp] DATETIME not null, 
# [System] VARCHAR(40) not null, 
# [CPU_Usage] float not null,
# [Memory_Usage] float not null, 
# [Memory_PagesSec] float not null, 
# [Memory_CacheMBytes] float not null, 
# [PagingFile_Usage] float not null,
# [Cdrive] float not null, 
# [Edrive] float not null, 
# [Fdrive] float not null, 
# [PhysicalDisk_IdleTime] float not null, 
# [PhysicalDisk_AvgRead] float not null, 
# [PhysicalDisk_AvgWrite] float not null, 
# [PhysicalDisk_DiskQueueLength] float not null, 
# [NetworkInterface1_BytesTotal] float not null, 
# [NetworkInterface2_BytesTotal] float not null, 
# [NetworkInterface1_QueueLength] float not null, 
# [NetworkInterface2_QueueLength] float not null, 
# )
