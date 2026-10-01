$releaseDir = "C:\Deploy\Releases\$env:RELEASE_VERSION"

$logDir = "C:\Deploy\Logs"

New-Item `
    -ItemType Directory `
    -Path $logDir `
    -Force | Out-Null

$stdout = "$logDir\green-$env:RELEASE_VERSION.stdout.log"
$stderr = "$logDir\green-$env:RELEASE_VERSION.stderr.log"

Write-Host "Starting:"
Write-Host $releaseDir
Write-Host ""

$process = Start-Process `
    -FilePath "dotnet" `
    -ArgumentList "TestApi.dll --urls http://127.0.0.1:5501" `
    -WorkingDirectory $releaseDir `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr `
    -WindowStyle Hidden `
    -PassThru

Write-Host "Green PID: $($process.Id)"

Set-Content `
    "C:\Deploy\green.pid" `
    $process.Id

Start-Sleep -Seconds 3
