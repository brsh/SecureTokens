Function Get-SecureTokenHelp {
	<#
	.SYNOPSIS
	List commands available in the SecureTokens Module

	.DESCRIPTION
	List all available commands in this module

	.EXAMPLE
	Get-SecureTokenHelp
	#>
	Write-Host ""
	Write-Host "Getting available functions..." -ForegroundColor Yellow

	$all = @()
	$list = Get-Command -Type function -Module "SecureTokens" | Where-Object { $_.Name -in $script:showhelp}
	$list | ForEach-Object {
		if ($PSVersionTable.PSVersion.Major -lt 6) {
			$RetHelp = Get-help $_.Name -ShowWindow:$false -ErrorAction SilentlyContinue
		} else {
			$RetHelp = Get-help $_.Name -ErrorAction SilentlyContinue
		}
		if ($RetHelp.Description) {
			$Infohash = @{
				Command     = $_.Name
				Description = $RetHelp.Synopsis
			}
			$out = New-Object -TypeName psobject -Property $InfoHash
			$all += $out
		}
	}
	$all | format-table -Wrap -AutoSize | Out-String | Write-Host
}
