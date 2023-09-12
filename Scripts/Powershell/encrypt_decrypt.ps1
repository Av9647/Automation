
# Encrypting script 
$Code = Get-Content C:\Scripts\MyCode.txt
$CodeSecureString = ConvertTo-SecureString $Code -AsPlainText -Force
$Encrypted = ConvertFrom-SecureString -SecureString $CodeSecureString
$Encrypted | Out-File -FilePath C:\Scripts\Encrypted.txt

# Decrypting and running script
$Instructions = Get-Content C:\Scripts\Encrypted.txt
$Decrypt = $Instructions | ConvertTo-SecureString
$Code = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Decrypt))
Invoke-Expression $Code
