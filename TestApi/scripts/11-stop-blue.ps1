$port = 5500

$connections = Get-NetTCPConnection `
    -LocalPort $port `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($connections) {

    foreach ($connection in $connections) {

        Write-Host "Stopping old API:"
        Write-Host "PID $($connection.OwningProcess)"

        Stop-Process `
            -Id $connection.OwningProcess `
            -Force
    }
}
