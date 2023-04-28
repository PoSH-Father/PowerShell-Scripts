# Path to the zip file containing justaprogram.exe (nc.exe)
$zipFilePath = "C:\path\to\your\justaprogram.zip"

# Path to the folder where you want to extract justaprogram.exe (nc.exe)
$extractPath = "C:\path\to\extract"

# Extract justaprogram.exe (nc.exe) from the zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $extractPath)

# Set the path to the extracted justaprogram.exe (nc.exe)
$justAProgramPath = Join-Path $extractPath "justaprogram.exe"

# Launch a simple listener on port 9001 using justaprogram.exe (nc.exe)
& $justAProgramPath -l -p 9001
