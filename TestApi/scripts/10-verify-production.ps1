$url = "http://127.0.0.1/api/health"

$healthy = $false

for ($i = 1; $i -le 15; $i++) {

    try {

        $response = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -TimeoutSec 3

        if ($response.StatusCode -eq 200) {

            Write-Host "Production is healthy."

            $healthy = $true
            break
        }

    }
    catch {

        Write-Host "Production check attempt $i failed."
    }

    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    throw "Production verification failed."
}
