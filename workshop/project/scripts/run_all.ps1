param(
  [string]$ConfigPath = "workshop/project/config/config.json",
  [switch]$IncludeTicks,
  [switch]$IncludeDeals
)

$projRoot = "workshop/project"
Set-Location $projRoot

Write-Host "[RUN] ETL: Bars" -ForegroundColor Cyan
$etlBars = "python -m src.etl.ingest_csv_to_parquet --config `"$ConfigPath`" --kind bars"
Write-Host $etlBars
Invoke-Expression $etlBars

if ($IncludeTicks) {
  Write-Host "[RUN] ETL: Ticks" -ForegroundColor Cyan
  $etlTicks = "python -m src.etl.ingest_csv_to_parquet --config `"$ConfigPath`" --kind ticks"
  Write-Host $etlTicks
  Invoke-Expression $etlTicks
}

if ($IncludeDeals) {
  Write-Host "[RUN] ETL: Deals" -ForegroundColor Cyan
  $etlDeals = "python -m src.etl.ingest_csv_to_parquet --config `"$ConfigPath`" --kind deals"
  Write-Host $etlDeals
  Invoke-Expression $etlDeals
}

Write-Host "[RUN] Orchestrator: process next partitions" -ForegroundColor Cyan
$orch = "python -m src.orchestration.process_next_partition --config `"$ConfigPath`""
Write-Host $orch
Invoke-Expression $orch

Write-Host "[RUN] Generate reports" -ForegroundColor Cyan
$reportCmd = "python -m src.report.generate_reports --config `"$ConfigPath`""
Write-Host $reportCmd
Invoke-Expression $reportCmd

Write-Host "[DONE] run_all.ps1 completed." -ForegroundColor Green
