$version = "${{ gitea.ref_name }}"

Write-Host "Deploying version: $version"

"VERSION=$version" >> $env:GITHUB_ENV
