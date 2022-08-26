<#
This script requires the RSAT tool installed to authenticate with Active Directory.

1. Open PowerShell ISE
2. Copy the contents of this script into the Powershell window
3. Run


#Loads the System.Windows.Forms assembly (used to navigate to file via File Explorer)
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
$null = $FileBrowser.ShowDialog()


#Populates this variable with selected file through File Explorer (File must be a .csv)
$outlook_object = Import-CSV -Path $FileBrowser.FileName
#>

$results = foreach ($obj in $outlook_object) {

    #retrieves AD information for user
    Try{
    
        $user = Get-ADUser $obj.'From: (Address)' -Properties Title, displayNamePrintable, manager

        #retrieves AD information for manager (use of string manipulation to obtain manager eID) 
        $manager = Get-ADUser -Identity $user.manager.split("=,")[1] -Properties Title, displayNamePrintable, UserPrincipalName

        if ($obj.'To: (Address)' -like "*@*" ) {

            #Creates a Custom Powershell Object and stores pertinent information within object
            [PSCustomObject]@{
            Subject           = $obj.Subject
            User_email        = $user.UserPrincipalName
            User_Title        = $user.Title
            User_Name         = $user.displayNamePrintable
            Email_Destination = 'External'
            Email_sent_To     = $obj.'To: (Address)'
            Null              = $null
            Manager_email     = $manager.UserPrincipalName
            Manager_Title     = $manager.Title
            Manager_Name      = $manager.displayNamePrintable
            }
        }

        else{

            Try {
                $Email_Sent_To = get-aduser $obj.'To: (Address)' | Select-Object -ExpandProperty UserPrincipalName

                #Creates a Custom Powershell Object and stores pertinent information within object
                [PSCustomObject]@{
                Subject           = $obj.Subject
                User_email        = $user.UserPrincipalName
                User_Title        = $user.Title
                User_Name         = $user.displayNamePrintable
                Email_Destination = 'Internal'
                Email_sent_To     = $Email_Sent_To
                Null              = $null
                Manager_email     = $manager.UserPrincipalName
                Manager_Title     = $manager.Title
                Manager_Name      = $manager.displayNamePrintable
                }
            }

            Catch {
                $Sent_To = $obj.'To: (Address)'
                #Creates a Custom Powershell Object and stores pertinent information within object
                [PSCustomObject]@{
                Subject           = $obj.Subject
                User_email        = $user.UserPrincipalName
                User_Title        = $user.Title
                User_Name         = $user.displayNamePrintable
                Email_Destination = 'Internal'
                Email_sent_To     = 'UNABLE TO LOCATE ' + $Sent_To + ' IN ACTIVE DIRECTORY'
                Null              = $null
                Manager_email     = $manager.UserPrincipalName
                Manager_Title     = $manager.Title
                Manager_Name      = $manager.displayNamePrintable
                }
            }    
        }
    }

    Catch {
        [PSCustomObject]@{
            Subject           = $obj.Subject
            User_email        = 'INACTIVE AD ACCOUNT'
            User_Title        = $null
            User_Name         = $obj.'From: (Address)'
            Email_Destination = $null
            Email_sent_To     = $null
            Null              = $null
            Manager_email     = $null
            Manager_Title     = $null
            Manager_Name      = $null
        }
    }
}
 
$results | Export-Csv -Path C:\users\$env:USERNAME\Desktop\ESP_Violation.csv
