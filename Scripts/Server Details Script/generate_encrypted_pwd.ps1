
# Function to generate key file
function New-KeyFile {

    [cmdletbinding()]

    param(
        [string]$KeyFile,
        [ValidateSet(16, 24, 32)]
        [int]$KeySize,
        [switch]$Force
    )

    if ( (Test-Path $KeyFile) -and (-not $Force) ) {
        throw "File path provided already exist, use [-Force] if you wish to overwrite the file."
    }

    $genKey = New-Object Byte[] $KeySize
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($genKey)
    $genKey | out-file $KeyFile

}

# Function to generate encrypted password file
function New-PasswordFile {

    [cmdletbinding()]
    param(
        [string]$PwdFile,
        [SecureString]$Password = (Read-Host -Prompt "Enter the password to add to the file" -AsSecureString),
        [Byte[]]$Key,
        [switch]$Force
    )

    if ( (Test-Path $PwdFile) -and (-not $Force) ) {
        throw "File path provided already exist, use [-Force] if you wish to overwrite the file."
    }

    ConvertFrom-SecureString -SecureString $Password -Key $Key | Out-File $PwdFile

}

# Function to retrieve password from encrypted file
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

$parent_path = Split-Path $MyInvocation.MyCommand.Path -Parent

# Creating key file
New-KeyFile -KeyFile $parent_path\key.key -KeySize 16 -Force

# Creating password file
New-PasswordFile -PwdFile $parent_path\pwd.txt -Key (Get-Content $parent_path\key.key) -Force
