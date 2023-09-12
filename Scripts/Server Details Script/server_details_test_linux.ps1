
# NOTE : Script requires Alias_Name as FQDN in ServerDetails2 table for fetching info.
# .NET Framework 4.7.2 or above required inorder to install module Posh-SSH for accessing linux servers

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

# Provide username and linux server FQDN as Alias_Name
$User = "vinodath"
$Pswd = Get-SecurePassword -PwdFile $parent_path\pwd.txt -KeyFile $parent_path\key.key

$Alias_Name = "g8t11518c.inc.hpicorp.net"
$Alias_Name_lwr = $Alias_Name.ToLower()
$Server_Name = $Alias_Name_lwr.Substring(0, $Alias_Name_lwr.IndexOf('.'))

$Credentials = New-Object System.Management.Automation.PSCredential($User, $Pswd)
$SessionID = New-SSHSession -ComputerName $Alias_Name_lwr -Credential $Credentials -AcceptKey:$true

$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@12345;Integrated Security=False'

$linux_cores = "lscpu | awk 'NR==4{print `$2}'"
$linux_ram = "free -g | awk 'NR==2{print `$2}'"
$linux_os = "cat /etc/redhat-release"
$linux_manufacturer = "cat /sys/devices/virtual/dmi/id/sys_vendor"
$linux_serial_number = "sudo dmidecode -s system-serial-number"
$linux_model_id = "cat /sys/devices/virtual/dmi/id/product_name"
$linux_processor = "cat /proc/cpuinfo | grep 'model name' | uniq | cut -d: -f2"
$linux_logical_processors = "cat /proc/cpuinfo | grep 'bogo' | wc -l"

try {
    if (-not(Get-Module -ListAvailable -Name Posh-SSH)) {
        Install-Module Posh-SSH -Force
        Set-Executionpolicy RemoteSigned
        Import-Module Posh-SSH
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

function IP_Address([string] $server) {
    try {
        [string]([System.Net.DNS]::GetHostAddresses($server) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | select-object IPAddressToString)[0].IPAddressToString
    }
    catch { 
        log_write $_.Exception
        return $null 
    } 
}

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
        log_write $_.Exception
        Continue
    } 
}

$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$conn.Open()

if ($Alias_Name_lwr.Substring(2, 1) -eq "t") {

    try {
        if (Test-Connection -ComputerName $Alias_Name_lwr -Count 1) {
            $CPU_Cores = Invoke-SSH $linux_cores "Int"
            $IP_Address = IP_Address $Alias_Name_lwr
            $Logical_Processors = Invoke-SSH $linux_logical_processors "Int"
            $Manufacturer = Invoke-SSH $linux_manufacturer "String"
            $Model_ID = Invoke-SSH $linux_model_id "String"
            $OS = Invoke-SSH $linux_os "String"
            $Processor = (Invoke-SSH $linux_processor "String").Trim()
            $Serial_number = Invoke-SSH $linux_serial_number "String"	
            $Total_RAM = Invoke-SSH $linux_ram "Int"
        }
    }
    catch { 
        log_write $_.Exception
        Continue
    }

    SQL $Alias_Name $CPU_Cores "CPU_Cores"
    SQL $Alias_Name $IP_Address "IP_Address"			
    SQL $Alias_Name $Logical_Processors "Logical_Processors"
    SQL $Alias_Name $Manufacturer "Manufacturer"			
    SQL $Alias_Name $Model_ID "Model_ID"			
    SQL $Alias_Name $OS "OS"				
    SQL $Alias_Name $Processor "Processor"		
    SQL $Alias_Name $Serial_number "Serial_number"			
    SQL $Alias_Name $Total_RAM "Total_RAM"	
    SQL $Alias_Name $Server_Name "Server_Name"
			
}

$conn.Close()

# Writing script run completion to log file
log_write "---------------------------------- Script Run Completed ----------------------------------"
