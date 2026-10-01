$url = "http://127.0.0.1:5501/health"

$healthy = $false

for ($i = 1; $i -le 30; $i++) {

    try {

        $response = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -TimeoutSec 3

        if ($response.StatusCode -eq 200) {

            Write-Host "Green is healthy."

            $healthy = $true
            break
        }

    }
    catch {

        Write-Host "Attempt $i: API not ready."
    }

    Start-Sleep -Seconds 2
}

if (-not $healthy) {

    Write-Host "Green failed health check."

    $stderr = "C:\Deploy\Logs\green-$env:RELEASE_VERSION.stderr.log"

    if (Test-Path $stderr) {
        Get-Content $stderr -Tail 100
    }

    throw "Deployment aborted."
}
