$results = foreach ($email in $email_list) {

    #Search AD for and find mail attribute that matches $email variable + grab additional Active Directory User attributes
    $Shared_mailbox = Get-ADUser -Filter { mail -eq $email } -Properties mail, manager

    #(-ne) is "not equal" -> If Shared_mailbox variable is not empty then...
    If ($Shared_mailbox -ne $null) {
        #Enumerate manager details for shared mailbox. Requires string manipulation
        $manager = Get-ADUser -Identity $Shared_mailbox.Manager.split("=,")[1] -Properties Title, displayNamePrintable, UserPrincipalName

        [PSCustomObject]@{
            Shared_Mailbox      = $email
            AD_Mail_Attribute   = $Shared_mailbox
            Manager_eID         = $manager.Name
            Manager_Title       = $manager.Title
            Manager_Email       = $manager.UserPrincipalName
        }
    }
    else {
        [PSCustomObject]@{
            Shared_Mailbox      = $email
            AD_Mail_Attribute   = 'Could not find in Active Directory'
            Manager_eID         = $null
            Manager_Title       = $null
            Manager_Email       = $null
        }
    }
}

$results | Export-Csv -Path C:\users\$env:USERNAME\Desktop\shared_mailbox_owners.csv
