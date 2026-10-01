$version = $env:VERSION -replace '^v', ''

Write-Host "Deploying version: $version"

"RELEASE_VERSION=$version" >> $env:GITHUB_ENV
