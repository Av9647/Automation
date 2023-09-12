
$ErrorActionPreference = "SilentlyContinue"

$select = "SELECT Server_ID, Alias_Name FROM [Monitoring].[KPI].[tbl_ServerDetails2]"
$insert = "INSERT INTO [Monitoring].[KPI].[tbl_Server_Status_History] (Date_time, Server_ID, Status) VALUES ('{0}','{1}','{2}')"

while ($true) {

	try {

		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Monitoring;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
		$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
		$conn.Open()
		$selectcmd = $conn.CreateCommand()
		$selectcmd.CommandText = $select
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $selectcmd
		$DataSet = New-Object System.Data.DataSet
		$SqlAdapter.Fill($DataSet)

		for ($i = 0; $i -lt $DataSet.Tables.Rows.Length; $i++) {
			if ($null -eq (Test-Connection $DataSet.Tables.Alias_Name[$i] -Count 1)) {
				$Status = 1
			}
			else {
				$Status = 0
			}	

			$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			$cmd = $conn.CreateCommand()
			$cmd.CommandText = $insert -f $Timestamp, $DataSet.Tables.Server_ID[$i], $Status
			$cmd.ExecuteNonQuery()

		}
		$conn.Close()
	}
	Catch {
		Throw $_
	}
	Start-Sleep -s 60
}
