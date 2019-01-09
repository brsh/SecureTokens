Function New-Certificate {
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[string] $Subject = "$($env:USERNAME)@localhost.local",
		[string] $CertPath = "Cert:\CurrentUser\My",
		[datetime] $Expires = ((get-date).AddYears(100)),
		[int] $KeyLength = 2048
	)

	$hash = @{
		Subject           = $Subject
		Type              = 'DocumentEncryptionCert'
		KeyLength         = $KeyLength
		KeySpec           = 'KeyExchange'
		KeyExportPolicy   = 'Exportable'
		KeyUsage          = @('KeyEncipherment', 'DataEncipherment', 'KeyAgreement')
		NotAfter          = $Expires
		CertStoreLocation = $CertPath
		ErrorAction       = 'stop'
	}

	try {
		if ($pscmdlet.ShouldProcess("$CertPath", "Trying to create: $Subject")) {
			$retval = New-SelfSignedCertificate @hash
		} else {
			$retval = @{
				Header  = 'Information'
				Message = "Would have created Cert: $subject in Path: $CertPath "
			}
		}
	} catch {
		$retval = @{
			Header  = 'Error'
			Message = "$_.Exception.Message"
		}
	}

	Find-STEncryptionCertificate -filter $retval.Thumbprint.ToString()
	<#
	#https://docs.microsoft.com/en-us/powershell/module/pkiclient/new-selfsignedcertificate?view=win10-ps
	New-SelfSignedCertificate -Subject "cn=$Subject" -Type DocumentEncryptionCert -KeyLength 2048
	-KeySpec KeyExchange -KeyExportPolicy Exportable -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement
	-NotAfter $((Get-Date).AddYears(100)) -CertStoreLocation "Cert:\CurrentUser\My"

	# SAN:
	#-DnsName domain.example.com,anothersubdomain.example.com
	# Wildcard:
	#-dnsname *.example.com
	#>
}



Function Get-TimeUntil {
	param (
		[datetime] $Date
	)
	[datetime] $Now = Get-Date
	[int] $Years = $Date.Year - $Now.Year
	[int] $Months = $Date.Month - $Now.Month
	[int] $Days = $Date.Day - $Now.Day
	[int] $DaysLastMonth = 0

	If ($Date.Month -eq 1) {
		$DaysLastMonth = [DateTime]::DaysInMonth($Date.Year - 1, 12)
	} else {
		$DaysLastMonth = [DateTime]::DaysInMonth($Date.Year, $Date.Month - 1)
	}
	If ($Days -lt 0) {
		$Months = $Months - 1
		$Days = $Days + $DaysLastMonth
	}
	If ($Months -lt 0) {
		$Years = $Years - 1
		$Months = $Months + 12
	}

	$infohash = @{
		Years  = $Years
		Months = $Months
		Days   = $Days
	}

	$InfoStack = New-Object -TypeName PSObject -Property $InfoHash

	#Add a (hopefully) unique object type name
	$InfoStack.PSTypeNames.Insert(0, "SecureTokens.TimeUntil")

	#Sets the "default properties" when outputting the variable... but really for setting the order
	$defaultProperties = @('Years', 'Months', 'Days')
	$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultProperties)
	$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
	$InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

	$InfoStack

}

function Format-STEncryptionCertificate {
	param (
		[System.Security.Cryptography.X509Certificates.X509Certificate2] $cert,
		[string] $CertPath
	)

	$TimeRemaining = Get-TimeUntil -Date $cert.NotAfter

	$infohash = @{
		Thumbprint           = $cert.Thumbprint
		Subject              = $cert.Subject
		Expires              = $cert.NotAfter
		Created              = $cert.NotBefore
		TimeRemaining        = $TimeRemaining
		EnhancedKeyUsageList = $cert.EnhancedKeyUsageList
		Extensions           = $cert.Extensions
		SerialNumber         = $cert.SerialNumber
		HasPrivateKey        = $cert.HasPrivateKey
		CertPath             = $CertPath
	}

	$InfoStack = New-Object -TypeName PSObject -Property $InfoHash

	$InfoStack.PSTypeNames.Insert(0, "SecureTokens.EncryptionCertificates")

	$InfoStack
}
