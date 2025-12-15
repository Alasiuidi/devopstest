$maxRetries = 10
$delay = 3
$url = "http://localhost:3000/"

for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "SMOKE PASSED - API RESPONDING"
            exit 0
        }
    } catch {
        Write-Host "Attempt $i/$maxRetries - API not ready yet"
    }
    Start-Sleep -Seconds $delay
}

Write-Host "SMOKE FAILED - API NOT RESPONDING"
exit 1
