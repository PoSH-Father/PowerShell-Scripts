###
# This script is used to enumerate SMB shares in an AD enterprise environment and also parses accessible files for keywords
# Adjust certain parameters like $extensions or $pattern variables to change targets
# Leverages mulitple .NET modules for efficiency
###

# Loads the System.Windows.Forms assembly (used to navigate to file via File Explorer)
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
$null = $FileBrowser.ShowDialog()


# Populates this variable with selected file through File Explorer (File must be a .txt)
$servers = Get-Content -Path $FileBrowser.FileName

# Request Output file name (Name must inlcude .csv extension)
$Output= Read-Host -Prompt "Enter Output file name and include .csv extension (Example_File.csv)"

# Progress Bar Variables
$TotalItems = $servers.count
$CurrentItem = 0
$PercentComplete = 0

# ----------------------------------------------------------------------
# Enumerate computers that have TCP 445 open
# ----------------------------------------------------------------------

$Computers445Open = foreach($server in $servers) {

    Write-Progress -Activity "Checking SMB status $CurrentItem\$TotalItems" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
    $CurrentItem++
    $PercentComplete = [int](($CurrentItem / $TotalItems) * 100) 

    $ComputerPingable = Test-Connection -Computername $server -quiet -count 1

    if($ComputerPingable) {
        try {                      
            $Socket = New-Object System.Net.Sockets.TcpClient($Server,"445")   
                if($Socket.Connected) {
                    $Status = "Open"             
                    $Socket.Close()
                    Write-Host "Port 445 on $Server is open"
                }
                else {
                    $Status = "Closed"
                    Write-Host "Port 445 on $Server is closed"    
                }
        }
        catch {
            $Status = "Closed"
        }   

        if($Status -eq "Open") {            
            [PSCustomObject]@{  
                SERVER     = $Server
                SMB_STATUS = $Status                      
            }
        }
    }
}

# Progress Bar Reset
$TotalItems = $Computers445Open.SERVER.count
$CurrentItem = 0
$PercentComplete = 0

# ----------------------------------------------------------------------
# Enumerate SMB shares
# ----------------------------------------------------------------------

$Computer_Shares = foreach($server in $Computers445Open.SERVER) {

    Write-Progress -Activity "Enumerating Shares $CurrentItem\$TotalItems" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
    $CurrentItem++
    $PercentComplete = [int](($CurrentItem / $TotalItems) * 100) 

    $shares = net view \\$server | ConvertFrom-String -PropertyNames Share_Name, Share_Type
    foreach($share in $shares) {
        if ($share.Share_Type -eq 'Disk' -and $share.Share_Name -ne 'Icinga') {
            Write-Host $share.Share_Name "found on $server"
            [PSCustomObject]@{
                SERVER     = $Server
                SHARE_NAME = $share.Share_Name
            }
        }
    }
}

# Progress Bar Reset
$TotalItems = $Computer_Shares.SHARE_NAME.count
$CurrentItem = 0
$PercentComplete = 0

# ----------------------------------------------------------------------
# Enumerate ACLs for SMB shares
# ----------------------------------------------------------------------

# These variables are just for reference
$IDReferences = @('MBULOGIN\Domain Users', 'Everyone', 'BUILTIN\Users', 'NT AUTHORITY\Authenticated Users', 
'NT AUTHORITY\ANONYMOUS LOGON', 'DOMAINNAME\Domain Computers')
$FileSystemRights = @('FullControl' , 'ReadAndExecute, Synchronize', 'Modify, Synchronize', '-1610612736', 'AppendData', 
'CreateFiles', '268435456', 'Read, Synchronize', 'Write, ReadAndExecute, Synchronize', 'CreateFiles, Synchronize', 
'AppendData, Synchronize', '1610809791', 'Write', '-536805376', 'DeleteSubdirectoriesAndFiles, Modify, Synchronize', 
'-536805306', 'CreateFiles, AppendData, Synchronize', 'CreateFiles, WriteExtendedAttributes, WriteAttributes, ReadAndExecute, Synchronize', 
'CreateFiles, AppendData', '1880031743', 'CreateFiles, AppendData, ReadAndExecute, Synchronize', 'Write, Read, Synchronize')

$Share_ACLs = foreach ($share in $Computer_Shares) {

    Write-Progress -Activity "Enumerating ACLs for share # $CurrentItem out of $TotalItems" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
    $CurrentItem++
    $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)

    Try {
        $Acl = Get-Acl -Path "\\$($share.SERVER)\$($share.SHARE_NAME)" -ErrorAction Stop
        Write-Host "found ACL for" $Share.SHARE_NAME "on" $share.SERVER
        $Has_Access = $true
    }

    Catch { 
        $Has_Access = $false
        Write-Host "Can't access ACL for" $Share.SHARE_NAME "on" $share.SERVER
    }

    if($Has_Access) {
         
        foreach($accessRule in $Acl.Access) { 
            [PSCustomObject]@{
                SERVER     = $share.SERVER
                SHARE_NAME = $share.SHARE_NAME
                Account    = $accessRule.IdentityReference
                Permission = $accessRule.FileSystemRights
                HashCode   = $accessRule.GetHashCode()
            }
        }
    }
}

# ----------------------------------------------------------------------
# Obtain ACLS with Account NT Authority System for metadata gathering
# ----------------------------------------------------------------------

$NTAuthACLs = foreach ($ACL in $share_ACLS) {
    if($ACL.Account -eq 'NT AUTHORITY\SYSTEM') {
        [PSCustomObject]@{
            SERVER     = $ACL.SERVER
            SHARE_NAME = $ACL.SHARE_NAME
        }
    }
}

# Progress Bar Reset
$TotalItems = $NTAuthACLs.count
$CurrentItem = 0
$PercentComplete = 0

# ----------------------------------------------------------------------
# Enumerate metadata for SMB shares
# ----------------------------------------------------------------------

$MetaData = foreach ($ACL in $NTAuthACLs) {
    
    Write-Progress -Activity "Gathering Metadata for share # $CurrentItem out of $TotalItems" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
    $CurrentItem++
    $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)

    Try {
        $SERVER = $ACL.SERVER
        $SHARE = $ACL.SHARE_NAME
        $Share_Metadata = ([System.IO.DirectoryInfo] "\\$($ACL.SERVER)\$($ACL.SHARE_NAME)").EnumerateFiles('*', 'AllDirectories')
        Write-Host $ACL.SHARE_NAME "has" ($Share_Metadata | Measure-Object | Select-Object -ExpandProperty Count) "files on $ACL.SERVER"
        $File_Count = $true
    }
    Catch {
        Write-Host "Don't have access to" $ACL.SHARE_NAME "on" $ACL.SERVER
        $File_Count = $false
    }
    

    if($File_Count) {
        [PSCustomObject]@{
            SERVER     = $ACL.SERVER
            SHARE_NAME = $ACL.SHARE_NAME
            File_Count = $Share_Metadata | Measure-Object | Select-Object -ExpandProperty Count
            Files      = $Share_Metadata.FullName
        }
    }
}

$TotalItems=$Metadata.count
$CurrentItem = 0
$PercentComplete = 0

# ----------------------------------------------------------------------
# Parse All accessible files
# ----------------------------------------------------------------------

# Add or remove extension that you want to be checked
$extensions = @(".ps1", ".py", ".ini", ".conf", ".yaml", ".sh", ".txt")

$TotalItems=$Metadata.Files.count
$CurrentItem = 0
$PercentComplete = 0

# Add or remove patterns that you want to be checked
$Patterns = "password =", "password=", "username=","username =", "apikey", "api_key", "PRIVATE KEY"

$File_Parse = foreach ($file in $Metadata.Files){

    Write-Progress -Activity "Parsing Files for sensitive information disclousure for file # $CurrentItem out of $TotalItems" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
    $CurrentItem++
    $PercentComplete = [int](($CurrentItem / $TotalItems) * 100)

    if([IO.Path]::GetExtension($file) -in $extensions ) {
        Write-Host $file
        $Data_in_File = Select-String -Pattern $Patterns -Path $file
        Write-Host $Data_in_File
        if($Data_in_file){
            Write-Host "Sensitive Information found"
            foreach ($hit in $Data_in_File){
                [PSCustomObject] @{
                    FILEPATH    = $File
                    Regex_Match = $hit.Matches.Value
                    SERVER      = ($file.split("\"))[2]
                    SHARE_NAME  = ($file.split("\"))[3]
                }
            }
        }
    }
}


# ----------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------

$Share_ACLs_Output = 'Share_ACLs_' + $Output
$Share_ACLs | Export-Csv -Path C:\users\$env:USERNAME\Desktop\$Share_ACLs_Output

$SensitiveData_Output = 'Sensitive_Data_' + $Output
$File_Parse | Export-Csv -Path C:\users\$env:USERNAME\Desktop\$SensitiveData_Output

$MetaData_Output = 'Metadata_' + $Output
$Metadata | Export-Csv -Path C:\users\$env:USERNAME\Desktop\$Metadata_Output

$Shares_Output = 'Shares_' + $Output
$Computer_Shares | Export-Csv -Path C:\users\$env:USERNAME\Desktop\$Shares_Output_Output
