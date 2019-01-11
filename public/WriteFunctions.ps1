Function Set-SecureTokenFolder {
	<#
	.SYNOPSIS
	Set (and save) the location of the files that hold secured tokens

	.DESCRIPTION
	This will set the location of the folder that contains secure tokens
	files. By default, this folder is $env:APPDATA\SecureTokens, but
	you can use multiple locations or just store the files elsewhere.
	Your choice. Just use this command if you want something different.

	.PARAMETER file
	The folder path to use

	.PARAMETER default
	Sets the module default of $env:APPDATA\SecureTokens

	.PARAMETER clobber
	Save the folder so it's the default going forward

	.EXAMPLE
	Set-SecureTokensFolder -folder c:\temp -clobber

	This will set the active folder to c:\temp and save it. C:\temp will then be the default until the next -clobber

	.EXAMPLE
	Set-SecureTokensFolder -file c:\temp

	This will set the active folder to c:\temp but not save it. The previous default file will be active at the next instantiation.

	.EXAMPLE
	Set-SecureTokensFolder -default -clobber

	Resets the saved default to $env:APPDATA\SecureTokens for the active session and future sessions

	#>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Set', Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Alias('Directory', 'Dir')]
		[string] $folder,
		[Parameter(Mandatory = $false, ParameterSetName = 'Set')]
		[Parameter(Mandatory = $false, ParameterSetName = 'Default')]
		[Alias('Force')]
		[switch] $clobber = $false,
		[Parameter(Mandatory = $true, ParameterSetName = 'Default')]
		[switch] $default = $false
	)
	if ($PSCmdlet.ParameterSetName -eq "Default") {
		$folder = "$env:APPDATA\SecureTokens"
	}

	[bool] $DoSet = $false
	if (test-path $folder) {
		Write-Host "Folder '$folder' exists" -ForegroundColor Green
		$DoSet = $true
	} else {
		Write-Host "Folder '$folder' does not exist." -ForegroundColor Red
		if (-not $Clobber) {
			$answer = Set-TimedPrompt -prompt "Create it?" -SecondsToWait 20 -Options 'Yes', 'No'
		}
		write-host ''
		if (($answer.Response -eq 'Yes') -or $clobber) {
			try {
				$created = new-item -path "$folder" -ItemType Directory -ErrorAction Stop
				if ($created) {
					Write-Host "Folder '$folder' created." -ForegroundColor Green
					$DoSet = $true
				} else {
					Write-Host "Could not create '$folder'. No error returned." -ForegroundColor Red
					$DoSet = $false
				}
			} catch {
				Write-Host "There was an error creating '$folder'." -ForegroundColor Red
				Write-Host "  $($_.Exception.Message)" -ForegroundColor White
				$DoSet = $false
			}
		} else {
			Write-Host "You chose No, so '$folder' NOT created." -ForegroundColor Red
			$DoSet = $false
		}
	}

	if ($DoSet) {
		$script:SecureTokenFolder = $folder
		Write-host "SecureTokenFolder is $script:SecureTokenFolder" -ForegroundColor Yellow

		if ($clobber) {
			if (-not $(test-path -Path $script:ScriptPath\Config)) {
				new-item -path $script:ScriptPath\config -ItemType Directory -ErrorAction SilentlyContinue
			}
			try {
				Set-Content -Path "$ScriptPath\Config\FolderPath.txt" -Value $script:SecureTokenFolder
				Write-Host "The change has been saved"
			} catch {
				Write-Error "Could not save the file."
				$_.Exception
			}
		}
	} else {
		Write-Host 'Not changing the SecureFolder folder' -ForegroundColor Yellow
	}
}

Function Set-STDefaultCertificate {
	<#
	.SYNOPSIS
	Set (and save) the default certificate used to encrypt tokens

	.DESCRIPTION
	This will set the default certificate for all new encrypted Tokens - meaning all new Tokens
	will be portable, encrypted by this certificate (unless over-ridden by the -Certificate switch
	on the Add-SecureToken function). With this set, you cannot create non-portable Tokens unless
	you use the -Clear switch.

	You can persist the Default Certificate between sessions via the -Clobber switch - this writes
	the Thumbprint to a file in the Module's config directory. You can clear the current 'in memory'
	default certificate to create non-portable Tokens without saving the "clear" to the file.

	At this point, I only allow CurrentUser certs to be set as default. I'll prolly open that up
	if I find I'm using more LocalMachine certs.

	Of course, the certificate set as default has to exist on the system before it can be set :)

	.PARAMETER Certificate
	The certificate to use as the default

	.PARAMETER Clear
	Clears the setting so Tokens become non-portable

	.PARAMETER clobber
	Saves the Default Certificate (actual cert or 'clear' so it's the default going forward

	.EXAMPLE
	Set-STDefaultCertificate -Certificate cn=myne@certs -clobber

	This will set the default certificate to cn=myne@certs and saves it so it will always be the default until the next -clobber

	.EXAMPLE
	Set-STDefaultCertificate -Clear

	The Default Certificate will be cleared, and certs won't be portable by default. The previous default will be active at the next module instantiation.

	.EXAMPLE
	Set-STDefaultCertificate -Clear -Clobber

	Resets the saved default to "nothing" for the active session and future sessions

	#>
	[CmdletBinding(DefaultParameterSetName = "Set")]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Set', Position = 0)]
		[ValidateNotNullOrEmpty()]
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Find-STEncryptionCertificate -Filter "$WordToComplete").Subject
				} else {
					(Find-STEncryptionCertificate).Subject
				}
			})]
		[Alias('Cert', 'To')]
		[string] $Certificate,
		[Parameter(Mandatory = $false, ParameterSetName = 'Set')]
		[Parameter(Mandatory = $false, ParameterSetName = 'Clear')]
		[Alias('Force')]
		[switch] $Clobber = $false,
		[Parameter(Mandatory = $true, ParameterSetName = 'Clear')]
		[switch] $Clear = $false
	)

	$DefCertFile = "$script:scriptpath\config\DefaultCert.txt"

	if ($script:DefaultCert) {
		$OldDefCert = Find-STEncryptionCertificate -filter ${script:DefaultCert}$
		if ($OldDefCert) {
			Write-Host "Old Default Certififcate was" -ForegroundColor Green
			$OldDefCert
			Write-Host ''
		}
	}

	if ($Clear) {
		if ($script:DefaultCert -eq '') {
			Write-Host "Certificates is already blank - No change made" -ForegroundColor Yellow
			$Clobber = $false
		} else {
			Write-Host "Default Certificate is now empty" -ForegroundColor Yellow
			$script:DefaultCert = ''
		}
	}

	if ($Certificate) {
		$NewDefCert = Find-STEncryptionCertificate -filter ${Certificate}$
		if ($NewDefCert) {
			Write-Host "New Default Certificate is " -ForegroundColor Green
			$NewDefCert
			Write-Host ''
			if ($NewDefCert.Thumbprint -eq $OldDefCert.Thumbprint) {
				Write-Host "Certificates Match - No change made" -ForegroundColor Yellow
				$Clobber = $false
			} else {
				$script:DefaultCert = $NewDefCert.Thumbprint
			}
		}
	}

	if ($clobber) {
		if (-not $(test-path -Path $script:ScriptPath\Config)) {
			$null = new-item -path $script:ScriptPath\config -ItemType Directory -ErrorAction SilentlyContinue
		}
		try {
			Set-Content -Path $DefCertFile -Value $script:DefaultCert
			Write-Host "The change has been saved" -ForegroundColor Green
		} catch {
			Write-Error "Could not save the file."
			$_.Exception
		}
	}

}


Function Add-SecureToken {
	<#
	.SYNOPSIS
	Add a token to the secured tokens file

	.DESCRIPTION
	Tokens are passwords or api-keys or other items that you might reference occasionally
	in scripts or command lines but that you don't want other people to know. This command
	adds a new token, secured via PowerShell's securestring encryption (tied to this user
	on this machine) or via certificate document encryption (potentially portable).

	If you use the Set-DefaultCertificate to set a .. um .. default certificate, all new
	Tokens will be created as Portable (using that .. um .. default certificate by .. um ..
	default). You can still use the -Certificate switch to specify a different cert for
	a particular Token, but you will not be able to create non-portable Tokens unless you
	clear the default certificate.

	.PARAMETER Name
	The name of the token - only used for reference to the stored Token

	.PARAMETER Token
	The actual token

	.PARAMETER Certificate

	.PARAMETER Clobber
	Overwrite an existing token if it exists

	.EXAMPLE
	Add-SecureToken -Name 'MyUserName' -Token 'P@ssw0rd!'

	This will save the token 'P@ssw0rd!' as an encrypted string for MyUserName

	.EXAMPLE
	Add-SecureToken -Name 'PortablePassword' -Token 'P@ssw0rd!' -Certificate 'cn=portable@localhost'

	This will save the token as an encrypted string using the cn=portable@localhost certificate

	#>
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					Get-SecureTokenList -Filter "$WordToComplete"
				} else {
					Get-SecureTokenList
				}
			})]
		[Alias('UserName', 'User', 'Item')]
		[string] $Name,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[Alias('Password', 'Secret')]
		[string] $Token,
		[Parameter(Mandatory = $false, Position = 0)]
		[Alias('Force')]
		[switch] $Clobber = $false,
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Find-STEncryptionCertificate -Filter "$WordToComplete").Subject
				} else {
					(Find-STEncryptionCertificate).Subject
				}
			})]
		[Alias('Cert', 'To')]
		[string] $Certificate = $script:DefaultCert
	)

	try {
		Write-Verbose "Trying to clear the invocation from history - keeps the password safer"
		Clear-History -Newest -Count 1
	} catch {
		Write-Host "Couldn't remove this command from History." -ForegroundColor Red
		Write-Host "Sorry, but the password will visible in the command history." -ForegroundColor Yellow
	}

	[bool] $DoIt = $true
	if (test-path "$($script:SecureTokenFolder)\$Name.txt") {
		Write-Host "File Exists! " -ForegroundColor Red
		if (-not $Clobber) {
			Write-Host "Please use the -Clobber switch if you want to over-write the file." -ForegroundColor Yellow
		}
		$DoIt = $Clobber
	}

	if ($DoIt) {
		$hash = @{
			Name  = $Name
			Token = $Token
		}
		if ($Certificate) { $hash.Add("Certificate", $Certificate)}
		$retval = Set-SavedToken @hash

		if ($retval -match "Error: ") {
			Write-Host "There was an error saving the token." -ForegroundColor Red
			Write-Host "  $retval" -ForegroundColor Yellow
		} else {
			Write-Host "Saved token to $retval" -ForegroundColor Green
		}
	} else {
		Write-Host 'Not saving the Token' -ForegroundColor Yellow
	}
}

