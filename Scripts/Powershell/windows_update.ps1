
Install-Module -Name PSWindowsUpdate
Import-Module -Name PSWindowsUpdate
Get-WindowsUpdate -KBArticleID KB2467173,KB2538242,KB2726958 -Install 

Get-WUHistory | Select-Object -Property * -First 10
Get-WindowsUpdate -KBArticleID KB2467173,KB2538242,KB2726958 -IsInstalled

#Status -DI--U- if updated
#Status -DI---- if not updated

#To fix windows update, open cmd in admin mode :
#net stop wuauserv
#net start wuauserv
