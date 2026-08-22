[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtimeDir = Join-Path $projectDir '.mcp_runtime'
$logDir = Join-Path $runtimeDir 'logs'
$pidDir = Join-Path $runtimeDir 'pids'

$servers = @(
    @{ Name = 'stock_predict'; File = 'stock_predict_mcp_server.py'; Port = 8336 },
    @{ Name = 'turn_human'; File = 'turn_human_server.py'; Port = 8335 },
    @{ Name = 'article_check'; File = 'article_check_mcp_server.py'; Port = 9330 },
    @{ Name = 'finance_consult'; File = 'finance_consult_mcp_server.py'; Port = 9339 }
)

New-Item -ItemType Directory -Force -Path $logDir, $pidDir | Out-Null

$pythonExe = $env:PYTHON_EXE
if (-not $pythonExe -and $env:CONDA_PREFIX) {
    $pythonExe = Join-Path $env:CONDA_PREFIX 'python.exe'
}
if (-not $pythonExe) {
    $travelPython = Join-Path $env:USERPROFILE '.conda\envs\travel\python.exe'
    if (Test-Path -LiteralPath $travelPython) {
        $pythonExe = $travelPython
    }
}
if (-not $pythonExe) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) {
        $pythonExe = $pythonCommand.Source
    }
}
if (-not $pythonExe -or -not (Test-Path -LiteralPath $pythonExe)) {
    throw 'Python was not found. Activate the Conda environment or set PYTHON_EXE.'
}

Write-Host "Project: $projectDir"
Write-Host "Python:  $pythonExe"
Write-Host ''

# Keep redirected logs and model output Unicode-safe on Windows.
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

foreach ($server in $servers) {
    $scriptPath = Join-Path $projectDir $server.File
    $pidPath = Join-Path $pidDir ($server.Name + '.pid')
    $stdoutPath = Join-Path $logDir ($server.Name + '.out.log')
    $stderrPath = Join-Path $logDir ($server.Name + '.err.log')

    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Warning "[$($server.Name)] Script not found: $scriptPath"
        continue
    }

    if (Test-Path -LiteralPath $pidPath) {
        $oldPid = (Get-Content -LiteralPath $pidPath -Raw).Trim()
        if ($oldPid -match '^\d+$' -and (Get-Process -Id ([int]$oldPid) -ErrorAction SilentlyContinue)) {
            Write-Host "[$($server.Name)] Already running (PID $oldPid, port $($server.Port))." -ForegroundColor Yellow
            continue
        }
        Remove-Item -LiteralPath $pidPath -Force
    }

    $portOwner = Get-NetTCPConnection -LocalPort $server.Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($portOwner) {
        Write-Warning "[$($server.Name)] Port $($server.Port) is already in use by PID $($portOwner.OwningProcess); skipped."
        continue
    }

    $process = Start-Process -FilePath $pythonExe `
        -ArgumentList @('-u', $scriptPath) `
        -WorkingDirectory $projectDir `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -PassThru

    Set-Content -LiteralPath $pidPath -Value $process.Id -Encoding ascii
    Start-Sleep -Milliseconds 700

    if ($process.HasExited) {
        Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
        Write-Warning "[$($server.Name)] Failed to start (exit code $($process.ExitCode)). Check: $stderrPath"
    }
    else {
        Write-Host "[$($server.Name)] Started (PID $($process.Id), port $($server.Port))." -ForegroundColor Green
    }
}

Write-Host ''
Write-Host "Logs: $logDir"
Write-Host 'All launch commands have completed. The MCP processes will remain in the background.'
