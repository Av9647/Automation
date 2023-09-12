
function Get-UrlStatusCode([string] $Url) {
	try {
     (Invoke-WebRequest -Uri $Url -UseBasicParsing -DisableKeepAlive -Method head).StatusCode
	}
 catch [Net.WebException] {
		[int]$_.Exception.Response.StatusCode
	}
}

function Get-ResponseTime([string] $Url) {
	try {
     (Measure-Command -Expression { Invoke-WebRequest -Uri $Url -UseBasicParsing }).Milliseconds
	}
 catch [Net.WebException] {
		[int]$_.Exception.$null
	}
}

$select = @'
SELECT Endpoint_ID, Endpoint FROM [Powershell].[dbo].[Endpoints]
'@
$update = @'
UPDATE [Powershell].[dbo].[EndpointStatus2]
SET Timestamp = '{1}', Status = '{2}', ResponseTime = '{3}'
WHERE Endpoint_ID = '{0}'
'@

while ($true) {
	Try {

		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'
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
		$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		for ($i = 0; $i -lt $DataSet.Tables.Rows.Length; $i++) {
			$cmd = $conn.CreateCommand()
			$Status = Get-UrlStatusCode $DataSet.Tables.Endpoint[$i]
			$ResponseTime = Get-ResponseTime $DataSet.Tables.Endpoint[$i]
			$cmd.CommandText = $update -f $DataSet.Tables.Endpoint_ID[$i], $Timestamp, $Status, $ResponseTime
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

# CREATE TABLE EndpointStatus2 (
# [Timestamp] DATETIME not null,
# [Endpoint_ID] int not null,
# [Status] int not null,
# [ResponseTime] int not null
# )
