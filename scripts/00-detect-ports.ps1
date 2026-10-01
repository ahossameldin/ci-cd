$caddyAdmin = "http://127.0.0.1:2019"

$livePort = $null

# Collect all upstream dial values from Caddy config
function Find-LivePort {
    param ([object]$Node)

    if ($null -eq $Node) {
        return
    }

    if ($Node -is [System.Collections.IDictionary]) {
        foreach ($key in @($Node.Keys)) {
            $value = $Node[$key]
            if ($key -eq "upstreams") {
                foreach ($upstream in $value) {
                    $dial = $upstream.dial
                    if ($dial -match ":5500$") {
                        $script:livePort = 5500
                        return
                    }
                    if ($dial -match ":5501$") {
                        $script:livePort = 5501
                        return
                    }
                }
            }
            Find-LivePort $value
            if ($script:livePort) {
                return
            }
        }
    }
    elseif ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) {
            Find-LivePort $item
            if ($script:livePort) {
                return
            }
        }
    }
}

try {
    $config = Invoke-RestMethod `
        -Uri "$caddyAdmin/config/" `
        -Method Get `
        -TimeoutSec 5

    Find-LivePort $config

    if ($livePort) {
        Write-Host "Caddy live port: $livePort"
    }
    else {
        Write-Host "No 5500/5501 upstream found in Caddy config."
    }
}
catch {
    Write-Host "Could not query Caddy admin API, falling back to listening ports."
    Write-Host $_
}

if (-not $livePort) {
    $listening5500 = Get-NetTCPConnection `
        -LocalPort 5500 `
        -State Listen `
        -ErrorAction SilentlyContinue

    $listening5501 = Get-NetTCPConnection `
        -LocalPort 5501 `
        -State Listen `
        -ErrorAction SilentlyContinue

    if ($listening5500 -and -not $listening5501) {
        $livePort = 5500
        Write-Host "Only 5500 listening, treating it as live."
    }
    elseif ($listening5501 -and -not $listening5500) {
        $livePort = 5501
        Write-Host "Only 5501 listening, treating it as live."
    }
    else {
        # First deploy (neither listening) or ambiguous (both listening):
        # default to 5500 live so we deploy to 5501.
        $livePort = 5500
        Write-Host "Fallback: assuming live=5500, new=5501."
    }
}

if ($livePort -eq 5500) {
    $newPort = 5501
}
else {
    $newPort = 5500
}

$oldPort = $livePort

Write-Host "Live port: $oldPort"
Write-Host "New port:  $newPort"

"LIVE_PORT=$oldPort" >> $env:GITHUB_ENV
"OLD_PORT=$oldPort" >> $env:GITHUB_ENV
"NEW_PORT=$newPort" >> $env:GITHUB_ENV
