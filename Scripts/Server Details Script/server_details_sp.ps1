
# NOTE : Script requires Alias_Name as FQDN in ServerDetails2 table for fetching info.
# .NET Framework 4.7.2 or above and Powershell version greater than 5.0 required inorder to install module Posh-SSH for accessing linux servers
# $CPU_Cores value must be a non-zero integer value or else data collection will be skipped. This condition is provided to improve script performance.

# To run from a powershell windows in admin mode
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {  
	$arguments = "& '" + $myinvocation.mycommand.definition + "'"
	Start-Process powershell -Verb runAs -ArgumentList $arguments
	Break
}

# Suppresses Errors, Warnings
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Specifying log file path as current directory of script 
$parent_path = Split-Path $MyInvocation.MyCommand.Path -Parent
$log_file = "{0}\ServerDetails_{1}.log" -f $parent_path, $env:computername

# Declaring function to create or append log file
function log_write([string] $log) {
	$date = Get-Date
	$date_utc = $date.ToUniversalTime()
	$content = $date_utc.ToString() + " : " + $log
	Add-content $log_file -value $content
}

# Writing script run start to log file
log_write "----------------------------------- START -----------------------------------"

# Function to retrieve password
function Get-SecurePassword {

	[cmdletbinding()]
	param(
		[string]$PwdFile,
		[string]$KeyFile
	)

	if ( !(Test-Path $PwdFile) ) {
		throw "Password File provided does not exist."
	}
	if ( !(Test-Path $KeyFile) ) {
		throw "KeyFile was not found."
	}

	$keyValue = Get-Content $KeyFile
	Get-Content $PwdFile | ConvertTo-SecureString -Key $keyValue

}

# Assigning credentials to SSH into linux servers
$User = "vinodath"
$Pswd = Get-SecurePassword -PwdFile $parent_path\pwd.txt -KeyFile $parent_path\key.key

# Converting credentials to secure string
$Credentials = New-Object System.Management.Automation.PSCredential($User, $Pswd)

# Assigning connection string
$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@12345;Integrated Security=False'

# Assigning SQL Stored Procedure to obtain existing table values from ServerDetails
$select = "EXEC ServerDetails_SelectAll"

# Declaring linux commands to obtain server stats
$linux_cores = "lscpu | awk 'NR==4{print `$2}'"
$linux_ram = "free -g | awk 'NR==2{print `$2}'"
$linux_os = "cat /etc/redhat-release"
$linux_manufacturer = "cat /sys/devices/virtual/dmi/id/sys_vendor"
$linux_serial_number = "sudo dmidecode -s system-serial-number"
$linux_model_id = "cat /sys/devices/virtual/dmi/id/product_name"
$linux_processor = "cat /proc/cpuinfo | grep 'model name' | uniq | cut -d: -f2"
$linux_logical_processors = "cat /proc/cpuinfo | grep 'bogo' | wc -l"

$RSAT = 1
$Host_Domain = (Get-CimInstance CIM_ComputerSystem).Domain.ToLower()
# Installs RSAT-AD-PowerShell windows feature if not present
try {
	$RSAT_InstallState = (Get-WindowsFeature -Name RSAT-AD-PowerShell).InstallState
	$AcceptableText = @("Available", "Installed", "InstallPending")
	if ($RSAT_InstallState -notin $AcceptableText) {
		Install-WindowsFeature RSAT-AD-PowerShell
	}
	if ($RSAT_InstallState -eq "InstallPending") {
		$RSAT = 0
		log_write ("RSAT-AD-PowerShell requires server restart to fetch OU info")
		Write-Host ("RSAT-AD-PowerShell requires server restart to fetch OU info")
	}
}
catch { 
	$RSAT = 0
	log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
	log_write ($_.Exception)
}

$PoshSSH = 1
$PSVersion = $PSVersionTable.PSVersion.Major
# Installs Posh-SSH module if not present
try {
	if ($PSVersion -ge 5) {
		if (-not(Get-Module -ListAvailable -Name Posh-SSH)) {
			Install-Module Posh-SSH -Force
			Import-Module Posh-SSH
		}
	}
 else {
		$PoshSSH = 0
		log_write ("Install-Module cmd requires Powershell version greater than or equal to 5.0, existing major version is " + $PSVersion)
		log_write ("Data collection from linux servers will be skipped")
		Write-Host ("Install-Module cmd requires Powershell version greater than or equal to 5.0, existing major version is " + $PSVersion)
		Write-Host  ("Data collection from linux servers will be skipped")
	}
}
catch { 
	log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
	log_write ($_.Exception)
}

# Declaring function to update column value in ServerDetails
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
			log_write ("Could not add " + $server + " - " + $column + " value to SQL table.")
		}
		$updatecmd.Parameters.AddWithValue("@Alias_Name", $server) | Out-Null
		$updatecmd.Parameters.AddWithValue("@Value", $value) | Out-Null
		$updatecmd.Parameters.AddWithValue("@Column", $column) | Out-Null
		if (-not [string]::IsNullOrEmpty($updatecmd.CommandText)) {
			$updatecmd.ExecuteNonQuery()
		}
	}
	catch { 
		log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
		log_write ($_.Exception)
	}
}

# Declaring function to remotely execute powershell command
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
			default { 
				log_write ($metric + " is a non-existent column name") 
			}
		}
	}
	catch { 
		log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
		log_write ($_.Exception)
	}
}

# Declaring function to fetch IP Address
function IP_Address([string] $server) {
	try {
		[string]([System.Net.DNS]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | select-object IPAddressToString)[0].IPAddressToString
	}
	catch { 
		log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
		log_write ($_.Exception)
		return $null
	}
}

# Declaring function to remotely execute bash command
function Invoke-SSH([string] $command, [string] $datatype) {
	try {
		if ($datatype -eq "String") {
			[string]((Invoke-SSHCommand -Index $SessionID.sessionid -Command $command).Output)[0]
		}
		elseif ($datatype -eq "Int") {
			[int]((Invoke-SSHCommand -Index $SessionID.sessionid -Command $command).Output)[0]
		}
	}
	catch { 
		log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
		log_write ($_.Exception)
		return $null 
	}
}

# Checking metric value is not null and confirming it's different from field value in ServerDetails table
function Validate($field, $metric) {
	((-not [string]::IsNullOrEmpty($metric)) -and ($metric -ne 0)) -and ($metric -ne $field)
}

# Creating SQL connection object
$global:conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)

# Opening SQL connection
$conn.Open()

# Assigning and creating SQL Select command
$selectcmd = $conn.CreateCommand()
$selectcmd.CommandText = $select

# Creating SQL Adapter object
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter

# Executing SQL Select command on ServerDetails table
$SqlAdapter.SelectCommand = $selectcmd

# Creating DataSet object
$DataSet = New-Object System.Data.DataSet

# Assigning ServerDetails table values to DataSet
$SqlAdapter.Fill($DataSet) | Out-Null

# Looping through each row in DataSet having server details
for ($i = 0; $i -lt $DataSet.Tables.Rows.Length; $i++) {
    
	$Alias_Name = $DataSet.Tables.Alias_Name[$i]
	$Alias_Name_lwr = $Alias_Name.ToLower()
	$Server_Name = $Alias_Name_lwr.Split(".", 2)[0]
	$Domain = $Alias_Name_lwr.Split(".", 2)[1]
	$Availability = $null

	$CPU_Cores = $null
	$Total_RAM = $null
	$OS = $null
	$Manufacturer = $null
	$Serial_number = $null
	$Model_ID = $null
	$Organizational_Unit = $null
	$IP_Address = IP_Address $DataSet.Tables.Alias_Name[$i]
	$Processor = $null
	$Logical_Processors = $null
	$Cluster_Name = $null

	# Checking if server is windows
	if (($Server_Name.Substring(2, 1) -eq "w") -or ($Server_Name.Substring(2, 1) -eq "s")) {

		try {

			# Checking if server is hosted on cloud
			if ($Alias_Name_lwr -Match "hpicloud.net") { 

				if (($RSAT -eq 1) -and ($Domain -eq $Host_Domain)) {
					$Organizational_Unit = windows_metric $Server_Name "Organizational_Unit"
				}

				if ((Test-Connection -ComputerName $Alias_Name_lwr -Count 1 -Quiet) -eq $true) {
					$Availability = 1
			
					# Calling function to remotely invoke powershell command returning stat value
					$CPU_Cores = windows_metric $Alias_Name_lwr "CPU_Cores"

					if ($CPU_Cores -ne 0) {

						$Total_RAM = windows_metric $Alias_Name_lwr "Total_RAM"
						$OS = windows_metric $Alias_Name_lwr "OS"
						$Manufacturer = windows_metric $Alias_Name_lwr "Manufacturer"
						$Serial_number = windows_metric $Alias_Name_lwr "Serial_number"
						$Model_ID = windows_metric $Alias_Name_lwr "Model_ID"
						$Processor = windows_metric $Alias_Name_lwr "Processor"
						$Logical_Processors = windows_metric $Alias_Name_lwr "Logical_Processors"

					}
					else {
						log_write ($Server_Name + " denied permission")
					}
				}			
			}
		}
		catch { 
			log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
			log_write ($_.Exception)
		}
		
		try {

			# Checking if server is hosted on premises
			if (($Alias_Name_lwr -match "hpicorp.net") -or ($Alias_Name_lwr -match "hp.com")) {

				if (($RSAT -eq 1) -and ($Domain -eq $Host_Domain)) {
					$Organizational_Unit = windows_metric $Server_Name "Organizational_Unit"
				}

				if (Test-Connection -ComputerName $Alias_Name_lwr -Count 1 -Quiet) {
					$Availability = 1

					$CPU_Cores = windows_metric $Server_Name "CPU_Cores"
					$Cluster_Name = windows_metric $Server_Name "Cluster_Name"

					if ($CPU_Cores -ne 0) {

						$Total_RAM = windows_metric $Server_Name "Total_RAM"
						$OS = windows_metric $Server_Name "OS"
						$Manufacturer = windows_metric $Server_Name "Manufacturer"
						$Serial_number = windows_metric $Server_Name "Serial_number"
						$Model_ID = windows_metric $Server_Name "Model_ID"
						$Processor = windows_metric $Server_Name "Processor"
						$Logical_Processors = windows_metric $Server_Name "Logical_Processors"

					}
					else {
						log_write ($Server_Name + " denied permission")
					}
				}
			}
		}
		catch { 
			log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
			log_write ($_.Exception)
		}
	}

	# Checking if server is linux
	Elseif ($Server_Name.Substring(2, 1) -eq "t") {

		if ($PoshSSH -eq 1) {

			try {

				if (Test-Connection -ComputerName $Alias_Name_lwr -Count 1 -Quiet) {
					$Availability = 1

					# Opening SSH session to the server
					$SessionID = New-SSHSession -ComputerName $Alias_Name_lwr -Credential $Credentials -AcceptKey:$true
                
					if ($null -ne $SessionID) {
					
						# Calling function to invoke linux command returning stat value using SSH session
						$CPU_Cores = Invoke-SSH $linux_cores "Int"
						$Total_RAM = Invoke-SSH $linux_ram "Int"
						$OS = Invoke-SSH $linux_os "String"
						$Manufacturer = Invoke-SSH $linux_manufacturer "String"
						$Serial_number = Invoke-SSH $linux_serial_number "String"
						$Model_ID = Invoke-SSH $linux_model_id "String"
						$Processor = (Invoke-SSH $linux_processor "String").Trim()
						$Logical_Processors = Invoke-SSH $linux_logical_processors "Int"

					}
					else {
						log_write ($Server_Name + " denied permission")
					}		
				}
			}
			catch { 
				log_write ("Line " + $_.InvocationInfo.ScriptLineNumber + " :")
				log_write ($_.Exception)
			}
		}
		else {
			log_write ($Server_Name + " was skipped")
		}		
	}

	if (Validate $DataSet.Tables.Organizational_Unit[$i] $Organizational_Unit) {
		SQL $Alias_Name $Organizational_Unit "Organizational_Unit"
	}

	if (Validate $DataSet.Tables.IP_Address[$i] $IP_Address) {				
		SQL $Alias_Name $IP_Address "IP_Address"
	}

	if ($Availability -ne 1) {
		if ($Server_Name.Substring(2, 1) -eq "t") {
			if ($PoshSSH -eq 1) {
				log_write ($Server_Name + " is unreachable")
			}
		}
		else {
			log_write ($Server_Name + " is unreachable")
		}
	}

	if (($Availability -eq 1) -and ($CPU_Cores -ne 0) -and ($null -ne $CPU_Cores)) {

		# Checking whether the metric value for server has changed
		if (Validate $DataSet.Tables.CPU_Cores[$i] $CPU_Cores) {

			# Executing SQL function with stat value and Column name to update ServerDetails in DB
			SQL $Alias_Name $CPU_Cores "CPU_Cores"

		}

		if (Validate $DataSet.Tables.Total_RAM[$i] $Total_RAM) {
			SQL $Alias_Name $Total_RAM "Total_RAM"
		}

		if (Validate $DataSet.Tables.OS[$i] $OS) {
			SQL $Alias_Name $OS "OS"
		} 	

		if (Validate $DataSet.Tables.Manufacturer[$i] $Manufacturer) {
			SQL $Alias_Name $Manufacturer "Manufacturer"
		}	

		if (Validate $DataSet.Tables.Serial_number[$i] $Serial_number) {				
			SQL $Alias_Name $Serial_number "Serial_number"
		}

		if (Validate $DataSet.Tables.Model_ID[$i] $Model_ID) {				
			SQL $Alias_Name $Model_ID "Model_ID"
		}

		if (Validate $DataSet.Tables.Processor[$i] $Processor) {				
			SQL $Alias_Name $Processor "Processor"
		}

		if (Validate $DataSet.Tables.Logical_Processors[$i] $Logical_Processors) {				
			SQL $Alias_Name $Logical_Processors "Logical_Processors"
		}

		if (Validate $DataSet.Tables.Cluster_Name[$i] $Cluster_Name) {				
			SQL $Alias_Name $Cluster_Name "Cluster_Name"
		}
	
		if (Validate $DataSet.Tables.Server_Name[$i] $Server_Name) {				
			SQL $Alias_Name $Server_Name "Server_Name"
		}
	}
}

# Closing SQL connection
$conn.Close()

# Writing script run completion to log file
log_write "------------------------------------ STOP ------------------------------------"
