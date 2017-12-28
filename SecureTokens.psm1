﻿param(
	[parameter(Position = 0, Mandatory = $false)]
	[boolean] $Quiet = $false
)

#region Private Variables
# Current script path
[string] $script:ScriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent
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
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | Foreach {
		Export-ModuleMember $_.Name
		$script:showhelp += $_.Name
	}
}
#endregion public Helpers

[string] $script:SecureTokenFolder = ""

if (-not $Quiet) {
	try {
		if (test-path "$script:scriptpath\config\FolderPath.txt") {
			Write-host "Attempting to load SecureTokens config file..."
			[string] $script:SecureTokenFolder = get-content "$script:scriptpath\config\FolderPath.txt"
			Write-Host "  Loaded config file" -ForegroundColor Green
			if (test-path $script:SecureTokenFolder -ErrorAction SilentlyContinue) {
				Write-Host "  Path to SecureTokens ($($script:SecureTokenFolder)) is valid" -ForegroundColor Green
			} else {
				Write-Host "  Path to SecureTokens ($($script:SecureTokenFolder)) is NOT valid" -ForegroundColor Yellow
				Write-Host "  Use the Set-SecureTokenFolder function "
			}
		} else {
			Write-host "Default config does not exist.... Fixing that problem.... " -ForegroundColor Yellow
			Set-SecureTokenFolder -default -clobber
			Write-host "  Use Set-SecureTokenFolder to override this default (if necessary)"
			Write-host ""
		}

	} catch {
		$script:SecureTokenFolder = ""
		Write-Host "No default sites file exists. Use 'Set-SecureTokenFolder' to create one"
	}

	Get-SecureTokenHelp
}

# #Export-ModuleMember -Variable TestWebstackFile

# Export-ModuleMember -function Get-*
# Export-ModuleMember -function Set-*
# Export-ModuleMember -function Test-*
# Export-ModuleMember -function Read-*
# Export-ModuleMember -function New-*
# Export-ModuleMember -function Add-*
# Export-ModuleMember -function Remove-*


# #Export-ModuleMember -alias *


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
