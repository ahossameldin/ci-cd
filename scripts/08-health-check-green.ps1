$newPort = $env:NEW_PORT

if ([string]::IsNullOrWhiteSpace($newPort)) {
    throw "NEW_PORT is empty. Did 00-detect-ports.ps1 run?"
}

$url = "http://127.0.0.1:${newPort}/health"

$healthy = $false

for ($i = 1; $i -le 30; $i++) {

    try {

        $response = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -TimeoutSec 3

        if ($response.StatusCode -eq 200) {

            Write-Host "Port $newPort is healthy."

            $healthy = $true
            break
        }

    }
    catch {

        Write-Host "Attempt ${i}: API on port $newPort not ready."
    }

    Start-Sleep -Seconds 2
}

if (-not $healthy) {

    Write-Host "Port $newPort failed health check."

    $stderr = "C:\Deploy\Logs\port-$newPort-$env:RELEASE_VERSION.stderr.log"

    if (Test-Path $stderr) {
        Get-Content $stderr -Tail 100
    }

    throw "Deployment aborted."
}
