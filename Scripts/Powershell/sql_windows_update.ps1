
$ErrorActionPreference = "SilentlyContinue"

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

function Cluster_Name([string] $com) {
	try {
		[string](Invoke-Command -ComputerName $com -ScriptBlock { (Get-Cluster).Name + "." + (Get-Cluster).Domain })
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
		[string]([System.Net.DNS]::GetHostAddresses($com) | Where-Object {$_.AddressFamily -eq "InterNetwork"} | select-object IPAddressToString)[0].IPAddressToString
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

$select = "SELECT Server_Name, CPU_Cores, Total_RAM, OS, Manufacturer, Serial_number, Model_ID, Alias_Name, Cluster_Name, Organizational_Unit, IP_Address, Processor, Logical_Processors FROM [Monitoring].[KPI].[tbl_ServerDetails]"
$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
$global:conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)

# Fetching data from SQL table
$conn.Open()
$selectcmd = $conn.CreateCommand()
$selectcmd.CommandText = $select
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $selectcmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
for ($i = 0; $i -lt $DataSet.Tables.Rows.Length; $i++) {
	if ($DataSet.Tables.Server_Name[$i].Substring(2, 1) -Match "w") {
		if (($DataSet.Tables.Alias_Name[$i] -Match "corp.hpicloud.net") -and (Test-Connection -ComputerName $DataSet.Tables.Alias_Name[$i] -Count 1)) {
			if ([string]::IsNullOrEmpty($DataSet.Tables.CPU_Cores[$i]) -or ($DataSet.Tables.CPU_Cores[$i] -eq 0)) {				
				$CPU_Cores = CPU_Cores $DataSet.Tables.Alias_Name[$i]
				$column = "CPU_Cores"
				SQL $DataSet.Tables.Server_Name[$i] $CPU_Cores $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Total_RAM[$i]) -or ($DataSet.Tables.Total_RAM[$i] -eq 0)) {
				$Total_RAM = Total_RAM $DataSet.Tables.Alias_Name[$i]
				$column = "Total_RAM"
				SQL $DataSet.Tables.Server_Name[$i] $Total_RAM $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.OS[$i]) -or ($DataSet.Tables.OS[$i] -eq 0)) {				
				$OS = OS $DataSet.Tables.Alias_Name[$i]
				$column = "OS"
				SQL $DataSet.Tables.Server_Name[$i] $OS $column
			} 	
			if ([string]::IsNullOrEmpty($DataSet.Tables.Manufacturer[$i]) -or ($DataSet.Tables.Manufacturer[$i] -eq 0)) {				
				$Manufacturer = Manufacturer $DataSet.Tables.Alias_Name[$i]
				$column = "Manufacturer"
				SQL $DataSet.Tables.Server_Name[$i] $Manufacturer $column
			}			
			if ([string]::IsNullOrEmpty($DataSet.Tables.Serial_number[$i]) -or ($DataSet.Tables.Serial_number[$i] -eq 0)) {				
				$Serial_number = Serial_number $DataSet.Tables.Alias_Name[$i]
				$column = "Serial_number"
				SQL $DataSet.Tables.Server_Name[$i] $Serial_number $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Model_ID[$i]) -or ($DataSet.Tables.Model_ID[$i] -eq 0)) {				
				$Model_ID = Model_ID $DataSet.Tables.Alias_Name[$i]
				$column = "Model_ID"
				SQL $DataSet.Tables.Server_Name[$i] $Model_ID $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Organizational_Unit[$i]) -or ($DataSet.Tables.Organizational_Unit[$i] -eq 0)) {				
				$Organizational_Unit = Organizational_Unit $DataSet.Tables.Server_Name[$i]
				$column = "Organizational_Unit"
				SQL $DataSet.Tables.Server_Name[$i] $Organizational_Unit $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.IP_Address[$i]) -or ($DataSet.Tables.IP_Address[$i] -eq 0)) {				
				$IP_Address = IP_Address $DataSet.Tables.Server_Name[$i]
				$column = "IP_Address"
				SQL $DataSet.Tables.Server_Name[$i] $IP_Address $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Processor[$i]) -or ($DataSet.Tables.Processor[$i] -eq 0)) {				
				$Processor = Processor $DataSet.Tables.Alias_Name[$i]
				$column = "Processor"
				SQL $DataSet.Tables.Server_Name[$i] $Processor $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Logical_Processors[$i]) -or ($DataSet.Tables.Logical_Processors[$i] -eq 0)) {				
				$Logical_Processors = Logical_Processors $DataSet.Tables.Alias_Name[$i]
				$column = "Logical_Processors"
				SQL $DataSet.Tables.Server_Name[$i] $Logical_Processors $column
			}
		}
		Elseif (($DataSet.Tables.Alias_Name[$i] -Match "inc.hpicorp.net" -or "inc.hp.com") -and (Test-Connection -ComputerName $DataSet.Tables.Server_Name[$i] -Count 1)) {
			if ([string]::IsNullOrEmpty($DataSet.Tables.CPU_Cores[$i]) -or ($DataSet.Tables.CPU_Cores[$i] -eq 0)) {				
				$CPU_Cores = CPU_Cores $DataSet.Tables.Server_Name[$i]
				$column = "CPU_Cores"
				SQL $DataSet.Tables.Server_Name[$i] $CPU_Cores $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Total_RAM[$i]) -or ($DataSet.Tables.Total_RAM[$i] -eq 0)) {
				$Total_RAM = Total_RAM $DataSet.Tables.Server_Name[$i]
				$column = "Total_RAM"
				SQL $DataSet.Tables.Server_Name[$i] $Total_RAM $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.OS[$i]) -or ($DataSet.Tables.OS[$i] -eq 0)) {				
				$OS = OS $DataSet.Tables.Server_Name[$i]
				$column = "OS"
				SQL $DataSet.Tables.Server_Name[$i] $OS $column
			} 	
			if ([string]::IsNullOrEmpty($DataSet.Tables.Manufacturer[$i]) -or ($DataSet.Tables.Manufacturer[$i] -eq 0)) {				
				$Manufacturer = Manufacturer $DataSet.Tables.Server_Name[$i]
				$column = "Manufacturer"
				SQL $DataSet.Tables.Server_Name[$i] $Manufacturer $column
			}			
			if ([string]::IsNullOrEmpty($DataSet.Tables.Serial_number[$i]) -or ($DataSet.Tables.Serial_number[$i] -eq 0)) {				
				$Serial_number = Serial_number $DataSet.Tables.Server_Name[$i]
				$column = "Serial_number"
				SQL $DataSet.Tables.Server_Name[$i] $Serial_number $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Model_ID[$i]) -or ($DataSet.Tables.Model_ID[$i] -eq 0)) {				
				$Model_ID = Model_ID $DataSet.Tables.Server_Name[$i]
				$column = "Model_ID"
				SQL $DataSet.Tables.Server_Name[$i] $Model_ID $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Organizational_Unit[$i]) -or ($DataSet.Tables.Organizational_Unit[$i] -eq 0)) {				
				$Organizational_Unit = Organizational_Unit $DataSet.Tables.Server_Name[$i]
				$column = "Organizational_Unit"
				SQL $DataSet.Tables.Server_Name[$i] $Organizational_Unit $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.IP_Address[$i]) -or ($DataSet.Tables.IP_Address[$i] -eq 0)) {				
				$IP_Address = IP_Address $DataSet.Tables.Server_Name[$i]
				$column = "IP_Address"
				SQL $DataSet.Tables.Server_Name[$i] $IP_Address $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Processor[$i]) -or ($DataSet.Tables.Processor[$i] -eq 0)) {				
				$Processor = Processor $DataSet.Tables.Server_Name[$i]
				$column = "Processor"
				SQL $DataSet.Tables.Server_Name[$i] $Processor $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Logical_Processors[$i]) -or ($DataSet.Tables.Logical_Processors[$i] -eq 0)) {				
				$Logical_Processors = Logical_Processors $DataSet.Tables.Server_Name[$i]
				$column = "Logical_Processors"
				SQL $DataSet.Tables.Server_Name[$i] $Logical_Processors $column
			}
			if ([string]::IsNullOrEmpty($DataSet.Tables.Cluster_Name[$i]) -or ($DataSet.Tables.Cluster_Name[$i] -eq 0)) {				
				$Cluster_Name = Cluster_Name $DataSet.Tables.Server_Name[$i]
				$column = "Cluster_Name"
				SQL $DataSet.Tables.Server_Name[$i] $Cluster_Name $column
			}
		}
	}
}	

$conn.Close()

# if (Get-WindowsFeature -Name RSAT-AD-PowerShell | Where-Object InstallState -Eq Installed) {
#     Uninstall-WindowsFeature RSAT-AD-PowerShell
# }		
