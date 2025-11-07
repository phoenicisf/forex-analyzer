param(
  [string]$ConfigPath = "workshop/project/config/config.json",
  [int]$Year,
  [int]$Month,
  [string]$Timeframe = "M1"
)

if (-not $Year -or -not $Month) {
  Write-Host "Usage: run_month.ps1 -ConfigPath <path> -Year <YYYY> -Month <MM> -Timeframe <TF>" -ForegroundColor Yellow
  exit 1
}

# Move to project root to ensure python -m works
$projRoot = "workshop/project"
Set-Location $projRoot

Write-Host "[RUN] Analyzer for $Year-$([string]::Format("{0:D2}", $Month)) ($Timeframe) using $ConfigPath" -ForegroundColor Cyan

$pythonCmd = "python -m src.analysis.analyze_patterns --config `"$ConfigPath`" --year $Year --month $Month --timeframe `"$Timeframe`""
Write-Host $pythonCmd
$analyze = Invoke-Expression $pythonCmd

Write-Host "[RUN] Generate reports" -ForegroundColor Cyan
$reportCmd = "python -m src.report.generate_reports --config `"$ConfigPath`""
Invoke-Expression $reportCmd

Write-Host "[DONE] run_month.ps1 completed." -ForegroundColor Green
