#Quick check for "auto elevate" and "requires admin" executalbes in system32 via sigcheck. Will come back and edit on later date with instructions and details

$executables = Get-ChildItem -Path C:\Windows\System32 *.exe

$Pattern = '<autoElevate>true</autoElevate>', 'level="requireAdministrator'

$results = foreach ($program in $executables) {
    $sigcheck_results = C:\users\$username\Downloads\Sigcheck\sigcheck.exe -a -m $program.FullName | Select-String -Pattern $Pattern
    if($sigcheck_results) {
        [PSCustomObject]@{
            Program  = $program.FullName
            SigCheck = $sigcheck_results
        }
    }

    else {
        [PSCustomObject]@{
            Program  = $program.FullName
            SigCheck = 'No Auto Elevate'
        }
    }
}


$results | export-csv -Path C:\Users\$username\Desktop\sigcheck_full.csv
