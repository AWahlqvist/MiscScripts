# Fetch my mobile device name
$DeviceName = Get-AutomationVariable -Name 'MyDeviceName'

# Fetch my iCloud Credential
$iCloudCred = Get-AutomationPSCredential -Name 'iCloudCredential'

# Let's start with fetching my location details
$MyDeviceLocation = Get-AppleDeviceLocation -Credential $iCloudCred | Where-Object { $_.DeviceName -eq $DeviceName }

# Check if we got a lock
if (!$MyDeviceLocation) {
    # Sometimes it takes longer for the device to locate, let's wait and try again
    Start-Sleep -Seconds 60
    $MyDeviceLocation = Get-AppleDeviceLocation -Credential $iCloudCred | Where-Object { $_.DeviceName -eq $DeviceName }

    if (!$MyDeviceLocation) {
        throw "Failed to fetch the location of device $DeviceName"
    }
}

# Time to get a weather report for my location
$CurrentWeather = $MyDeviceLocation | Get-SMHIWeatherData | Where-Object { [datetime] $_.ForecastEndDate -lt (Get-Date).AddHours(2) }

if ($CurrentWeather.PrecipitationCategory -contains 'Rain') {

    <# Since the weather is bad, let's send a e-mail with a webhook for starting the coffee brewer
       Note: Sending a webhook over e-mail is a BAD idea (huge security risk depending on the runbook),
       this is just for demo purposes.
    #>

    $WepageLink = Get-AutomationVariable -Name 'StartCoffeeBrewerPage'

# Set the body
$body = @"
Hi,<BR>
<BR>
Since the weather seems to be bad at your current location, I thought you might feel a bit cold.<BR>
<BR>
If you feel a nice cup of coffee would help, just follow <a href='$WepageLink'>this link</A> and press the button on the page and I'll start the coffee brewer for you!<BR>
<BR>
Kind regards,<BR>
Jarvis, running in Azure Automation<BR>
"@

    $MailMessageParams = @{
        'To' = Get-AutomationVariable -Name 'MyEmailAddress'
        'From' = "Jarvis <$($SMTPCred.UserName)>"
        'Subject' = 'Would you like some coffee?'
        'Body' = $body
        'UseSsl' = $true
        'Port' = Get-AutomationVariable -Name 'SMTPServerPort'
        'SmtpServer' = Get-AutomationVariable -Name 'SMTPServer'
        'Credential' = Get-AutomationPSCredential -Name 'SMTPAuthCredential'
        'BodyAsHtml' = $true
    }

    Send-MailMessage @MailMessageParams
}
