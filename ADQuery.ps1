# This Script is designed to help with administration of user accounts that contain DNS names of computers that are disabled or have been removed from Active Directory

# 1. Prompts for username
# 2. The "LogonWorkstations" property is queried in AD and is stored as an array
# 3. Each machine in the new array is then queried against the "Enabled" property
# 4. A CSV file is created with the machine name and with it's associated "Enabled" value

#This script automatically returns a $false value for "InAD" if the machine isn't found at all using Try/Catch

function Get-LogonWorkstations {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$UserName
    )

    try {
        $Account = Get-AdUser -Identity $Username -Properties LogonWorkstations | Select-Object -ExpandProperty Logonworkstations
        Write-Verbose -Message ('Located user {0}' -f $UserName) 
    }
    catch {
        Throw ('Unable to locate user {0}' -f $UserName)
    }

    $output = $Account -split ',' | ForEach-Object {
        $computer = $_
        try {
            $adcomp = Get-ADComputer -Identity $_ -ErrorAction Stop | Select-Object -ExpandProperty Enabled
            if($adcomp -eq $true) { 
                [PSCustomObject]@{
                    MachineName = $computer
                    InAD        = $true
                }
            Write-Verbose ('{0} is enabled' -f $computer)
            }
            else {
                [PSCustomObject]@{
                    MachineName = $computer
                    InAD        = $false
            }
            Write-Verbose ('{0} is disabled' -f $computer)
        }
    }

        catch {
            [PSCustomObject]@{
                MachineName = $computer
                InAD        = $false
            }
            Write-Verbose ('Unable to locate machine {0}' -f $computer)
        }
    }

    $output | export-csv -path C:\Powershell\data.csv
}
