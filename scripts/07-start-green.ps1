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

# Empty previous logs for this version so failures are not confused with old output
Set-Content $stdout ""
Set-Content $stderr ""

Write-Host "Starting version $env:RELEASE_VERSION on port $newPort :"
Write-Host $releaseDir
Write-Host ""

# NOTE: plain Start-Process children die when the runner's step console is
# torn down, so launch fully detached via WMI (no console attached at all).
$dotnet = (Get-Command dotnet).Source

$cmd = "cmd.exe /c `"`"$dotnet`" TestApi.dll --urls http://0.0.0.0:$newPort > $stdout 2> $stderr`""

Write-Host "Launch: $cmd"

$result = Invoke-CimMethod `
    -ClassName Win32_Process `
    -MethodName Create `
    -Arguments @{
        CommandLine      = $cmd
        CurrentDirectory = $releaseDir
    }

if ($result.ReturnValue -ne 0) {
    throw "Failed to start API, Win32_Process.Create returned $($result.ReturnValue)."
}

$pidValue = $result.ProcessId

Write-Host "New process PID: $pidValue"

Set-Content `
    "C:\Deploy\$newPort.pid" `
    $pidValue

# Fail fast: the listener must appear, otherwise dump logs instead of
# letting the health-check step time out for a minute.
$listening = $false

for ($i = 1; $i -le 10; $i++) {

    Start-Sleep -Seconds 1

    $conn = Get-NetTCPConnection `
        -LocalPort $newPort `
        -State Listen `
        -ErrorAction SilentlyContinue

    if ($conn) {
        $listening = $true
        break
    }

    $proc = Get-Process -Id $pidValue -ErrorAction SilentlyContinue

    if (-not $proc) {
        Write-Host "Process $pidValue exited during startup. Logs:"
        Write-Host "--- stdout ---"
        Get-Content $stdout -ErrorAction SilentlyContinue
        Write-Host "--- stderr ---"
        Get-Content $stderr -ErrorAction SilentlyContinue
        throw "API process exited before listening on port $newPort."
    }
}

if (-not $listening) {
    Write-Host "No listener on port $newPort after 10s. Logs:"
    Write-Host "--- stdout ---"
    Get-Content $stdout -ErrorAction SilentlyContinue
    Write-Host "--- stderr ---"
    Get-Content $stderr -ErrorAction SilentlyContinue
    throw "API did not start listening on port $newPort."
}

Write-Host "Listener confirmed on port $newPort (PID $pidValue)."
