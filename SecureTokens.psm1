param(
	[parameter(Position = 0, Mandatory = $false)]
	[boolean] $Quiet = $false
)

#region Private Variables
# Current script path
[string] $script:ScriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent
if ((Get-Variable MyInvocation -Scope script).Value.Line.Trim().Length -eq 0) { $Quiet = $true }
#endregion Private Variables

#region Private Helpers

# Dot sourcing private script files
Get-ChildItem $script:ScriptPath/private -Recurse -Filter "*.ps1" -File | ForEach-Object {
	. $_.FullName
}
#endregion Load Private Helpers

#region public Helpers

[string[]] $script:showhelp = @()
# Dot sourcing public script files
Get-ChildItem $script:ScriptPath/public -Recurse -Filter "*.ps1" -File | ForEach-Object {
	. $_.FullName
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
		Export-ModuleMember $_.Name
		$script:showhelp += $_.Name
	}
}
#endregion public Helpers

[string] $script:SecureTokenFolder = ''
[string] $script:DefaultCert = ''

try {
	if (test-path "$script:scriptpath\config\FolderPath.txt") {
		if (-not $Quiet) { Write-host "Attempting to load SecureTokens config file..." }
		[string] $script:SecureTokenFolder = get-content "$script:scriptpath\config\FolderPath.txt"
		if (-not $Quiet) { Write-Host "  Loaded config file" -ForegroundColor Green }
		if (-not $Quiet) {
			if (test-path $script:SecureTokenFolder -ErrorAction SilentlyContinue) {
				Write-Host "  Path to SecureTokens ($($script:SecureTokenFolder)) is valid" -ForegroundColor Green
			} else {
				Write-Host "  Path to SecureTokens ($($script:SecureTokenFolder)) is NOT valid" -ForegroundColor Yellow
				Write-Host "  Use the Set-SecureTokenFolder function "
			}
		}
	} else {
		if (-not $Quiet) { Write-host "Default config does not exist.... Fixing that problem.... " -ForegroundColor Yellow }
		Set-SecureTokenFolder -default -clobber
		if (-not $Quiet) {
			Write-host "  Use Set-SecureTokenFolder to override this default (if necessary)"
			Write-host ""
		}
	}

} catch {
	$script:SecureTokenFolder = ""
	Write-Host "No default Token folder exists. Use 'Set-SecureTokenFolder' to create one"
}

try {
	if (test-path "$script:scriptpath\config\DefaultCert.txt") {
		if (-not $Quiet) { Write-host "Attempting to load Default Certificate config file..." }
		[string] $script:DefaultCert = get-content "$script:scriptpath\config\DefaultCert.txt"
		if (-not $Quiet) { Write-Host "  Loaded config file" -ForegroundColor Green }
		if (-not $Quiet) {
			if ($script:DefaultCert) {
				if (Find-STEncryptionCertificate -filter "${script:DefaultCert}$") {
					Write-Host "  SecureTokens Default Cert (" -NoNewline -ForegroundColor Green
					Write-Host (Find-STEncryptionCertificate -filter "${script:DefaultCert}$").Subject -NoNewline -ForegroundColor Yellow
					Write-Host ") is configured" -ForegroundColor Green
				} else {
					Write-Host "  Saved Default Certificate is not valid for this user/machine"
				}
			} else {
				Write-Host "  SecureTokens Default Certs is NOT configured" -ForegroundColor Yellow
				Write-Host "  Use the Set-STDefaultCertificate function "
			}
		}
	} else {
		if (-not $Quiet) {
			$script:DefaultCert = ''
			Write-host "Default Certificate config does not exist.... " -ForegroundColor Yellow
			Write-host "  Use Set-STDefaultCertificate if you want to use Certificate Encryption by default"
			Write-host ""
		}
	}

} catch {
	$script:DefaultCert = ''
	Write-host "Default Certificate config does not exist.... " -ForegroundColor Yellow
	Write-host "  Use Set-STDefaultCertificate if you want to use Certificate Encryption by default"
	Write-host ""
}



if (test-path $script:ScriptPath\formats) {
	try {
		Update-FormatData $ScriptPath\formats\*.ps1xml -ErrorAction Stop
	} catch { }
}

if (-not $Quiet) { Get-SecureTokenHelp }


###################################################
## END - Cleanup

#region Module Cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
	# cleanup when unloading module (if any)
	Get-ChildItem alias: | Where-Object { $_.Source -match "SecureTokens" } | Remove-Item
	Get-ChildItem function: | Where-Object { $_.Source -match "SecureTokens" } | Remove-Item
	Get-ChildItem variable: | Where-Object { $_.Source -match "SecureTokens" } | Remove-Item
}
#endregion Module Cleanup

