function Set-SavedToken {
	param(
		[string] $Name = '',
		[string] $Token = '',
		[switch] $force = $false,
		[string] $Certificate
	)
	$retval = "!! Nothing Happened !!"
	$credpath = "$($script:SecureTokenFolder)\$Name.txt"

	if (($name) -and ($token)) {
		if ($Certificate) {
			if (Find-STEncryptionCertificate -filter ${Certificate}$) {
				try {
					Protect-CmsMessage -Content $Token -To $Certificate -OutFile $credpath
					$retval = $credpath
				} catch {
					$retval = "Error: $($_.Exception.Message)"
				}
			} else {
				$retval = "Error: Certificate $Certificate not found"
			}
		} else {
			$SecureToken = $Token | ConvertTo-SecureString -AsPlainText -Force -ErrorAction Stop
			$SecureTokenAsText = $SecureToken | ConvertFrom-SecureString
			try {
				$SecureTokenAsText | Out-File $credpath
				$retval = $credpath
			} catch {
				$retval = "Error: $($_.Exception.Message)"
			}
		}
	}
	$retval
}

function Get-SavedToken {
	param(
		[string] $Name = ''
	)
	[string] $retval = ''
	if ($Name) {
		$credpath = "$($script:SecureTokenFolder)\$Name.txt"
		try {
			$credcontent = Get-Content $credpath
			try {
				$unprotected = $credcontent | Unprotect-CmsMessage -IncludeContext
				if ($unprotected -eq $credcontent) {
					try {
						$UsableSecureString = Get-Content $credpath | ConvertTo-SecureString -ErrorAction Stop
						$Credentials = New-Object System.Management.Automation.PSCredential ("MySlackToken", $UsableSecureString)
						$retval = $Credentials.GetNetworkCredential().Password
					} catch [System.Security.Cryptography.CryptographicException] {
						$retval = "Error: Maybe Token Not Owned By This User on This Machine"
					} catch {
						$retval = "Error: $($_.Exception.Message)"
					}
				} else {
					$retval = $unprotected
				}

			} catch {
				$retval = "Error: $($_.Exception.Message) "
			}
		} catch {
			$retval = "Error: Could not read SecureToken file"
		}
	}
	$retval
}
