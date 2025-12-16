param (
  [Parameter(Mandatory = $true)]
  [string]$ContainerName,

  [Parameter(Mandatory = $true)]
  [string]$Port
)

$url = "http://localhost:$Port/"
$maxAttempts = 10
$delay = 3

Write-Host "Running smoke test on $url (container: $ContainerName)"

for ($i = 1; $i -le $maxAttempts; $i++) {
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
    if ($response.StatusCode -eq 200) {
      Write-Host "SMOKE PASSED - API responding"
      exit 0
    }
  } catch {
    Write-Host "Attempt $i/$maxAttempts - API not ready yet"
  }

  Start-Sleep -Seconds $delay
}

Write-Host "SMOKE FAILED - API NOT RESPONDING"
exit 1
