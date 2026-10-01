$version = $env:VERSION

Write-Host "Deploying version: $version"

"VERSION=$version" >> $env:GITHUB_ENV
