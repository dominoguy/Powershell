#SendingEmail


Function SendEmail {
    [CmdletBinding()]
    Param(
        [String]$Subject,
        [String]$Body,
        [String]$Attachments
    )

    $SMTPServer = "smtp.4web.ca"
    #$SMTPServer = "ri-exch-002.ri.ads"
    $SMTPUser = "smtp@renatus.ca"
    $SMTPPWD = "Gamma@Echo42"


    #$passwordLocation = "$PSScriptRoot\Password.txt"
    #$password = Get-Content $passwordLocation | ConvertTo-SecureString
    $password = $SMTPPWD
    $Port = "587"
    #$Port = "25"
    $From = "testsender@renatus.ca"
    $To = "brianlong@renatus.ca"
    
    $email = New-Object System.Net.Mail.MailMessage
    $email.From = $From
    $email.To.Add($To)
    $email.Subject = $Subject
    $email.Body = $Body
    $email.isBodyhtml = $true
    $smtp = New-Object Net.Mail.SmtpClient $SMTPServer,$Port
    $smtp.Credentials = New-Object System.Net.NetworkCredential ($SMTPUser,$password)
   
    $smtp.EnableSSL = $False
    $smtp.Port = 587
    $emailAttachment = New-Object Net.Mail.Attachment $Attachments
    $email.Attachments.add($emailAttachment)
    $smtp.Send($email)
    $emailAttachment.Dispose()
}

$attachment = "F:\Data\Scripts\Github\Powershell\EmployeeClockedIn\ITR-EmployeeClockedIn.txt"
$Subject = "This is a test 2"
$Body = "Don't look up"
$Attachments = $attachment



SendEmail $Subject $Body $Attachments