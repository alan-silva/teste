Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

Set-ExecutionPolicy unrestricted -Force
$CertSelfSigned = New-SelfSignedCertificate -DnsName "$env:computername" -KeyAlgorithm RSA -KeyLength 2048 -NotAfter ((Get-Date).AddYears(10)) -CertStoreLocation "Cert:\LocalMachine\My"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $CertSelfSigned.ThumbPrint -Hostname "$env:computername" -Force
Get-ChildItem WSMan:\localhost\Listener | ?{$_.Keys -contains "Transport=HTTP"}|remove-item -recurse -Confirm:$false

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

# Configure WinRM to allow unencrypted communication, and provide the
# self-signed cert to the WinRM listener.
cmd.exe /c winrm quickconfig -q
#cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
#cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
#cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
#cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
#cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
#cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"localhost`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
#cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"vm-win-vivo-001`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"$env:computername`";CertificateThumbprint=`"$($CertSelfSigned.ThumbPrint)`"}"

# Make sure appropriate firewall port openings exist
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5986 "Port 5986"

# Disabling Firewall Service
cmd.exe /c netsh advfirewall set allprofile state off

# Restart WinRM, and set it so that it auto-launches on startup.
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm
