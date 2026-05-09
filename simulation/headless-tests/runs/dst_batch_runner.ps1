$ErrorActionPreference = "Stop"
$inis = @(
    "dst_2021_oct.ini",
    "dst_2022_mar.ini",
    "dst_2022_oct.ini",
    "dst_2023_mar.ini",
    "dst_2023_oct.ini",
    "dst_2024_mar.ini",
    "dst_2024_oct.ini",
    "dst_2025_mar.ini",
    "dst_2025_oct.ini"
)
$progress = "$PSScriptRoot\dst_batch_progress.txt"
$root = (Get-Item "$PSScriptRoot\..\..\..").FullName
"DST batch start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $progress
foreach ($name in $inis) {
    $ini = Join-Path $root "simulation\headless-tests\$name"
    "$(Get-Date -Format 'HH:mm:ss') BEGIN $name" | Add-Content $progress
    $proc = Start-Process -FilePath "C:\Program Files\FBS MetaTrader 5ph\terminal64.exe" -ArgumentList "/config:$ini" -PassThru
    $proc.WaitForExit()
    "$(Get-Date -Format 'HH:mm:ss') END   $name (exit=$($proc.ExitCode))" | Add-Content $progress
}
"DST batch complete: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content $progress
