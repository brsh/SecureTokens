Function Rename-SecureToken {
	<#
	.SYNOPSIS
	Renames an existing Token to the specified Name

	.DESCRIPTION
	Returns a object containing the old name and the new name

	.PARAMETER Name
	The name of the existing saved token

	.PARAMETER NewName
	The um... new name for the token

	.PARAMETER Confirm
	Prompts to confirm the file should be renamed

	.EXAMPLE
	Rename-SecureToken -Name 'Aida' -NewName 'Adia'

Name       NewName
----       -----
Aida       Aida


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
		[Parameter(Mandatory = $true)]
		[string] $Name,
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					Get-SecureTokenList -Filter "$WordToComplete"
				} else {
					Get-SecureTokenList
				}
			})]
		[Parameter(Mandatory = $true)]
		[string] $NewName,
		[switch] $Confirm = $false
	)

	$hash = @{
		Name    = $Name
		NewName = '!! Not renamed !!'
	}

	$STFolder = Get-SecureTokenFolder
	if ($STFolder.Exists) {
		[string] $RealName = Get-SecureTokenList -Filter ${Name}$
		if ($RealName) {
			$hash.Name = $RealName
			$TestNewName = Get-SecureTokenList -Filter ${NewName}$
			if ($TestNewName) {
				$hash.NewName = "Error: NewName already exists !!"
			} else {
				try {
					$file = "$($STFolder.Folder)\${RealName}.txt"
					$newfile = "$($STFolder.Folder)\${NewName}.txt"
					$a = Rename-Item -Path $file -NewName $newfile -Confirm:$Confirm -PassThru
					if ($a) {
						$hash.NewName = $NewName
					} else {
						$hash.NewName = "Error: Assuming confirm was a No"
					}
				} catch {
					$hash.NewName = "Error: $($_.Exception.Message)"
				}
			}
		} else {
			$hash.NewName = "Error: SecureToken doesn't exist"
		}
	} else {
		$hash.NewName = "Error: SecureTokenFolder doesn't exists ?!?!"
	}

	New-Object -TypeName psobject -Property $hash
}

Function Remove-SecureToken {
	<#
	.SYNOPSIS
	Deletes an existing Token

	.DESCRIPTION
	Returns an object with either a confirmation of deltion... or a reason why not

	.PARAMETER Name
	The name of the existing saved token

	.PARAMETER Confirm
	Prompts to confirm the file should be renamed

	.EXAMPLE
	Remove-SecureToken -Name 'Aida'

Name       Deleted
----       -----
Aida       True


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
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Name,
		[switch] $Force = $false,
		[switch] $Confirm = $false
	)

	#Deprecating $Confirm cuz it's the wrong option here
	#It's a delete, it should never just do it!
	[bool] $JustDoIt = $true
	if ($Confirm.IsPresent) { $JustDoIt = $Confirm }
	if ($Force.IsPresent) { $JustDoIt = -not $Force }

	$hash = @{
		Name    = $Name
		Deleted = '!! Not removed !!'
	}

	$STFolder = Get-SecureTokenFolder
	if ($STFolder.Exists) {
		[string] $RealName = Get-SecureTokenList -Filter ${Name}$
		if ($RealName) {
			$hash.Name = $RealName
			try {
				$file = "$($STFolder.Folder)\${RealName}.txt"
				Remove-Item -Path $file -Confirm:$JustDoIt
				$hash.Deleted = (-not (test-path $file))
			} catch {
				$hash.Deleted = "Error: $($_.Exception.Message)"
			}
		} else {
			$hash.Deleted = "Error: SecureToken doesn't exist"
		}
	} else {
		$hash.Deleted = "Error: SecureTokenFolder doesn't exists ?!?!"
	}
	$out = New-Object -TypeName psobject -Property $hash
	$out.PSObject.TypeNames.Insert(0, 'SecureTokens.RemovedToken')
	$out
}
