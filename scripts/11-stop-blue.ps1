$port = $env:OLD_PORT

if ([string]::IsNullOrWhiteSpace($port)) {
    throw "OLD_PORT is empty. Did 00-detect-ports.ps1 run?"
}

Write-Host "Stopping old port: $port"

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
else {
    Write-Host "Nothing listening on old port $port."
}
