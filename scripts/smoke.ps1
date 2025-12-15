param(
  [string]$Url = "http://localhost:3000/",
  [int]$TimeoutSec = 30
)

$end = (Get-Date).AddSeconds($TimeoutSec)

while ((Get-Date) -lt $end) {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
      "SMOKE PASSED - API RESPONDS"
      exit 0
    }
  } catch {
    Start-Sleep 2
  }
}

"SMOKE FAILED - API NOT RESPONDING"
exit 1
