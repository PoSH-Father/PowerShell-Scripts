$listenerIP = '0.0.0.0'
$listenerPort = 4444

$listener = New-Object System.Net.Sockets.TcpListener([IPAddress]::Parse($listenerIP), $listenerPort)
$listener.Start()

Write-Host "Listening on port $listenerPort..."

$client = $listener.AcceptTcpClient()
$stream = $client.GetStream()
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

Write-Host "Connection received!"

while ($true) {
    $receivedData = $reader.ReadLine()
    Write-Host $receivedData
    $response = Read-Host
    $writer.WriteLine($response)
}

$client.Close()
$listener.Stop()
