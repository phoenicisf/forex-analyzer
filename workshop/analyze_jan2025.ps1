$ErrorActionPreference = 'Stop'

function Parse-Time($s) {
  $fmts = @('yyyy.MM.dd HH:mm','yyyy-MM-dd HH:mm','yyyy/MM/dd HH:mm','MM/dd/yyyy HH:mm','M/d/yyyy H:mm','yyyy-MM-dd HH:mm:ss','yyyy.MM.dd HH:mm:ss')
  foreach($f in $fmts){ try { return [datetime]::ParseExact($s,$f,$null) } catch {} }
  try { return [datetime]::Parse($s) } catch { return $null }
}

function Mean($arr){ if(-not $arr -or $arr.Count -eq 0){ return $null } return [double]([math]::Round((($arr | Measure-Object -Average).Average), 12)) }
function Std($arr){ if(-not $arr -or $arr.Count -le 1){ return $null } $m = Mean($arr); $sum = 0.0; foreach($x in $arr){ $sum += [math]::Pow(($x - $m),2) } $variance = $sum / ($arr.Count - 1); return [double]([math]::Sqrt($variance)) }

$filesDir = Join-Path 'MQL5' 'Files'
$barsFile = Join-Path $filesDir 'EURUSD_BARS_2020_2025.csv'
if(!(Test-Path $barsFile)){
  $cand = Get-ChildItem -Path $filesDir -Filter '*_BARS_*.csv' | Select-Object -First 1
  if($cand){ $barsFile = $cand.FullName } else { Write-Output '[ERROR] ไม่พบไฟล์ Bars CSV ใน ' + $filesDir; exit 1 }
}
Write-Output ('[INFO] ใช้ไฟล์: ' + $barsFile)

$bars = New-Object System.Collections.Generic.List[object]
$headerProcessed = $false
$lineNo = 0
Get-Content -Path $barsFile -ReadCount 1000 | ForEach-Object {
  foreach($line in $_){
    $lineNo++
    if([string]::IsNullOrWhiteSpace($line)){ continue }
    if(-not $headerProcessed){ if($line -match 'Date,Time,'){ $headerProcessed=$true; continue } else { $headerProcessed=$true } }
    $f = $line.Split(',')
    if($f.Count -lt 6){ continue }
    $dt = Parse-Time(($f[0] + ' ' + $f[1]))
    if($dt -eq $null){ continue }
    if($dt.Year -ne 2025 -or $dt.Month -ne 1){ continue }
    $open   = [double]$f[2]
    $high   = [double]$f[3]
    $low    = [double]$f[4]
    $close  = [double]$f[5]
    $tickv  = if($f.Count -gt 6){ [int]$f[6] } else { 0 }
    $spread = if($f.Count -gt 7){ [double]$f[7] } else { 0.0 }

    $range = $high - $low
    if($range -le 0){ continue }
    $body = $close - $open
    $bodyHigh = [math]::Max($open,$close)
    $bodyLow  = [math]::Min($open,$close)
    $upper = [math]::Abs($high - $bodyHigh)
    $lower = [math]::Abs($bodyLow - $low)
    $bodyRatio = [math]::Abs($body) / ($range)
    $upperRatio = $upper / $range
    $lowerRatio = $lower / $range

    $bars.Add([pscustomobject]@{
      ts=$dt; open=$open; high=$high; low=$low; close=$close; spread=$spread; tick=$tickv;
      range=$range; body=$body; bodyHigh=$bodyHigh; bodyLow=$bodyLow; bodyRatio=$bodyRatio; upperRatio=$upperRatio; lowerRatio=$lowerRatio
    })
  }
}

if($bars.Count -eq 0){ Write-Output '[WARN] ไม่พบข้อมูลเดือน 01/2025 ในไฟล์ที่เลือก'; exit 0 }

# คำนวณแพตเทิร์น
$pinBodyMax = 0.33
$wickMin = 0.6
$signals = New-Object System.Collections.Generic.List[object]
$inside=0; $outside=0; $pinBull=0; $pinBear=0; $engBull=0; $engBear=0
for($i=1; $i -lt $bars.Count; $i++){
  $cur = $bars[$i]
  $prev = $bars[$i-1]
  if($cur.high -le $prev.high -and $cur.low -ge $prev.low){ $inside++ ; $signals.Add([pscustomobject]@{idx=$i; ts=$cur.ts; pat='inside'}) }
  if($cur.high -ge $prev.high -and $cur.low -le $prev.low){ $outside++ ; $signals.Add([pscustomobject]@{idx=$i; ts=$cur.ts; pat='outside'}) }
  if(($cur.body -gt 0) -and ($cur.bodyRatio -le $pinBodyMax) -and ($cur.lowerRatio -ge $wickMin)){ $pinBull++ ; $signals.Add([pscustomobject]@{idx=$i; ts=$cur.ts; pat='pin_bull'}) }
  if(($cur.body -lt 0) -and ($cur.bodyRatio -le $pinBodyMax) -and ($cur.upperRatio -ge $wickMin)){ $pinBear++ ; $signals.Add([pscustomobject]@{idx=$i; ts=$cur.ts; pat='pin_bear'}) }
  if(($cur.body -gt 0) -and ($cur.bodyHigh -ge $prev.bodyHigh) -and ($cur.bodyLow -le $prev.bodyLow)){ $engBull++ ; $signals.Add([pscustomobject]@{idx=$i; ts=$cur.ts; pat='engulf_bull'}) }
  if(($cur.body -lt 0) -and ($cur.bodyHigh -ge $prev.bodyHigh) -and ($cur.bodyLow -le $prev.bodyLow)){ $engBear++ ; $signals.Add([pscustomobject]@{idx=$i; ts=$cur.ts; pat='engulf_bear'}) }
}

# Outcomes N=1,3,5
$nexts = @(1,3,5)
$summary = @{}
foreach($pat in @('inside','outside','pin_bull','pin_bear','engulf_bull','engulf_bear')){
  $idxs = $signals | Where-Object { $_.pat -eq $pat } | Select-Object -ExpandProperty idx
  foreach($n in $nexts){
    $rets = New-Object System.Collections.Generic.List[double]
    foreach($j in $idxs){ if(($j + $n) -lt $bars.Count){ $rets.Add( ($bars[$j+$n].close / $bars[$j].close) - 1.0 ) } }
    $count = $rets.Count
    $win = if($count -gt 0){ (($rets | Where-Object { $_ -gt 0 }).Count / $count) } else { $null }
    $mean = Mean($rets)
    $std = Std($rets)
    $summary["$pat|$n"] = [pscustomobject]@{ pattern=$pat; n=$n; count=$count; win_rate=$win; mean=$mean; std=$std }
  }
}

# สถิติพื้นฐาน
$avgClose = Mean(($bars | Select-Object -ExpandProperty close))
$avgRangePips = Mean(($bars | Select-Object -ExpandProperty range | ForEach-Object { $_ * 10000 }))
$avgSpread = Mean(($bars | Select-Object -ExpandProperty spread))
$avgTickVol = Mean(($bars | Select-Object -ExpandProperty tick))
$startTs = ($bars[0].ts)
$endTs = ($bars[$bars.Count-1].ts)
$total = $bars.Count

Write-Output '[RESULT] เดือน 01/2025'
Write-Output ('Bars = {0}, ช่วงเวลา = {1} ถึง {2}' -f $total, $startTs, $endTs)
Write-Output ('Avg Close = {0}' -f $avgClose)
Write-Output ('Avg Range ≈ {0} pips' -f [math]::Round($avgRangePips,3))
Write-Output ('Avg Spread = {0}' -f $avgSpread)
Write-Output ('Avg TickVol = {0}' -f $avgTickVol)
Write-Output ('Patterns: Inside={0}, Outside={1}, PinBull={2}, PinBear={3}, EngulfBull={4}, EngulfBear={5}' -f $inside,$outside,$pinBull,$pinBear,$engBull,$engBear)

Write-Output 'Outcomes (N-bars ahead):'
foreach($key in ($summary.Keys | Sort-Object)){
  $s = $summary[$key]
  $wr = if($s.win_rate -ne $null){ [math]::Round($s.win_rate,4) } else { $null }
  $mn = if($s.mean -ne $null){ [math]::Round($s.mean,6) } else { $null }
  $sd = if($s.std -ne $null){ [math]::Round($s.std,6) } else { $null }
  Write-Output ('  {0} N={1}: count={2}, win_rate={3}, mean={4}, std={5}' -f $s.pattern,$s.n,$s.count,$wr,$mn,$sd)
}
