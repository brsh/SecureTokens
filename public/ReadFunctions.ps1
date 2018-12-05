Function Get-SecureTokenFolder {
	<#
	.SYNOPSIS
	Returns the path to the tokens folder

	.DESCRIPTION
	This function lists the folder where all of the SecureTokens are stored.

	.EXAMPLE
	Get-SecureTokenFolder

Folder                                       Exists
------                                       ------
C:\Users\user\AppData\Roaming\SecureTokens   True
	#>

	$hash = @{
		Folder = [string] ''
		Exists = [bool] $false
	}

	if ($script:SecureTokenFolder) {
		Write-Verbose "The SecureTokenFolder = $($script:SecureTokenFolder)"
		$hash.Folder = $script:SecureTokenFolder
		$hash.Exists = test-path $script:SecureTokenFolder -ErrorAction SilentlyContinue
	} else {
		Write-Host "SecureTokenFolder is not set. Use Set-SecureTokenFolder to correct that."
	}
	New-Object -TypeName psobject -Property $Hash
}

Function Get-SecureTokenList {
	<#
	.SYNOPSIS
	Returns the names of all tokens

	.DESCRIPTION
	This function will return a list of all tokens stored in the SecureTokenFolder.
	The list does not include the values. You can over-ride the default folder via
	the -Folder switch.

	You can filter the list via the -Filter command - which accepts regex!

	.PARAMETER Folder
	The folder to search (if you want to over-ride the default)

	.PARAMETER Filter
	A regex to filter the names

	.EXAMPLE
	Get-SecureTokenList

	Returns the full list

	.EXAMPLE
	Get-SecureTokenList -Folder C:\AlternameFolder

	Returns the full list stored in C:\AlternateFolder

	.EXAMPLE
	Get-SecureTokenList -Filter '\d'

	Returns a list of all items with digits in the name

	.EXAMPLE
	Get-SecureTokenList -Filter D

	Returns a list of all items that start with D
	#>
	param (
		[Alias('Directory', 'Dir')]
		[string] $Folder = (Get-SecureTokenFolder).Folder,
		[string] $Filter = ''
	)

	if ($Folder) {
		if (test-path $Folder) {
			try {
				[string[]] $list = (Get-ChildItem $Folder -Filter '*.txt' -ErrorAction Stop).BaseName
				if ($filter) {
					$list = $list | Where-Object { $_ -match "^$Filter" }
				}
				$list
			} catch {
				throw "Could not list directory!"
			}
		} else {
			Write-Host "Folder ($Folder) does not exist." -ForegroundColor Red
			Write-Host "Try Get-SecureTokenFolder or Set-SecureTokenFolder." -ForegroundColor Yellow
		}
	} else {
		Write-Host "No folder specified or defined." -ForegroundColor Red
		Write-Host "Try Get-SecureTokenFolder or Set-SecureTokenFolder." -ForegroundColor Yellow
	}
}

Function Get-SecureToken {
	<#
	.SYNOPSIS
	Returns the Token for the specified Name

	.DESCRIPTION
	Returns a object containing the no-longer-secret token

	.PARAMETER Name
	The name of the saved token

	.EXAMPLE
	Get-SecureToken -Name 'Aida'

Name       Token
----       -----
Aida       1234-5678-9

	.EXAMPLE
	Get-SecureToken -Name 'Aida2'

Name       Token
----       -----
Aida2      Not Found



	#>
	param (
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					Get-SecureTokenList -Filter "$WordToComplete"
				} else {
					Get-SecureTokenList
				}
			})]
		[ValidateScript( {
				$_ -in (Get-SecureTokenList)
			})]
		[string] $Name = ''
	)

	$hash = @{
		Name  = $Name
		Token = 'Not Found'
	}

	[string] $RealName = Get-SecureTokenList -Filter $Name$
	if ($RealName) {
		$hash.Name = $RealName
		$hash.Token = Get-SavedToken -Name $Name
	}
	New-Object -TypeName psobject -Property $hash
}
