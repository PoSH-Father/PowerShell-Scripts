#This Script is designed to ping a remote machine to verify if it's turned on. Active Directory is used to verify the machine is active before attempting to ping
# 1. Prompts for file path containing machine names
# 2. The enabled property is checked for each machine using Foreach
# 3. If the Enabled property returns with "true" then a quiet ping is attempted
# 4. A custom PSObject is created and stores all output
# 5. Custom PSObject is saved as a CSV file

# Try/Catch is used to prevent pings for machine that is disabled or not in AD at all. The automatic value returned is false for these machines

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop')
Filter = 'Documents (*.txt)|*.txt' }

$null = $FileBrowser.ShowDialog()

$computer = get-content -path $filebrowser.FileName


$Results = foreach ($machine in $computer) {
    Try {
    $adcomp = Get-ADComputer -Identity $machine -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled

    [PSCustomObject]@{
        MachineName = $machine
        AD          = $adcomp
        PingTest    = $adcomp -and (Test-Connection -Computername $machine -quiet -count 1)
        }
    }
    catch{
            [PSCustomObject]@{
        MachineName = $machine
        AD          = $false
        PingTest    = $false
        }
    }
}


$Results | Export-Csv -Path C:\Powershell\PingAD.csv
