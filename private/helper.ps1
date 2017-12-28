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
		$SecureToken = $Token | ConvertTo-SecureString -AsPlainText -Force
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
		$UsableSecureString = Get-Content $credpath | ConvertTo-SecureString
		$Credentials = New-Object System.Management.Automation.PSCredential ("MySlackToken", $UsableSecureString)
		$Credentials.GetNetworkCredential().Password
	}

}
