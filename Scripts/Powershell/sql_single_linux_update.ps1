# $ErrorActionPreference = "SilentlyContinue"
if (-not(Get-Module -ListAvailable -Name Posh-SSH)) {
    Install-Module Posh-SSH -Force
	Set-Executionpolicy RemoteSigned
    Import-Module Posh-SSH
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
$User = " "
$Pswd = " "
$Alias_Name = "g7t00196g.inc.hpicorp.net"
$secpasswd = ConvertTo-SecureString $Pswd -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($User, $secpasswd)
$SessionID = New-SSHSession -ComputerName $Alias_Name -Credential $Credentials -AcceptKey:$true	
$linux_cores = "lscpu | awk 'NR==4{print `$2}'"
$linux_ram = "free -g | awk 'NR==2{print `$2}'"
$linux_os = "cat /etc/redhat-release"
$linux_manufacturer = "sudo dmidecode -s system-manufacturer"
$linux_serial_number = "sudo dmidecode -s system-serial-number"
$linux_model_id = "sudo dmidecode -s system-product-name"
$linux_processor = "cat /proc/cpuinfo | grep 'model name' | uniq | cut -d: -f2"
$linux_logical_processor = "cat /proc/cpuinfo | grep 'bogo' | wc -l"
$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$conn.Open()
if ($Alias_Name.Substring(2, 1) -Match "t") {	
$CPU_Cores = Invoke-SSH-Int $linux_cores
$IP_Address = [string]([System.Net.DNS]::GetHostAddresses($Alias_Name) | Where-Object {$_.AddressFamily -eq "InterNetwork"} | select-object IPAddressToString)[0].IPAddressToString
$Logical_Processor = Invoke-SSH-Int $linux_logical_processor
$Manufacturer = Invoke-SSH-String $linux_manufacturer
$Model_ID = Invoke-SSH-String $linux_model_id
$OS = Invoke-SSH-String $linux_os
$Processor = Invoke-SSH-String $linux_processor
$Serial_number = Invoke-SSH-String $linux_serial_number		
$Total_RAM = Invoke-SSH-Int $linux_ram
$column1 = "CPU_Cores"
$column2 = "IP_Address"
$column3 = "Logical_Processors"
$column4 = "Manufacturer"
$column5 = "Model_ID"
$column6 = "OS"
$column7 = "Processor"
$column8 = "Serial_number"
$column9 = "Total_RAM"
SQL $Alias_Name $CPU_Cores $column1
SQL $Alias_Name $IP_Address $column2			
SQL $Alias_Name $Logical_Processor $column3
SQL $Alias_Name $Manufacturer $column4			
SQL $Alias_Name $Model_ID $column5			
SQL $Alias_Name $OS $column6				
SQL $Alias_Name $Processor $column7			
SQL $Alias_Name $Serial_number $column8			
SQL $Alias_Name $Total_RAM $column9			
}	
$conn.Close()