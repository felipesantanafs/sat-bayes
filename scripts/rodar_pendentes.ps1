# Roda em sequencia as etapas pendentes (robustez, bayesiana, avaliacao bayesiana).
# Os scripts R retomam do que ja foi gravado; cada passo e repetido ate 3 vezes se falhar.
# Uso: powershell -ExecutionPolicy Bypass -File scripts/rodar_pendentes.ps1
Set-Location (Split-Path $PSScriptRoot -Parent)
$rscript = "C:\Program Files\R\R-4.4.1\bin\Rscript.exe"
$log = "logs/pendentes.log"
New-Item -ItemType Directory -Force logs | Out-Null
function Registrar($msg) { Add-Content $log ("[" + (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") + "] " + $msg) }

function Rodar($nome, [string[]]$argumentos) {
  for ($tentativa = 1; $tentativa -le 3; $tentativa++) {
    Registrar "inicio $nome (tentativa $tentativa)"
    $p = Start-Process $rscript -ArgumentList $argumentos -NoNewWindow -PassThru -Wait `
      -RedirectStandardOutput "logs/$nome.out.log" -RedirectStandardError "logs/$nome.err.log"
    Registrar "fim $nome, codigo $($p.ExitCode)"
    if ($p.ExitCode -eq 0) { return $true }
  }
  return $false
}

# Espera um processo R ja em andamento, se houver.
Get-Process Rscript -ErrorAction SilentlyContinue | Wait-Process

Rodar "robustez" @("scripts/08_robustez.R") | Out-Null

# B2 e B3 em paralelo, depois B4 sozinha (memoria de 6 GB). Processos lancados
# direto daqui: dentro de Start-Job o Rscript travava sem console.
$pendentes = @("B2", "B3")
for ($tentativa = 1; $tentativa -le 3 -and $pendentes.Count; $tentativa++) {
  Registrar "inicio bayes $($pendentes -join '+') (tentativa $tentativa)"
  $procs = @{}
  foreach ($v in $pendentes) {
    $procs[$v] = Start-Process $rscript -ArgumentList @("scripts/07_bayes.R", "ajustar", $v) -NoNewWindow -PassThru `
      -RedirectStandardOutput "logs/bayes_$v.out.log" -RedirectStandardError "logs/bayes_$v.err.log"
  }
  $procs.Values | Wait-Process
  $pendentes = @($pendentes | Where-Object { $procs[$_].ExitCode -ne 0 })
  foreach ($v in $procs.Keys) { Registrar "fim bayes_$v, codigo $($procs[$v].ExitCode)" }
}
Rodar "bayes_B4" @("scripts/07_bayes.R", "ajustar", "B4") | Out-Null
Rodar "bayes_avaliar" @("scripts/07_bayes.R", "avaliar") | Out-Null
Registrar "TUDO CONCLUIDO"
