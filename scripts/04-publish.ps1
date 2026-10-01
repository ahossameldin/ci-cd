$releaseDir = "C:App\deploy\releases\$env:VERSION"

Write-Host "Publishing to:"
Write-Host $releaseDir

# Don't overwrite an existing release
if (Test-Path $releaseDir) {
    throw "Release $env:VERSION already exists."
}

New-Item `
    -ItemType Directory `
    -Path $releaseDir `
    -Force | Out-Null

dotnet publish .\TestApi\TestApi.csproj `
    --configuration Release `
    --no-restore `
    --output $releaseDir

Write-Host ""
Write-Host "Release published:"
Write-Host $releaseDir
