
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

$Endpoints = Get-Content -Path "D:\Endpoints.csv"

# Prepare Insert Statement
$insert = @'
INSERT INTO [Powershell].[dbo].[EndpointStatus]
(Timestamp, Env, Service, Status, ResponseTime)
VALUES ('{0}','{1}','{2}','{3}','{4}')
'@

while ($true) {
	Try {

		# Define connection string of target database. Connection String might include Uid, Password
		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'

		# connection object initialization
		$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)

		# Open the Connection 
		$conn.Open()
		$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		foreach ($endpoint in $Endpoints) {		
    
			# Prepare the SQL 
			$cmd = $conn.CreateCommand()
			$URL = $endpoint.Split(" ")
			$Status = Get-UrlStatusCode $URL[2]
			$ResponseTime = Get-ResponseTime $URL[2]
			$cmd.CommandText = $insert -f $Timestamp, $URL[1], $URL[0], $Status, $ResponseTime
			$cmd.ExecuteNonQuery()

		}
		# Close the connection
		$conn.Close()
	}
	Catch {
		Throw $_
	}
	Start-Sleep -s 60
}

################################################################################################################################################################

# CREATE TABLE EndpointStatus (
# [Timestamp] DATETIME not null,
# [Env] VARCHAR(40) not null,
# [Service] VARCHAR(40) not null,
# [Status] smallint not null,
# [ResponseTime] int not null
# )
