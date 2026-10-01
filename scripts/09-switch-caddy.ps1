$caddyAdmin = "http://127.0.0.1:2019"

$oldPort = $env:OLD_PORT
$newPort = $env:NEW_PORT

if ([string]::IsNullOrWhiteSpace($oldPort) -or [string]::IsNullOrWhiteSpace($newPort)) {
    throw "OLD_PORT/NEW_PORT is empty. Did 00-detect-ports.ps1 run? OLD='$oldPort' NEW='$newPort'"
}

Write-Host "Switching Caddy: $oldPort -> $newPort"
Write-Host "Getting current Caddy configuration..."

$config = Invoke-RestMethod `
    -Uri "$caddyAdmin/config/" `
    -Method Get

$script:switched = 0
$script:alreadyOnNew = $false

function Replace-Upstream {
    param (
        [object]$Node
    )

    if ($null -eq $Node) {
        return
    }

    if ($Node -is [System.Collections.IDictionary]) {

        foreach ($key in @($Node.Keys)) {

            $value = $Node[$key]

            if ($key -eq "upstreams") {

                foreach ($upstream in $value) {

                    if ($upstream.dial -match ":$oldPort$") {

                        Write-Host "Switching dial $($upstream.dial) -> port $newPort"

                        $upstream.dial = ($upstream.dial -replace ":\d+$", ":$newPort")
                        $script:switched++
                    }
                    elseif ($upstream.dial -match ":$newPort$") {
                        $script:alreadyOnNew = $true
                    }
                }
            }

            Replace-Upstream $value
        }
    }

    elseif ($Node -is [System.Management.Automation.PSCustomObject]) {

        foreach ($prop in $Node.PSObject.Properties) {

            if ($prop.Name -eq "upstreams") {

                foreach ($upstream in $prop.Value) {

                    if ($upstream.dial -match ":$oldPort$") {

                        Write-Host "Switching dial $($upstream.dial) -> port $newPort"

                        $upstream.dial = ($upstream.dial -replace ":\d+$", ":$newPort")
                        $script:switched++
                    }
                    elseif ($upstream.dial -match ":$newPort$") {
                        $script:alreadyOnNew = $true
                    }
                }
            }

            Replace-Upstream $prop.Value
        }
    }

    elseif (
        $Node -is [System.Collections.IEnumerable] -and
        $Node -isnot [string]
    ) {

        foreach ($item in $Node) {
            Replace-Upstream $item
        }
    }
}

Replace-Upstream $config

if ($script:switched -eq 0) {
    if ($script:alreadyOnNew) {
        Write-Host "Caddy already points to new port $newPort. Nothing to switch."
        return
    }
    throw "No upstream with port $oldPort found in Caddy config. Aborting switch."
}

$json = $config | ConvertTo-Json -Depth 100

Invoke-RestMethod `
    -Uri "$caddyAdmin/config/" `
    -Method Put `
    -ContentType "application/json" `
    -Body $json

Write-Host "Caddy switched: $oldPort -> $newPort ($($script:switched) upstream(s))."
