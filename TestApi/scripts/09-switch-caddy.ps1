$caddyAdmin = "http://127.0.0.1:2019"

Write-Host "Getting current Caddy configuration..."

$config = Invoke-RestMethod `
    -Uri "$caddyAdmin/config/" `
    -Method Get

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

                    if ($upstream.dial -eq "127.0.0.1:5500") {

                        Write-Host "Switching:"
                        Write-Host "5500 -> 5501"

                        $upstream.dial = "127.0.0.1:5501"
                    }
                }
            }

            Replace-Upstream $value
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

$json = $config | ConvertTo-Json -Depth 100

Invoke-RestMethod `
    -Uri "$caddyAdmin/config/" `
    -Method Put `
    -ContentType "application/json" `
    -Body $json

Write-Host "Caddy switched to Green."
