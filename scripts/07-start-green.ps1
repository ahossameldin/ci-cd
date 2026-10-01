$newPort = $env:NEW_PORT

if ([string]::IsNullOrWhiteSpace($newPort)) {
    throw "NEW_PORT is empty. Did 00-detect-ports.ps1 run?"
}

if ([string]::IsNullOrWhiteSpace($env:RELEASE_VERSION)) {
    throw "RELEASE_VERSION is empty. Did 01-set-version.ps1 run?"
}

$releaseDir = "C:\Deploy\Releases\$env:RELEASE_VERSION"

$logDir = "C:\Deploy\Logs"

New-Item `
    -ItemType Directory `
    -Path $logDir `
    -Force | Out-Null

$stdout = "$logDir\port-$newPort-$env:RELEASE_VERSION.stdout.log"
$stderr = "$logDir\port-$newPort-$env:RELEASE_VERSION.stderr.log"

Write-Host "Starting version $env:RELEASE_VERSION on port $newPort :"
Write-Host $releaseDir
Write-Host ""

$process = Start-Process `
    -FilePath "dotnet" `
    -ArgumentList "TestApi.dll --urls http://0.0.0.0:$newPort" `
    -WorkingDirectory $releaseDir `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr `
    -WindowStyle Hidden `
    -PassThru

Write-Host "New process PID: $($process.Id)"

Set-Content `
    "C:\Deploy\$newPort.pid" `
    $process.Id

Start-Sleep -Seconds 3
