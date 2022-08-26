$results = foreach ( $ip in $ipaddress) {
    $org = Invoke-RestMethod -Uri "http://ipinfo.io/$ip"

                [PSCustomObject]@{
                    ipaddress = $ip
                    org       = $org.org
                }
            }

$results | Export-Csv -Path C:\Temp\ISP.csv
