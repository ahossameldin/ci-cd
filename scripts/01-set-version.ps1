$version = $env:VERSION -replace '^v', ''

if ([string]::IsNullOrWhiteSpace($version)) {
    throw "VERSION env var is empty, expected tag like v1.0.10"
}

Write-Host "Deploying version: $version"

"RELEASE_VERSION=$version" >> $env:GITHUB_ENV
