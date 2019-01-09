Function Find-STEncryptionCertificate {
	<#
	.SYNOPSIS
	Returns certificates available for encryption

	.DESCRIPTION
	This function will return a list of all certificates that can be used for encryption. You can pipe the cert(s) found
	to the other TSCert functions for further processing (like exporting).

	By default, the function will return certs from the CurrentUser\My store. However, you can use the LocalMachine switch
	to list certs from the LocalMachine\My store instead.

	The output includes the expiration date - and will color code the date as you get closer to the expiratoin (green is good,
	yellow is close, red is within a month!)

	You can filter the list on subject and thumbnail via the -Filter command - which accepts regex

	.PARAMETER LocalMachine
	Look in the LocalMachine store rather than the CurrentUser

	.PARAMETER Filter
	A regex to filter the subject or thumbprint

	.EXAMPLE
	Find-STEncryptionCertificate

	Returns the full list of all CurrentUser certs that can encrypt data

	.EXAMPLE
	Find-STEncryptionCertificate -LocalMachine

	Returns the full list of all LocalMachine certs that can encrypt data

	.EXAMPLE
	Find-STEncryptionCertificate -Filter '\d'

	Returns a list of all certs with only digits in the subject or thumbprint

	.EXAMPLE
	Find-STEncryptionCertificate -Filter D

	Returns a list of all certs whose subject or thumbprint starts with D
	#>
	param (
		[switch] $LocalMachine = $false,
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Find-STEncryptionCertificate -Filter "$WordToComplete").Subject
				} else {
					(Find-STEncryptionCertificate).Subject
				}
			})]
		[Parameter(HelpMessage = 'You must supply a valid subject or thumbprint on which to filter')]
		[string] $Filter
	)
	if ($LocalMachine) {
		$CertPath = 'Cert:\LocalMachine\My'
	} else {
		$CertPath = 'Cert:\CurrentUser\My'
	}

	$a = Get-ChildItem $CertPath | Where-Object { $_.Extensions.KeyUsages -match 'DataEncipherment' }

	if ($filter) {
		$a = $a | Where-Object { ($_.Subject -match $filter) -or ($_.Thumbprint -match $filter) }
	}

	#$a = $a | Select-Object Thumbprint, Subject, NotAfter, NotBefore, EnhancedKeyUsageList, Extensions, SerialNumber | Sort-Object NotAfter
	$a = $a | Sort-Object NotAfter

	$a | ForEach-Object {
		Format-STEncryptionCertificate -cert $_ -CertPath $CertPath
	}
}

Function New-STEncryptionCertificate {
	<#
	.SYNOPSIS
	Creates a new document encryption certificate

	.DESCRIPTION
	This function will create a new Encryption Certificate, either in the current user's
	personal cert store (cert:\currentuser\my; the default location) or in the local machine's
	cert store (cert:\localmachine\my; selectable via the -LocalMachine switch).

	You can use this cert to encrypt SecureTokens ... which can then be decrypted by any user
	on any machine as long as they have the certificate installed. And yes, there are 2 functions
	to help with exporting and importing certificates. Try:

		Get-Help Export-STEncryptionCertificate
		Get-Help Import-STEncryptionCertificate

	You _can_ have multiple certs with the same subject name (and this function will let you),
	but be careful with that ... the selection of the correct cert is limited at this point.

	Oh, and be specific with your subject names ... you want something recognizable and
	specific to the tasks for which it will be used. Your personal work-to-home cert should be
	different (and obviously so) from the cert your team uses for management scripts!

	.PARAMETER Subject
	A string to identify the certificate (in the form of 'cn=something@somewhere' or similar)

	.PARAMETER LocalMachine
	Save the new cert in the LocalMachine store rather than the CurrentUser

	.PARAMETER Days
	The number of days in the future that the cert should be valid

	.PARAMETER Years
	The number of years in the future that the cert should be valid (default is 100)

	.PARAMETER HighKeyLength
	Use 4096 bit key vs the 2048 key that is set by default

	.PARAMETER Clobber
	Create a cert with a duplicate subject

	.PARAMETER WhatIf
	Doesn't actually create the cert, just tells you it would have

	.EXAMPLE
	New-STEncryptionCertificate -Subject 'me@here.com'

	Creates a new cert with subject me@here.com' in the current user store

	.EXAMPLE
	New-STEncryptionCertificate -Subject 'me@here.com' -LocalMachine

	Creates a new cert with subject me@here.com' in the local machine store

	#>
	[CmdletBinding(DefaultParameterSetName = 'Years')]
	param (
		[string] $Subject = "$($env:USERNAME)@localhost.local",
		[switch] $LocalMachine = $false,
		[Parameter(Mandatory = $false, ParameterSetName = 'Days')]
		[int] $Days = 100,
		[Parameter(Mandatory = $false, ParameterSetName = 'Years')]
		[int] $Years = 100,
		[switch] $HighKeyLength = $false,
		[Alias('Force')]
		[switch] $Clobber = $false,
		[switch] $WhatIf = $false
	)

	if ($Subject -notmatch 'cn=') { $Subject = "cn=$Subject" }

	[bool] $Machine = $false
	[string] $CertPath = "Cert:\CurrentUser\My"
	if ($LocalMachine) {
		$CertPath = "Cert:\LocalMachine\My"
		$Machine = $true
	}

	$FoundCerts = Find-STEncryptionCertificate -Filter $Subject -LocalMachine:$Machine

	if (($FoundCerts.Count -gt 0) -and (-not $Clobber)) {
		Write-Host "Found $($FoundCerts.Count) cert(s) with Subject: $Subject." -ForegroundColor Yellow
		$FoundCerts | ForEach-Object { Write-Host "`t$($_.Thumbprint)`t$($_.Subject)" }
		Write-Host "Use the -Clobber switch if you want to add another" -ForegroundColor Yellow
	} else {
		if ($PSCmdlet.ParameterSetName -eq 'Days') {
			$expires = (Get-Date).AddDays($Days)
		} else {
			$expires = (Get-Date).AddYears($Years)
		}

		[int] $KeyLength = 2048
		if ($HighKeyLength) {
			$KeyLength = 4096
		}

		$retval = New-Certificate -Subject $Subject -CertPath $CertPath -Expires $expires -KeyLength $KeyLength -WhatIf:$WhatIf

		$retval
	}
}

Function Export-STEncryptionCertificate {
	<#
	.SYNOPSIS
	Exports a document encryption certificate for later import

	.DESCRIPTION
	This function will export an Encryption Certificate that you can copy and import
	on another machine (or as another user). Tokens encrypted with the cert can be
	decrypted by those users on that other machine! (Tokens are portable!)

	Use with Import-STEncryptionCertificate

	.PARAMETER Thumbprint
	The string that identifies the cert - uses thumbprints in case of dupes (but can autocomplete to Thumbprint from subject text...)

	.PARAMETER CertPath
	The path to the Cert Store (I make you type this to be sure you know what you're doing... but I let you pipe it in from the Find-STEncryptionCertificate funtion cuz I'm nice)

	.PARAMETER OutPath
	The path where the file will be stored - expects a directory, defaults to temp

	.PARAMETER Password
	The password that will protect the file (must be a secure string, but the function will prompt you)

	.PARAMETER Confirm
	Makes you say yes to each export (Yes to all doesn't work tho')

	.PARAMETER WhatIf
	Doesn't actually export the cert, just tells you it would have

	.EXAMPLE
	Export-STEncryptionCertificate -Thumbprint 'EEDSFEWESF...blah'

	Exports the cert from the current user's store with that thumbprint to the $env:temp folder

	.EXAMPLE
	Export-STEncryptionCertificate -Thumbprint 'EEDSFEWESF...blah' -CertPath 'Cert:\LocalMachine\My

	Exports the cert from the local machine's store with that thumbprint to the $env:temp folder

	.EXAMPLE
	Find-STEncryptionCertificate | Export-STEncryptionCertificate -OutPath .

	Exports ALL certs from the current user's store and sames them in the current folder

	.EXAMPLE
	Find-STEncryptionCertificate -filter 'mine' | Export-STEncryptionCertificate -OutPath .

	Exports certs with 'mine' in their subject from the current user's store and sames them in the current folder

	#>
	param (
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Find-STEncryptionCertificate -Filter "$WordToComplete").Thumbprint
				} else {
					(Find-STEncryptionCertificate).Thumbprint
				}
			})]
		[Parameter(Mandatory = $true, HelpMessage = "Supply the certificate Thumbprint", ValueFromPipelineByPropertyName = $true)]
		[string] $Thumbprint,
		[Parameter(Mandatory = $false, HelpMessage = "The path to the cert", ValueFromPipelineByPropertyName = $true)]
		[string] $CertPath = "Cert:\CurrentUser\My",
		[string] $OutPath = $env:temp,
		[Parameter(Mandatory = $true, HelpMessage = "You must supply a password!")]
		[securestring] $Password = $(Read-Host 'Password' -AsSecureString),
		[switch] $Confirm = $false,
		[switch] $WhatIf = $false
	)
	BEGIN {	}

	PROCESS {
		$cert = "${CertPath}\${thumbprint}"
		$OutFile = "${OutPath}\${thumbprint}.pfx"

		try {
			# https://docs.microsoft.com/en-us/powershell/module/pkiclient/export-pfxcertificate?view=win10-ps
			$a = Export-PfxCertificate -Cert $cert -FilePath $OutFile -Password $Password -ChainOption BuildChain -Confirm:$Confirm -WhatIf:$WhatIf -ErrorAction Stop
			$hash = @{
				Status     = 'Success'
				Thumbprint = $Thumbprint
				FileName   = $a.FullName
			}
			$InfoStack = New-Object -TypeName PSObject -Property $hash

			$InfoStack.PSTypeNames.Insert(0, "SecureTokens.ExportedCertificates")

			$InfoStack
			#Export-Certificate -Cert cert:\localMachine\my\F81AFDC2A23B8629580374E64871941476E43F02 -FilePath root-authority.crt
		} catch {
			$hash = @{
				Status     = 'Error'
				Thumbprint = $Thumbprint
				FileName   = $_.Exception.Message
			}
			$InfoStack = New-Object -TypeName PSObject -Property $hash

			$InfoStack.PSTypeNames.Insert(0, "SecureTokens.ExportedCertificates")

			$InfoStack
		}
	}

	END { }
}

function Import-STEncryptionCertificate {
	<#
	.SYNOPSIS
	Imports a document encryption certificate for use

	.DESCRIPTION
	This function will import an Encryption Certificate to encrypt or decrypt Tokens
	for use by other users and/or other machine! (Tokens are portable!).

	One caveat ... the PowerShell cmdlet that does this doesn't care if the cert
	already exists: It'll just overwrite it. There is little I can do to verify if
	the cert is already there since the cmdlet that gets info from the file does _not_
	allow passing the password to the file as a command line switch - it always prompts!
	(Well, ok, they fixed that in PS Core 6+, but this has to work on older PS so...).
	Anyhoo, rather than bog down multi-file processing with constant password prompts,
	and since thumbnails are _extremely reasonably_ unique to the exact cert, I figure
	you prolly don't care if you overwrite a cert with itself.

	Use with Export-STEncryptionCertificate

	.PARAMETER Fullname
	A FileInfo object of the file(s) to import. This one is for piping dir/get-childitem commands

	.PARAMETER Filename
	The filename to import - this one is a straight-up string for manually typing the name or piping get-content of a text list

	.PARAMETER LocalMachine
	Import this to the local machine's cert store (not the current user)

	.PARAMETER Password
	The password that will protect the file (must be a secure string, but the function will prompt you)

	.PARAMETER Confirm
	Makes you say yes to each import (Yes to all doesn't work tho')

	.PARAMETER WhatIf
	Doesn't actually import the cert, just tells you it would have

	.EXAMPLE
	Import-STEncryptionCertificate -Filename 'this.pfx'

	Imports the file this.pfx

	.EXAMPLE
	Get-ChildItem *.pfx | Import-STEncryptionCertificate

	Imports all the pfx files from the current dir

	.EXAMPLE
	Get-Content ListofFiles.txt | Import-STEncryptionCertificate -LocalMachine

	Imports all the files listed in the txt file to the LocalMachine cert store

	#>
	param (
		[Parameter(Mandatory = $false, ParameterSetName = 'FileInfo', ValueFromPipelineByPropertyName = $true)]
		[System.IO.FileInfo] $Fullname,
		[Parameter(Mandatory = $false, ParameterSetName = 'FileName')]
		[string] $Filename,
		[switch] $LocalMachine = $false,
		[Parameter(Mandatory = $true, HelpMessage = "You must supply a password!")]
		[securestring] $Password = $(Read-Host 'Password' -AsSecureString),
		[switch] $Confirm = $false,
		[switch] $WhatIf = $false
	)

	BEGIN {
		[string] $CertPath = "Cert:\CurrentUser\My"
		if ($LocalMachine) {
			$CertPath = "Cert:\LocalMachine\My"
		}
	}

	PROCESS {
		if ($PSCmdlet.ParameterSetName -eq 'FileName') {
			[string] $FullName = $Filename
		}

		try {
			$a = Import-PfxCertificate -CertStoreLocation $CertPath -Password $Password -Exportable -FilePath $Fullname -Confirm:$Confirm -WhatIf:$WhatIf
			if ($a) { Format-STEncryptionCertificate -cert $a -CertPath $CertPath }
		} catch {
			$hash = @{
				Status     = 'Error'
				Thumbprint = $Fullname.ToString().TrimStart('.\')
				FileName   = $_.Exception.Message
			}
			$InfoStack = New-Object -TypeName PSObject -Property $hash

			$InfoStack.PSTypeNames.Insert(0, "SecureTokens.ExportedCertificates")

			$InfoStack
		}
	}

	END { }
}
