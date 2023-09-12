
$ErrorActionPreference = "SilentlyContinue"

if (-not(Get-Module -ListAvailable -Name Posh-SSH)) {
    Install-Module Posh-SSH -Force
}

function Invoke-SSH-String([string] $com) {
	try {
		[string]((Invoke-SSHCommand -Index $SessionID.sessionid -Command $com).Output)[0]
	}
 catch [Net.WebException] {
		[float]$_.Exception.$null
	}
}

function Invoke-SSH-Int([string] $com) {
	try {
		[int]((Invoke-SSHCommand -Index $SessionID.sessionid -Command $com).Output)[0]
	}
 catch [Net.WebException] {
		[int]$_.Exception.$null
	}
}

function SQL([string] $com, $value, [string] $column) {
    try {
        $updatecmd = $conn.CreateCommand()
        if ($value -is [int]) {
            $updatecmd.CommandText = "UPDATE [Monitoring].[KPI].[tbl_ServerDetails] SET {2} = {1} WHERE Alias_Name = '{0}'" -f $com, $value, $column
        }
        Elseif ($value -is [string]) {
            $updatecmd.CommandText = "UPDATE [Monitoring].[KPI].[tbl_ServerDetails] SET {2} = '{1}' WHERE Alias_Name = '{0}'" -f $com, $value, $column
        }
        $updatecmd.ExecuteNonQuery()
    }
    catch { Continue } 
}

$Pswd = ""
$User = ""

$secpasswd = ConvertTo-SecureString $Pswd -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($User, $secpasswd)

$linux_cores = "lscpu | awk 'NR==4{print `$2}'"
$linux_ram = "free -g | awk 'NR==2{print `$2}'"
$linux_os = "cat /etc/redhat-release"
$linux_manufacturer = "sudo dmidecode -s system-manufacturer"
$linux_serial_number = "sudo dmidecode -s system-serial-number"
$linux_model_id = "sudo dmidecode -s system-product-name"
$linux_processor = "cat /proc/cpuinfo | grep 'model name' | uniq | cut -d: -f2"
$linux_logical_processor = "cat /proc/cpuinfo | grep 'bogo' | wc -l"
$select = "SELECT Server_Name, CPU_Cores, Total_RAM, OS, Manufacturer, Serial_number, Model_ID, Alias_Name, Cluster_Name, Organizational_Unit, IP_Address, Processor, Logical_Processors FROM [Monitoring].[KPI].[tbl_ServerDetails]"
$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)

# Fetching data from SQL table
$conn.Open()
$selectcmd = $conn.CreateCommand()
$selectcmd.CommandText = $select
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $selectcmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

# Inserting data to SQL table
for ($i = 0; $i -lt $DataSet.Tables.Rows.Length; $i++) {
    if ($DataSet.Tables.Server_Name[$i].Substring(2, 1) -Match "t") {
        $SessionID = New-SSHSession -ComputerName $DataSet.Tables.Alias_Name[$i] -Credential $Credentials -AcceptKey:$true
        if ([string]::IsNullOrEmpty($DataSet.Tables.CPU_Cores[$i]) -or ($DataSet.Tables.CPU_Cores[$i] -eq 0)) {				
            $CPU_Cores = Invoke-SSH-Int $linux_cores
            $column = "CPU_Cores"
            SQL $DataSet.Tables.Alias_Name[$i] $CPU_Cores $column
        }
        if ([string]::IsNullOrEmpty($DataSet.Tables.Total_RAM[$i]) -or ($DataSet.Tables.Total_RAM[$i] -eq 0)) {				
            $Total_RAM = Invoke-SSH-Int $linux_ram
            $column = "Total_RAM"
            SQL $DataSet.Tables.Alias_Name[$i] $Total_RAM $column
        } 			
        if ([string]::IsNullOrEmpty($DataSet.Tables.OS[$i]) -or ($DataSet.Tables.OS[$i] -eq 0)) {				
            $OS = Invoke-SSH-String $linux_os
            $column = "OS"
            SQL $DataSet.Tables.Alias_Name[$i] $OS $column
        }
        if ([string]::IsNullOrEmpty($DataSet.Tables.Manufacturer[$i]) -or ($DataSet.Tables.Manufacturer[$i] -eq 0)) {				
            $Manufacturer = Invoke-SSH-String $linux_manufacturer
            $column = "Manufacturer"
            SQL $DataSet.Tables.Alias_Name[$i] $Manufacturer $column
        }			
        if ([string]::IsNullOrEmpty($DataSet.Tables.Serial_number[$i]) -or ($DataSet.Tables.Serial_number[$i] -eq 0)) {				
            $Serial_number = Invoke-SSH-String $linux_serial_number
            $column = "Serial_number"
            SQL $DataSet.Tables.Alias_Name[$i] $Serial_number $column
        }
        if ([string]::IsNullOrEmpty($DataSet.Tables.Model_ID[$i]) -or ($DataSet.Tables.Model_ID[$i] -eq 0)) {				
            $Model_ID = Invoke-SSH-String $linux_model_id
            $column = "Model_ID"
            SQL $DataSet.Tables.Alias_Name[$i] $Model_ID $column
        }
        if ([string]::IsNullOrEmpty($DataSet.Tables.IP_Address[$i]) -or ($DataSet.Tables.IP_Address[$i] -eq 0)) {				
            $IP_Address = [string]([System.Net.DNS]::GetHostAddresses($DataSet.Tables.Alias_Name[$i]) | Where-Object {$_.AddressFamily -eq "InterNetwork"} | select-object IPAddressToString)[0].IPAddressToString
            $column = "IP_Address"
            SQL $DataSet.Tables.Alias_Name[$i] $IP_Address $column
        }
        if ([string]::IsNullOrEmpty($DataSet.Tables.Processor[$i]) -or ($DataSet.Tables.Processor[$i] -eq 0)) {				
            $Processor = Invoke-SSH-String $linux_processor
            $column = "Processor"
            SQL $DataSet.Tables.Alias_Name[$i] $Processor $column
        }
		if ([string]::IsNullOrEmpty($DataSet.Tables.Logical_Processors[$i]) -or ($DataSet.Tables.Logical_Processors[$i] -eq 0)) {				
            $Logical_Processor = Invoke-SSH-Int $linux_logical_processor
            $column = "Logical_Processors"
            SQL $DataSet.Tables.Alias_Name[$i] $Logical_Processor $column
        }
    }	
}	

$conn.Close()
