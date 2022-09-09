$computers = Get-Content -Path C:\Powershell\computers.txt

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -count 1 -quiet) {
        New-PSDrive -Name $computer -PSProvider FileSystem -Root \\$computer\c$
        Copy-Item -Path 'C:\Powershell\test.zip' -Destination ( '{0}:\Users\Public' -f $computer )
        }

    else {
        Write-Host $computer 'is offline'
        }
    }
