param (
  [Parameter(Mandatory = $true)]
  [string]$ContainerName
)

$maxAttempts = 15
$delay = 2
$port = $null

Write-Host "Waiting for Docker port mapping for container: $ContainerName"

for ($i = 1; $i -le $maxAttempts; $i++) {

  try {
    $portLine = docker port $ContainerName 3000 2>$null
    if ($portLine) {
      $port = ($portLine -split ":")[-1]
      break
    }
  } catch {}

  Write-Host "Attempt $i/$maxAttempts - port not published yet"
  Start-Sleep -Seconds $delay
}

if (-not $port) {
  Write-Host "SMOKE FAILED - unable to retrieve mapped port"
  exit 1
}

$url = "http://localhost:$port/"
Write-Host "Running smoke test on $url"

for ($i = 1; $i -le $maxAttempts; $i++) {
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
    if ($response.StatusCode -eq 200) {
      Write-Host "SMOKE PASSED - API responding"
      exit 0
    }
  } catch {
    Write-Host "Attempt $i/$maxAttempts - API not ready"
  }

  Start-Sleep -Seconds $delay
}

Write-Host "SMOKE FAILED - API NOT RESPONDING"
exit 1
