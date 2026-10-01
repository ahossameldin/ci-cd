$port = $env:NEW_PORT

if ([string]::IsNullOrWhiteSpace($port)) {
    throw "NEW_PORT is empty. Did 00-detect-ports.ps1 run?"
}

Write-Host "Preparing new port: $port"

$connections = Get-NetTCPConnection `
    -LocalPort $port `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($connections) {

    foreach ($connection in $connections) {

        Write-Host "Stopping existing process on port ${port}:"
        Write-Host $connection.OwningProcess

        Stop-Process `
            -Id $connection.OwningProcess `
            -Force
    }

    Start-Sleep -Seconds 2
}
else {
    Write-Host "Port $port is free."
}
