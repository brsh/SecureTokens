function Clear-SavedPSReadlineHistory {
	[CmdletBinding()]
	param(
	)
	[string] $HistoryPath = ''
	try {
		$HistoryPath = (Get-PSReadLineOption).HistorySavePath
	} catch {
		$HistoryPath = ''
	}

	if ($HistoryPath.Length -gt 0) {
		Write-Verbose "PSReadline History Path: $HistoryPath"
		if (Test-Path $HistoryPath) {
			try {
				$HPContent = Get-Content $HistoryPath -ErrorAction Stop | Where-Object { $_ -notmatch '^Add-SecureToken' }
				if ($HPContent.Length -gt 0) {
					try {
						$HPContent | Out-File -FilePath $HistoryPath -Force -ErrorAction Stop
					} catch {
						Write-Host 'Could not save changes to PSReadline History file' -ForegroundColor Red
						Write-Host "  Path: $HistoryPath"
						Write-Host "  $($_.Exception.Message)"
						Throw 'History save error'
					}
				}
			} catch {
				Write-Host 'Could not remove Add-SecureToken command from PSReadline History file' -ForegroundColor Red
				Write-Host "  Path: $HistoryPath"
				Write-Host "  $($_.Exception.Message)"
				Throw 'History Read Error'
			}
		} else {
			Write-Verbose "PSReadline History File does not exist"
		}
	} else {
		Write-Verbose 'PSReadline History path is empty'
	}
}
