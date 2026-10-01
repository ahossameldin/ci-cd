$port = 5501

$connections = Get-NetTCPConnection `
    -LocalPort $port `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($connections) {

    foreach ($connection in $connections) {

        Write-Host "Stopping existing Green process:"
        Write-Host $connection.OwningProcess

        Stop-Process `
            -Id $connection.OwningProcess `
            -Force
    }

    Start-Sleep -Seconds 2
}
