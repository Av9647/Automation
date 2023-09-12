
Get-Service | Select-Object -Property Name,Status,@{Name = 'Timestamp';

Expression = { Get-Date -Format 'MM-dd-yy hh:mm:ss' }} | Export-Excel D:\ServiceStates.xlsx -WorksheetName 'Services'
