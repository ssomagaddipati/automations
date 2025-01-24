# PowerShell 4 or up is required to run this script
# This script detects platform and architecture.  It then downloads and installs the relevant Deep Security Agent package

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You are not running as an Administrator. Please try again with admin privileges."
    exit 1
 }
 
 $managerUrl="https://app.deepsecurity.trendmicro.com:443/"
 
 $env:LogPath = "$env:appdata\Trend Micro\Deep Security Agent\installer"
 New-Item -path $env:LogPath -type directory
 Start-Transcript -path "$env:LogPath\dsa_deploy.log" -append
 
 Write-Output "$(Get-Date -format T) - DSA download started"
 if ( [intptr]::Size -eq 8 ) {
    $sourceUrl=-join($managerUrl, "software/agent/Windows/x86_64/") }
 else {
    $sourceUrl=-join($managerUrl, "software/agent/Windows/i386/") }
 Write-Output "$(Get-Date -format T) - Download Deep Security Agent Package" $sourceUrl
 
 $ACTIVATIONURL="dsm://agents.deepsecurity.trendmicro.com:443/"
 
 $WebClient = New-Object System.Net.WebClient
 
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
 
 Try
 {
      $WebClient.DownloadFile($sourceUrl,  "$env:temp\agent.msi")
 } Catch [System.Net.WebException]
 {
       Write-Output " Please check that your Deep Security Manager TLS certificate is signed by a trusted root certificate authority."
       exit 2;
 }
 
 if ( (Get-Item "$env:temp\agent.msi").length -eq 0 ) {
     Write-Output "Failed to download the Deep Security Agent. Please check if the package is imported into the Deep Security Manager. "
  exit 1
 }
 Write-Output "$(Get-Date -format T) - Downloaded File Size:" (Get-Item "$env:temp\agent.msi").length
 
 Write-Output "$(Get-Date -format T) - DSA install started"
 Write-Output "$(Get-Date -format T) - Installer Exit Code:" (Start-Process -FilePath msiexec -ArgumentList "/i $env:temp\agent.msi /qn ADDLOCAL=ALL /l*v `"$env:LogPath\dsa_install.log`"" -Wait -PassThru).ExitCode
 Write-Output "$(Get-Date -format T) - DSA activation started"
 
 Start-Sleep -s 50
 & $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -r
 & $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a $ACTIVATIONURL "tenantID:XXXXX-XXX-XXX-XXX-XXXXXXXXX" "token:XXXXXX-XXX-XXX-XXX-XXXXXXXXX" "policyid:XXXX"
 #& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a dsm://agents.deepsecurity.trendmicro.com:443/ "tenantID:XXXXX-XXX-XXX-XXX-XXXXXXXXX" "token:XXXXX-XXX-XXX-XXX-XXXXXXXXX" "policyid:XXXX"
 Stop-Transcript
 Write-Output "$(Get-Date -format T) - DSA Deployment Finished"
 