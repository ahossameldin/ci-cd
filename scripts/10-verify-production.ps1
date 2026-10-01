$caddyAdmin = "http://127.0.0.1:2019"

# Use Caddy's actual public listen port (yours is :5042, not :80)
$publicPort = 80

try {
    $config = Invoke-RestMethod `
        -Uri "$caddyAdmin/config/" `
        -Method Get `
        -TimeoutSec 5

    $listen = $config.apps.http.servers.srv0.listen | Select-Object -First 1

    if ($listen -match ":(\d+)$") {
        $publicPort = $Matches[1]
    }
}
catch {
    Write-Host "Could not read Caddy listen port, defaulting to 80: $($_.Exception.Message)"
}

$url = "http://127.0.0.1:${publicPort}/health"

Write-Host "Verifying production through Caddy: $url"

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

        Write-Host "Production check attempt ${i} failed: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    throw "Production verification failed."
}
