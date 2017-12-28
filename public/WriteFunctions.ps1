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

Function Add-SecureToken {
	<#
	.SYNOPSIS
	Add a token to the secured tokens file

	.DESCRIPTION
	Tokens are passwords or api-keys or other items that you might reference occasionally
	in scripts or command lines but that you don't want other people to know. This command
	adds a new token, secured via PowerShell's securestring encryption.

	.PARAMETER Name
	The name of the token - only used for reference to the stored Token

	.PARAMETER Token
	The actual token

	.PARAMETER Clobber
	Overwrite an existing token if it exists

	.EXAMPLE
	Add-SecureToken -Name 'MyUserName' -Token 'P@ssw0rd!'

	This will save a the token 'P@ssw0rd!' as an encrypted string for MyUserName

	#>
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Alias('UserName', 'User', 'Item')]
		[string] $Name,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[Alias('Password', 'Secret')]
		[string] $Token,
		[Parameter(Mandatory = $false, Position = 0)]
		[Alias('Force')]
		[switch] $Clobber = $false
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
		$retval = Set-SavedToken -Name $Name -Token $Token
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

