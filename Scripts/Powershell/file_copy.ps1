
# Create new powershell session between target server
$session = New-PSSession g7w00856a.corp.hpicloud.net

# Specify source directory/file to copy and target directory
Copy-Item -FromSession $session E:\Servers.txt -Destination D:\
