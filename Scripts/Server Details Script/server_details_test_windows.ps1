
# NOTE : Script requires Alias_Name as FQDN in ServerDetails2 table for fetching info.

# $ErrorActionPreference = "SilentlyContinue"

$parent_path = Split-Path $MyInvocation.MyCommand.Path -Parent
$log_file = "{0}\ServerDetails_{1}.log" -f $parent_path, $env:computername

function log_write([string] $log) {
	$date = Get-Date
	$date_utc = $date.ToUniversalTime()
	$content = $date_utc.ToString() + " : " + $log
	Add-content $log_file -value $content
}

# Writing script run start to log file
log_write "----------------------------------- Script Run Started -----------------------------------"

$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@12345;Integrated Security=False'
$Alias_Name = "DESKTOP-QJSJ7NP.auth.hpicorp.net" 
$Alias_Name_lwr = $Alias_Name.ToLower()
$Server_Name = $Alias_Name_lwr.Substring(0, $Alias_Name_lwr.IndexOf('.'))

try {
	if (-not(Get-WindowsFeature -Name RSAT-AD-PowerShell | Where-Object InstallState -Eq Installed)) {
		Install-WindowsFeature RSAT-AD-PowerShell
	}
}
catch { 
	log_write $_.Exception
	Write-Host $_.Exception
}

function SQL([string] $server, $value, [string] $column) {
	try {
		$updatecmd = $conn.CreateCommand()
		if ($value -is [int]) {
			$updatecmd.CommandText = "EXEC [dbo].[ServerDetails_Update_Int] @Alias_Name, @Value, @Column"
		}
		elseif ($value -is [string]) {
			$updatecmd.CommandText = "EXEC [dbo].[ServerDetails_Update_String] @Alias_Name, @Value, @Column"
		}
		elseif ($null -eq $value) {
			log_write ("Could not fetch " + $server + " - " + $column + " value.")
		}
		$updatecmd.Parameters.AddWithValue("@Alias_Name", $server) | Out-Null
		$updatecmd.Parameters.AddWithValue("@Value", $value) | Out-Null
		$updatecmd.Parameters.AddWithValue("@Column", $column) | Out-Null
		if (-not [string]::IsNullOrEmpty($updatecmd.CommandText)) {
			$updatecmd.ExecuteNonQuery()
		}
	}
	catch { 
		log_write $_.Exception
		Continue
	}
}

function windows_metric([string] $server, [string] $metric) {
	try {
		switch ($metric) {
			"CPU_Cores" { return [int](Get-CimInstance -ClassName Win32_Processor -ComputerName $server | Measure-Object -Property NumberOfCores -Sum).Sum; break }
			"Total_RAM" { return [int]((Get-CimInstance -ClassName Win32_PhysicalMemory -ComputerName $server | Measure-Object -Property capacity -Sum).sum / 1gb); break }
			"OS" { return [string](Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $server -Property Caption).Caption; break }
			"Manufacturer" { return [string](Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $server -Property Manufacturer).Manufacturer; break }
			"Serial_number" { return [string](Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $server -Property SerialNumber).SerialNumber; break }
			"Model_ID" { return [string](Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $server -Property Model).Model; break }
			"Cluster_Name" { return [string](Invoke-Command -ComputerName $server -ScriptBlock { (Get-Cluster).Name + "." + (Get-Cluster).Domain }); break }
			"Organizational_Unit" { return [string](Get-ADComputer -Identity $server).DistinguishedName; break }
			"Processor" { return [string](Get-CimInstance -ClassName CIM_Processor -ComputerName $server | Select-Object -first 1).Name; break }
			"Logical_Processors" { return [int](Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $server -Property NumberOfLogicalProcessors).NumberOfLogicalProcessors; break }
			default { log_write ($metric + " is a non-existent column name") }
		}
	}
	catch { 
		log_write $_.Exception
		Continue
	}
}

function IP_Address([string] $server) {
	try {
		[string]([System.Net.DNS]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | select-object IPAddressToString)[0].IPAddressToString
	}
	catch { 
		log_write $_.Exception
		return $null
	}
}

$global:conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$conn.Open()

if (($Alias_Name_lwr.Substring(2, 1) -eq "w") -or ($Alias_Name_lwr.Substring(2, 1) -eq "S")) {

	$IP_Address = IP_Address $Alias_Name_lwr
	$Cluster_Name = $null

	try {
		if (($Alias_Name_lwr -Match "hpicloud.net") -and (Test-Connection -ComputerName $Alias_Name_lwr -Count 1)) {			
			$CPU_Cores = windows_metric $Alias_Name_lwr "CPU_Cores"
			$Logical_Processors = windows_metric $Alias_Name_lwr "Logical_Processors"
			$Manufacturer = windows_metric $Alias_Name_lwr "Manufacturer"
			$Model_ID = windows_metric $Alias_Name_lwr "Model_ID"
			$OS = windows_metric $Alias_Name_lwr "OS"
			$Organizational_Unit = windows_metric $Alias_Name_lwr "Organizational_Unit"
			$Processor = windows_metric $Alias_Name_lwr "Processor"
			$Serial_number = windows_metric $Alias_Name_lwr "Serial_number"
			$Total_RAM = windows_metric $Alias_Name_lwr "Total_RAM"
		}
	}
	catch { 
		log_write $_.Exception
		Continue
	} 

	try {
		if ((($Alias_Name_lwr -match "hpicorp.net") -or ($Alias_Name_lwr -match "hp.com")) -and (Test-Connection -ComputerName $Server_Name -Count 1)) {
			$CPU_Cores = windows_metric $Server_Name "CPU_Cores"
			$Logical_Processors = windows_metric $Server_Name "Logical_Processors"
			$Manufacturer = windows_metric $Server_Name "Manufacturer"
			$Model_ID = windows_metric $Server_Name "Model_ID"
			$OS = windows_metric $Server_Name "OS"
			$Organizational_Unit = windows_metric $Server_Name "Organizational_Unit"
			$Processor = windows_metric $Server_Name "Processor"
			$Serial_number = windows_metric $Server_Name "Serial_number"
			$Total_RAM = windows_metric $Server_Name "Total_RAM"
			$Cluster_Name = windows_metric $Server_Name "Cluster_Name"
		}
	}
	catch { 
		log_write $_.Exception
		Continue 
	}

	SQL $Alias_Name $CPU_Cores "CPU_Cores"
	SQL $Alias_Name $Cluster_Name "Cluster_Name"
	SQL $Alias_Name $IP_Address "IP_Address"
	SQL $Alias_Name $Logical_Processors "Logical_Processors"
	SQL $Alias_Name $Manufacturer "Manufacturer"
	SQL $Alias_Name $Model_ID "Model_ID"
	SQL $Alias_Name $OS "OS"
	SQL $Alias_Name $Organizational_Unit "Organizational_Unit"
	SQL $Alias_Name $Processor "Processor"
	SQL $Alias_Name $Serial_number "Serial_number"
	SQL $Alias_Name $Total_RAM "Total_RAM"
	SQL $Alias_Name $Server_Name "Server_Name"

}	

$conn.Close()

# Writing script run completion to log file
log_write "---------------------------------- Script Run Completed ----------------------------------"
