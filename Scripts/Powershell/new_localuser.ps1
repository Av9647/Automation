
# Provide password
$Password = Read-Host -AsSecureString

# Provide username, full name and description
New-LocalUser "User" -Password $Password -FullName "First User" -Description "Description of this account."
