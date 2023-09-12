
if (-not(Get-Module -ListAvailable -Name Posh-SSH)) {
	Install-Module Posh-SSH -Force
}

function Invoke-SSH([string] $com) {
	try {
		[float]((Invoke-SSHCommand -Index $SessionID.sessionid -Command $com).Output)[0]
	}
 catch [Net.WebException] {
		[float]$_.Exception.$null
	}
}

$Servers = Get-Content -Path "D:\Servers.csv"

$Pwd = ""
$User = ""

$insert = @'
	INSERT INTO [Powershell].[dbo].[PerformanceCounters_Linux](Timestamp, System, Cpu_Usage, Memory_Usage, Uptime_Days, System_Load)
	VALUES ('{0}','{1}','{2}','{3}','{4}','{5}')
'@

$cpu_com = "top -bn 2 -d 0.01 | grep '^%Cpu' | tail -n 1 | gawk '{print `$2+`$4+`$6}'"
$total_mem_com = "grep -P 'MemTotal' /proc/meminfo | awk '{print `$2}'"
$used_mem_com = "grep -P 'MemTotal|MemFree' /proc/meminfo | awk '{print `$2}'| paste -sd- - | bc"
$uptime_com = "uptime | awk 'NR==1{print `$3}'"
$system_load_1m_com = "uptime | awk 'NR==1{print `$11}' | cut -d ',' -f1"

while ($true) {
	Try {

		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
		$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
		$conn.Open()
		$cmd = $conn.CreateCommand()
		
		foreach ($Server in $Servers) {

			$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			$secpasswd = ConvertTo-SecureString $Pwd -AsPlainText -Force
			$Credentials = New-Object System.Management.Automation.PSCredential($User, $secpasswd)

			# Connecting Over SSH
			$SessionID = New-SSHSession -ComputerName $Server -Credential $Credentials

			# Invoking Command Over SSH
			$CPU_Usage = Invoke-SSH $cpu_com
			$Total_Memory = Invoke-SSH $total_mem_com
			$Used_Memory = Invoke-SSH $used_mem_com
			$Memory_Usage = [Math]::Round(($Used_Memory / $Total_Memory) * 100, 2)
			$Uptime = Invoke-SSH $uptime_com
			$System_Load = Invoke-SSH $system_load_1m_com

			# Write-Host $Server $CPU_Usage $Memory_Usage $Uptime $System_Load
			$cmd.CommandText = $insert -f $Timestamp, $Server, $Cpu_Usage, $Memory_Usage, $Uptime, $System_Load
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

# free | awk 'NR==2{print $2}'

# grep -P 'MemTotal|MemFree' /proc/meminfo | awk '{print $2}'| paste -sd- - | bc

# lscpu | grep 'Model name'

################################################################################################################################################################

# CREATE TABLE PerformanceCounters_Linux (
# [Timestamp] DATETIME not null, 
# [System] VARCHAR(40) not null, 
# [CPU_Usage] float not null,
# [Memory_Usage] float not null, 
# [Uptime_Days] float not null, 
# [System_Load] float not null
# )
