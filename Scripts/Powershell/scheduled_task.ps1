
# Specify location of script to run
$Action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NonInteractive -NoLogo -NoProfile -File "C:\temp\SQL-Transfer.ps1"'

# Provide repetition interval for running script
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1)
$Settings = New-ScheduledTaskSettingsSet
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings

# Provide user account credentials to register scheduled task
Register-ScheduledTask -TaskName 'SQL-Transfer' -InputObject $Task -User 'VinodAth_Adm' -Password 'cA6iEbqklOvyfg7YjDUJWPC%_r' -Description "This task sends performance metrics to a SQL table."

# Run the Get-ScheduledTask cmdlet to see the task
Get-ScheduledTask -TaskName 'SQL-Transfer'
