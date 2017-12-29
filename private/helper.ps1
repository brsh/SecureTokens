function Set-SavedToken {
	param(
		[Parameter(Mandatory = $true)]
		[string] $Name = '',
		[Parameter(Mandatory = $true)]
		[string] $Token = '',
		[switch] $force = $false
	)
	$retval = "Nothing Happened"
	if (($name) -and ($token)) {
		$SecureToken = $Token | ConvertTo-SecureString -AsPlainText -Force -ErrorAction Stop
		$SecureTokenAsText = $SecureToken | ConvertFrom-SecureString
		$credpath = "$($script:SecureTokenFolder)\$Name.txt"
		try {
			$SecureTokenAsText | Out-File $credpath
			$retval = $credpath
		} catch {
			$retval = "Error: $($_.Exception.Message)"
		}
	}
	$retval
}


function Get-SavedToken {
	param(
		[Parameter(Mandatory = $true)]
		[string] $Name = ''
	)
	[string] $retval = ''
	if ($Name) {
		$credpath = "$($script:SecureTokenFolder)\$Name.txt"
		try {
			$UsableSecureString = Get-Content $credpath | ConvertTo-SecureString -ErrorAction Stop
			$Credentials = New-Object System.Management.Automation.PSCredential ("MySlackToken", $UsableSecureString)
			$retval = $Credentials.GetNetworkCredential().Password
		} catch [System.Security.Cryptography.CryptographicException] {
			$retval = "Error: Maybe Token Not Owned By This User on This Machine"
		} catch {
			$retval = "Error: $($_.Exception.Message)"
		}
	}
	$retval
}
