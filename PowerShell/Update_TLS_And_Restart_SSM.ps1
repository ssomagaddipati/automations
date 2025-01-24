# Enable Strong Cryptography and Default TLS Versions for .NET Framework on AWS EC2 Windows
$regPaths = @(
    "HKLM\SOFTWARE\Microsoft\.NETFramework\v2.0.50727",
    "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
)

foreach ($path in $regPaths) {
    reg add $path /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f
    reg add $path /v SchUseStrongCrypto /t REG_DWORD /d 1 /f
}

Write-Output "TLS settings updated successfully."

# Restart the AWS SSM Agent Service
Restart-Service AmazonSSMAgent -Force
Write-Output "AmazonSSMAgent service restarted."

# Wait for 15 seconds to ensure the service starts properly
Start-Sleep -Seconds 15
Write-Output "Script execution completed."
