# $ErrorActionPreference = "SilentlyContinue"
$Alias_Name = "g7w11784c.inc.hpicorp.net" 
$Server_Name = $Alias_Name.Substring(0, $Alias_Name.IndexOf('.'))
if (-not(Get-WindowsFeature -Name RSAT-AD-PowerShell | Where-Object InstallState -Eq Installed)) {
	Install-WindowsFeature RSAT-AD-PowerShell
}
function CPU_Cores([string] $com) {
	try {
		[int](Get-CimInstance -ClassName Win32_Processor -ComputerName $com | Measure-Object -Property NumberOfCores -Sum).Sum
	}
	catch { [int]$_.Exception.$null }
}
function Total_RAM([string] $com) {
	try {
		[int]((Get-CimInstance Win32_PhysicalMemory -ComputerName $com | Measure-Object -Property capacity -Sum).sum / 1gb)
	}
	catch { [int]$_.Exception.$null }
}
function OS([string] $com) {
	try {
		[string](Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $com).Caption
	}
	catch { [string]$_.Exception.$null }
}
function Manufacturer([string] $com) {
	try {
		[string](Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $com).Manufacturer
	}
	catch { [string]$_.Exception.$null }
}
function Serial_number([string] $com) {
	try {
		[string](Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $com).SerialNumber
	}
	catch { [string]$_.Exception.$null }
}
function Model_ID([string] $com) {
	try {
		[string](Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $com -Property Model).Model
	}
	catch { [string]$_.Exception.$null } 
}
function Organizational_Unit([string] $com) {
	try {
		[string](Get-ADComputer -Identity $com).DistinguishedName
	}
	catch { [string]$_.Exception.$null } 
}
function IP_Address([string] $com) {
	try {
		[string]([System.Net.DNS]::GetHostAddresses($com) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | select-object IPAddressToString)[0].IPAddressToString
	}
	catch { [string]$_.Exception.$null } 
}
function Processor([string] $com) {
	try {
		[string](Get-CimInstance -ComputerName $com -Class CIM_Processor | Select-Object -first 1).Name
	}
	catch { [string]$_.Exception.$null } 
}
function Logical_Processors([string] $com) {
	try {
		[int](Get-WmiObject -ComputerName $com Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
	}
	catch { [int]$_.Exception.$null } 
}
function Cluster_Name([string] $com) {
	try {
		[string](Invoke-Command -ComputerName $com -ScriptBlock { (Get-Cluster).Name + "." + (Get-Cluster).Domain })
	}
	catch { [string]$_.Exception.$null }
}
function SQL([string] $com, $value, [string] $column) {
	try {
		$updatecmd = $conn.CreateCommand()
		if ($value -is [int]) {
			$updatecmd.CommandText = "UPDATE [Monitoring].[KPI].[tbl_ServerDetails] SET {2} = {1} WHERE Server_Name = '{0}'" -f $com, $value, $column
		}
		Elseif ($value -is [string]) {
			$updatecmd.CommandText = "UPDATE [Monitoring].[KPI].[tbl_ServerDetails] SET {2} = '{1}' WHERE Server_Name = '{0}'" -f $com, $value, $column
		}
		$updatecmd.ExecuteNonQuery()
	}
	catch { Continue } 
}
$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
$global:conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$conn.Open()
if ($Alias_Name.Substring(2, 1) -Match "w") {
	if (($Alias_Name -Match "corp.hpicloud.net") -and (Test-Connection -ComputerName $Alias_Name -Count 1)) {			
		$CPU_Cores = CPU_Cores $Alias_Name
		$IP_Address = IP_Address $Alias_Name
		$Logical_Processors = Logical_Processors $Alias_Name
		$Manufacturer = Manufacturer $Alias_Name
		$Model_ID = Model_ID $Alias_Name
		$OS = OS $Alias_Name
		$Organizational_Unit = Organizational_Unit $Alias_Name
		$Processor = Processor $Alias_Name
		$Serial_number = Serial_number $Alias_Name
		$Total_RAM = Total_RAM $Alias_Name
		$column1 = "CPU_Cores"
		$column10 = "Logical_Processors"
		$column2 = "Total_RAM"
		$column3 = "OS"
		$column4 = "Manufacturer"
		$column5 = "Serial_number"
		$column6 = "Model_ID"
		$column7 = "Organizational_Unit"
		$column8 = "IP_Address"
		$column9 = "Processor"
		SQL $Server_Name $CPU_Cores $column1
		SQL $Server_Name $IP_Address $column8
		SQL $Server_Name $Logical_Processors $column10
		SQL $Server_Name $Manufacturer $column4
		SQL $Server_Name $Model_ID $column6
		SQL $Server_Name $OS $column3
		SQL $Server_Name $Organizational_Unit $column7	
		SQL $Server_Name $Processor $column9
		SQL $Server_Name $Serial_number $column5
		SQL $Server_Name $Total_RAM $column2
	} 
	Elseif (($Alias_Name -Match "inc.hpicorp.net" -or "inc.hp.com") -and (Test-Connection -ComputerName $Server_Name -Count 1)) {
		$CPU_Cores = CPU_Cores $Server_Name
		$IP_Address = IP_Address $Server_Name
		$Logical_Processors = Logical_Processors $Server_Name
		$Manufacturer = Manufacturer $Server_Name
		$Model_ID = Model_ID $Server_Name
		$OS = OS $Server_Name
		$Organizational_Unit = Organizational_Unit $Server_Name
		$Processor = Processor $Server_Name
		$Serial_number = Serial_number $Server_Name
		$Total_RAM = Total_RAM $Server_Name
		$Cluster_Name = Cluster_Name $Server_Name
		$column1 = "CPU_Cores"
		$column10 = "Logical_Processors"
		$column11 = "Cluster_Name"
		$column2 = "Total_RAM"
		$column3 = "OS"
		$column4 = "Manufacturer"
		$column5 = "Serial_number"
		$column6 = "Model_ID"
		$column7 = "Organizational_Unit"
		$column8 = "IP_Address"
		$column9 = "Processor"
		SQL $Server_Name $CPU_Cores $column1
		SQL $Server_Name $Cluster_Name $column11
		SQL $Server_Name $IP_Address $column8
		SQL $Server_Name $Logical_Processors $column10
		SQL $Server_Name $Manufacturer $column4
		SQL $Server_Name $Model_ID $column6
		SQL $Server_Name $OS $column3
		SQL $Server_Name $Organizational_Unit $column7	
		SQL $Server_Name $Processor $column9
		SQL $Server_Name $Serial_number $column5
		SQL $Server_Name $Total_RAM $column2
	}
}	
$conn.Close()