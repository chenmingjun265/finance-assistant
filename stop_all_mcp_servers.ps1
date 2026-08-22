[CmdletBinding()]
param()

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidDir = Join-Path $projectDir '.mcp_runtime\pids'

if (-not (Test-Path -LiteralPath $pidDir)) {
    Write-Host 'No MCP runtime PID directory was found.'
    exit 0
}

Get-ChildItem -LiteralPath $pidDir -Filter '*.pid' | ForEach-Object {
    $name = $_.BaseName
    $savedPid = (Get-Content -LiteralPath $_.FullName -Raw).Trim()

    if ($savedPid -match '^\d+$') {
        $process = Get-Process -Id ([int]$savedPid) -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $process.Id -Force
            Write-Host "[$name] Stopped (PID $savedPid)." -ForegroundColor Green
        }
        else {
            Write-Host "[$name] Was not running (stale PID $savedPid)." -ForegroundColor Yellow
        }
    }

    Remove-Item -LiteralPath $_.FullName -Force
}

Write-Host 'All tracked MCP processes have been stopped.'

