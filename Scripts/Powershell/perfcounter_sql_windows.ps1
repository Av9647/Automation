
$Servers = Get-Content -Path "E:\Servers.csv"

$insert = @'
	INSERT INTO [Powershell].[dbo].[PerformanceCounters_Windows](Timestamp, System, Cpu_Usage, Memory_Usage, Memory_PagesSec, Memory_CacheMBytes, PagingFile_Usage, Cdrive, Edrive, Fdrive, 
	PhysicalDisk_IdleTime, PhysicalDisk_AvgRead, PhysicalDisk_AvgWrite, PhysicalDisk_DiskQueueLength, NetworkInterface1_BytesTotal, NetworkInterface2_BytesTotal, 
	NetworkInterface1_QueueLength, NetworkInterface2_QueueLength, Status)
	VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}','{18}')
'@

while ($true) {
	Try {
		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
		$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
		$conn.Open()
		$cmd = $conn.CreateCommand()
		foreach ($Server in $Servers) {
			if (Test-Connection -ComputerName $Server -Count 1) { 
				$Status = 1
				$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
				$Cpu_Usage = [float][Math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -ComputerName $Server).CounterSamples.CookedValue, 2)
				$TotalRam = (Get-CimInstance Win32_PhysicalMemory -ComputerName $Server | Measure-Object -Property capacity -Sum).Sum
				$AvailMem = (Get-Counter '\Memory\Available MBytes' -ComputerName $Server).CounterSamples.CookedValue
				$Memory_Usage = [float][Math]::Round(104857600 * $AvailMem / $TotalRam, 2)    
				$Memory_PagesSec = [float][Math]::Round((Get-Counter '\Memory\Pages/sec' -ComputerName $Server).CounterSamples.CookedValue, 2)
				$Memory_CacheMBytes = [float][Math]::Round(((Get-Counter '\Memory\Cache Bytes' -ComputerName $Server).CounterSamples.CookedValue / 1048576), 2)
				$PagingFile_Usage = [float][Math]::Round((Get-Counter '\Paging File(_Total)\% Usage' -ComputerName $Server).CounterSamples.CookedValue, 2)	
				$Cdrive = [float][Math]::Round(100 - (Get-Counter '\LogicalDisk(C:)\% Free Space' -ComputerName $Server).CounterSamples.CookedValue, 2)	
				$Edrive = [float][Math]::Round(100 - (Get-Counter '\LogicalDisk(E:)\% Free Space' -ComputerName $Server).CounterSamples.CookedValue, 2)	
				$Fdrive = [float][Math]::Round(100 - (Get-Counter '\LogicalDisk(F:)\% Free Space' -ComputerName $Server).CounterSamples.CookedValue, 2)	
				$PhysicalDisk_IdleTime = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\% Idle Time' -ComputerName $Server).CounterSamples.CookedValue, 2)
				$PhysicalDisk_AvgRead = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Read' -ComputerName $Server).CounterSamples.CookedValue, 2)
				$PhysicalDisk_AvgWrite = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\Avg. Disk sec/Write' -ComputerName $Server).CounterSamples.CookedValue, 2)
				$PhysicalDisk_DiskQueueLength = [float][Math]::Round((Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length' -ComputerName $Server).CounterSamples.CookedValue, 2)
				$NetworkInterface1_BytesTotal = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Bytes Total/sec' -ComputerName $Server).CounterSamples.CookedValue)[0], 2)
				$NetworkInterface2_BytesTotal = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Bytes Total/sec' -ComputerName $Server).CounterSamples.CookedValue)[1], 2)
				$NetworkInterface1_QueueLength = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Output Queue Length' -ComputerName $Server).CounterSamples.CookedValue)[0], 2)
				$NetworkInterface2_QueueLength = [float][Math]::Round(((Get-Counter '\Network Interface(*)\Output Queue Length' -ComputerName $Server).CounterSamples.CookedValue)[1], 2)
			}
			else { 
				$Status = 0 
				$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			} 
			$cmd.CommandText = $insert -f $Timestamp, $Server, $Cpu_Usage, $Memory_Usage, $Memory_PagesSec, $Memory_CacheMBytes, $PagingFile_Usage, $Cdrive, $Edrive, $Fdrive, 
			$PhysicalDisk_IdleTime, $PhysicalDisk_AvgRead, $PhysicalDisk_AvgWrite, $PhysicalDisk_DiskQueueLength, $NetworkInterface1_BytesTotal, $NetworkInterface2_BytesTotal, 
			$NetworkInterface1_QueueLength, $NetworkInterface2_QueueLength, $Status
			$cmd.ExecuteNonQuery()
		}
		$conn.Close()
	}
	Catch {
		Throw $_
	}
	Start-Sleep -s 10
}

################################################################################################################################################################

# $params = @{'server'='g7w11235g.inc.hpicorp.net,2048';'Database'='Powershell'}
# Invoke-Sqlcmd @params -Query "SELECT TOP 10 * FROM [Powershell].[dbo].[PerformanceCounters_Windows] ORDER BY Timestamp DESC" | format-table -AutoSize

################################################################################################################################################################

# CREATE TABLE PerformanceCounters_Windows (
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
# [Status] smallint not null
# )

# INSERT INTO [Monitoring].[KPI].[tbl_Windows_Linux_Service] 
# VALUES (4, 84, 'qaddp*.*', 'QAD DP', 1, 3, 1, '2022-06-06 11:39:00.000', 'athul.vinod@hp.com', '2022-06-06 11:39:00.000', 'shruti', 6);

# SELECT TOP 10 * FROM [Powershell].[dbo].[PerformanceCounters_Windows] ORDER BY Timestamp DESC

# DROP TABLE PerformanceCounters_Windows

# ALTER TABLE [Powershell].[dbo].[PerformanceCounters_Windows]
# DROP COLUMN D_Drive_Space;

# exec sp_rename 'dbo.PerformanceCounters_Windows."[Timestamp]"' , 'Timestamp', 'COLUMN' 

# Update [Powershell].[dbo].[PerformanceCounters_Windows] Set System_Status = 1;

# Update [Powershell].[dbo].[PerformanceCounters_Windows] Set CPU = 62.95 where CPU >= 100;

# ALTER TABLE [Powershell].[dbo].[PerformanceCounters_Windows]
# ADD C_Drive_Space varchar(20);

# Update [Powershell].[dbo].[PerformanceCounters_Windows] Set C_Drive_Space = 30.25 Where SystemName = 'g7w11234g';

# DELETE FROM [Powershell].[dbo].[PerformanceCounters_Windows] WHERE System = 'DESKTOP-QJSJ7NP'

# Update [Powershell].[dbo].[Organization] Set Date_Created = (SELECT CURRENT_TIMESTAMP);

# UPDATE [Powershell].[dbo].[Endpoints] SET Service = REPLACE(Service, 'PRD ', '') WHERE Service LIKE '%PRD %'

# UPDATE [Monitoring].[KPI].[tbl_ServerDetails] Set Processor = LTRIM(RTRIM(Processor))

# SELECT count(*), Server_Name FROM [Monitoring].[KPI].[tbl_ServerDetails] group by Server_Name having count(*) > 1

# Select Server_Name from [Monitoring].[KPI].[tbl_ServerDetails] 
# Where Server_ID NOT IN (Select distinct Server_ID from [Monitoring].[KPI].[tbl_CPU_Memory_Usage]) 
# AND Env_ID IN (1,2)
# AND IsActive = 1
# AND APP_ID = 7
