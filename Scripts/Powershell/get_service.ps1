
while ($true) {
	
	$Services = Get-Content -Path "E:\Services.csv"	

	# Prepare Insert Statement
	$insert = @'
	INSERT INTO [Powershell].[dbo].[ServiceStatus]
	(Timestamp, Server, Service, Status)
	VALUES ('{0}','{1}','{2}','{3}')
'@

	Try {

		# Define connection string of target database. Connection String might include Uid, Password
		$connectionString = 'Data Source=g7w11235g.inc.hpicorp.net,2048;Initial Catalog=Powershell;Uid=powershell_user;Password=powershell@123;Integrated Security=False'

		# connection object initialization
		$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)

		# Open the Connection 
		$conn.Open()

		$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

		foreach ($Service in $Services) {		

			# Prepare the SQL 
			$cmd = $conn.CreateCommand()
			$S = $Service.Split(" ")
			if (Get-Service $S[1] -ComputerName $S[0] -ErrorAction SilentlyContinue) {
				$Status = (Get-Service $S[1] -ComputerName $S[0] -ErrorAction SilentlyContinue).Status
			}
			else {
				$Status = "Not Found"
			}
			$cmd.CommandText = $insert -f $Timestamp, $S[0], $S[1], $Status
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

# if ($Status = "Stopped") {
# 	Get-Service $S[1] -ComputerName $S[0]| Start-Service
# 	} else {
# 		break
# 	}
	
################################################################################################################################################################

# CREATE TABLE ServiceStatus (
# [Timestamp] DATETIME not null,
# [Server] VARCHAR(40) not null,
# [Service] VARCHAR(40) not null,
# [Status] VARCHAR(10) not null
# )
