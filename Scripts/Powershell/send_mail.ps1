
# Sending email from shared mailbox using application mailbox.
# Pre-req's:
# Application mailbox must be disabled for MFA (or have application password)
# Application mailbox must be enabled for SMTP authentication
# Application mailbox must have "Send As" permissions on shared mailbox

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

[System.Net.ServicePointManager]::SecurityProtocol = 'Tls,TLS11,TLS12'
$From = "feedback@gmail.com"
$To = "receiver@gmail.com"
$Subject = "<Subject>"
$Body = "<Body>"
$Path = "D:\attachment.txt";
$UserName = "user@gmail.com"
$Password = Get-SecurePassword -PwdFile .\MyPwd.txt -KeyFile .\MyKey.key
$Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist $UserName, $Password
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -Attachments $Path -Credential $Creds -SmtpServer 'smtp.gmail.com' -Port 587 -UseSsl
