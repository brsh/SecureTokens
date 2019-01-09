# SecuredTokens

## Overview

I wrote this module as a way to manage passwords and application api tokens
used by my scripts. Rather than save them un-encrypted or un-obfuscated where
anyone and everyone could either read them or figure them out, this leverages
the built-in features of the PowerShell secure-string (non-portable) or cert
document encryption (portable).

Is it absolutely secure? No, not really. But the non-portable Token is limited
to decoding only by the user who creates them on the machine they're created on;
and the portable Token requires the correct certificate installed in the correct
certificate store. So that helps. A little.

Yes, you read that right:
  * the non-portable files created on 1 system by 1 user are useless on another
  system or for another user. **Only the user who creates the files can use them
  _on the machine where they are created_**.
  * the portable files created on 1 system by 1 user requires the correct certificate
  installed to the correct certificate store (so CurrentUser\My if it will be used
  by a user or LocalMachine\My if the script will be run "by the computer")


### Note
Huge shout out to Boe Prox for the CMS message encryption!
https://mcpmag.com/articles/2017/10/05/encrypting-data-with-powershell-cmdlets.aspx

SecureTokens are portable, baybee!!

### Folder for Tokens
I default the tokens to the user's AppData\Roaming folder:

```
C:\Users\username\AppData\Roaming\SecureTokens
```

Each file is a simple text file using the token name as the filename and
the encrypted string as the body of the file. You can change the filename,
but *don't change the content*!

Since these are files, you can delete and rename them via any of the usual
Windows file management tools. I've also added some low-key rename and
remove functions to help and make it a bit more self-contained.

I provide functions to manage certs (create-, export-, import-) ... but not
delete!! You can use PowerShell's certificate PSDrive for that (either
`cert:\CurrentUser\My` or `cert:\LocalMachine\My`) or the MMC.exe Certificates
snap-in (the `My` store is called `Personal\Certificates` there ... cuz
consistency).

### Usage
Naturally, the module should go where PowerShell modules go, either in the
`C:\Users\YourUser\Documents\WindowsPowerShell\Modules` (for you personally)
or the `C:\Windows\system32\WindowsPowerShell\v1.0\Modules` (for everyone)
folder. (Yes, there are other options, but these are generally the main ones).

You can then import this module via the PowerShell native Import-Module command:

```powershell
import-module SecureTokens
```

From there you can:

Command                        | Description
--- | ---
Set-SecureTokenFolder          | Set (and save) the location of the files that hold secured tokens
Get-SecureTokenFolder          | Returns the path to the tokens folder
Add-SecureToken                | Add a token to the secured tokens file
Get-SecureToken                | Returns the Token for the specified Name
Get-SecureTokenList            | Returns the names of all tokens
Get-SecureTokenHelp            | List commands available in the SecureTokens Module
New-STEncryptionCertificate    | Creates a new document encryption certificate
Find-STEncryptionCertificate   | Returns certificates available for encryption
Export-STEncryptionCertificate | Exports a document encryption certificate for later import
Import-STEncryptionCertificate | Imports a document encryption certificate for use
Remove-SecureToken             | Deletes an existing Token
Rename-SecureToken             | Renames an existing Token to the specified Name

The module will automatically show these commands on load (it runs
Get-SecureTokenHelp) unless you use the `-ArgumentList $true` option of
the Import-Module command (the first parameter of the module is 'Quiet').

```powershell
import-module SecureTokens -ArgumentList $true
```

On first run, the default location for tokens will *NOT* be created. You will
want to fix that with the `Set-SecureTokenFolder` command (examples below).

## Examples

### Initialization
Importing the module

```powershell
PS C:\Scripts> Import-Module SecureTokens
Attempting to load SecureTokens config file...
  Loaded config file
  Path to SecureTokens (C:\Users\user\AppData\Roaming\SecureTokens) is valid

Getting available functions...

Command               Description
-------               -----------
Add-SecureToken                Add a token to the secured tokens file
Export-STEncryptionCertificate Exports a document encryption certificate for later import
Find-STEncryptionCertificate   Returns certificates available for encryption
Get-SecureToken                Returns the Token for the specified Name
Get-SecureTokenFolder          Returns the path to the tokens folder
Get-SecureTokenHelp            List commands available in the SecureTokens Module
Get-SecureTokenList            Returns the names of all tokens
Import-STEncryptionCertificate Imports a document encryption certificate for use
New-STEncryptionCertificate    Creates a new document encryption certificate
Remove-SecureToken             Deletes an existing Token
Rename-SecureToken             Renames an existing Token to the specified Name
Set-SecureTokenFolder          Set (and save) the location of the files that hold secured tokens
```

### Working with the Tokens folder
To set the default location:
```powershell
PS C:\Scripts> Set-SecureTokenFolder -Default -Clobber
```

To set the your own location:
```powershell
PS C:\Scripts> Set-SecureTokenFolder -Folder 'C:\Scripts\Tokens' -Clobber
```

To set a temporary location (maybe alternate tokens? test vs prod?):
```powershell
PS C:\Scripts> Set-SecureTokenFolder -Folder 'C:\Scripts\ProdTokens'
```

To check the current token location
```powershell
PS C:\Scripts> Get-SecureTokenFolder

Folder                                       Exists
------                                       ------
C:\Users\user\AppData\Roaming\SecureTokens   True
```

### Adding Tokens
Saving a token called Aida
```powershell
PS C:\Scripts> Add-SecureToken -Name 'Aida' -Token '1234-5678-9'
Saved token to C:\Users\user\AppData\Roaming\SecureTokens\Aida.txt
```

```powershell
PS C:\Scripts> Add-SecureToken -Name 'Aida' -Token '1234-5678-9' -Certificate 'cn=mycert@localhost'
Saved token to C:\Users\user\AppData\Roaming\SecureTokens\Aida.txt
```

### Listing tokens
Listing all tokens
```powershell
PS C:\Scripts> Get-SecureTokenList
Aida
Candy
Myne
Myne2
```

#### Filtering saved tokens (regex!)

All that start with C
```powershell
PS C:\Scripts> Get-SecureTokenList -Filter C
Candy
```

All that have a y in the name
```powershell
PS C:\Scripts> Get-SecureTokenList -Filter "\w+y"
Myne
Myne2
```

All that have a digit in the name
```powershell
PS C:\Scripts> Get-SecureTokenList -Filter "\w+\d"
Myne2
```

### Using Tokens
Viewing a token
```powershell
PS C:\Scripts> Get-SecureToken -Name 'Aida'

Name       Token
----       -----
Aida       1234-5678-9
```

Using a token in a script
```powershell
$Token = (Get-SecureToken -Name SlackAPIToken).Token
if ($Token) {
  Add-SlackMessage -Channel 'Public' -Message 'Hello World!' -Token $Token
} else {
  "No token found"
}
```

### Modifying Tokens
Renaming a token
```powershell
PS C:\Scripts> Rename-SecureToken -Name 'Aida' -NewName 'Adia'

Name       NewName
----       -----
Aida       Adia
```

Deleting a token
```powershell
PS C:\Scripts> Remove-SecureToken -Name 'Aida' -Confirm

Confirm
Are you sure you want to perform this action?
Performing the operation "Remove File" on target "C:\Users\youruser\AppData\Roaming\SecureTokens\Aida.txt".
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y

Name   Deleted
----   -------
Aida      True
```

### Working with Certs
Creating a new certificate (defaults to 2048-bit and 100 year expiration)
```powershell
PS C:\Scripts> New-STEncryptionCertificate -Subject 'portableenc@localhost'

Thumbprint                                 Expires      Subject
----------                                 -------      -------
D4035B0B69002C00D2AD124EC2CC8FC0D93F0B4B   01/09/2119   CN=portableenc@localhost
```

Creating a new certificate (4096-bit and 100 days expiration)
```powershell
PS C:\Scripts> New-STEncryptionCertificate -Subject 'portableenc@localhost' -HighKeyLength -Days 100

Thumbprint                                 Expires      Subject
----------                                 -------      -------
D058A8397FDEF8ECB378406861FA7E6A64C2B1DC   04/19/2019   CN=portableenc@localhost
```

Viewing existing document encryption certificates
```powershell
PS C:\Scripts> Find-STEncryptionCertificate

Thumbprint                                 Expires      Subject
----------                                 -------      -------
EEA15A54F3B50E60E42E95F765CFC8D22D5E98A5   01/12/2019   CN=testenc3@localhost
2F6883858A09215233C2D80690707AC7CD36EAF2   04/12/2019   CN=testenc2@localhost
D058A8397FDEF8ECB378406861FA7E6A64C2B1DC   04/19/2019   CN=poratbleenc@localhost
51382C455E6590B00526AB99E5FDB5F63D1C53ED   01/02/2119   CN=testenc@localhost
D4035B0B69002C00D2AD124EC2CC8FC0D93F0B4B   01/09/2119   CN=poratbleenc@localhost
```

Export a certificate
```powershell
PS C:\Scripts> Export-STEncryptionCertificate -Thumbprint D058A8397FDEF8ECB378406861FA7E6A64C2B1DC -OutPath C:\Scripts\

cmdlet Export-STEncryptionCertificate at command pipeline position 1
Supply values for the following parameters:
(Type !? for Help.)
Password: ****

Thumbprint                               Status  Filename
----------                               ------  --------
D058A8397FDEF8ECB378406861FA7E6A64C2B1DC Success C:\Scripts\D058A8397FDEF8ECB378406861FA7E6A64C2B1DC.pfx
```
(you can, of course, rename this file)

Export all certificates
```powershell
PS C:\Scripts> Find-STEncryptionCertificate | Export-STEncryptionCertificate -OutPath .

cmdlet Export-STEncryptionCertificate at command pipeline position 2
Supply values for the following parameters:
(Type !? for Help.)
Password: ****

Thumbprint                               Status  Filename
----------                               ------  --------
EEA15A54F3B50E60E42E95F765CFC8D22D5E98A5 Success C:\Scripts\tcerts\EEA15A54F3B50E60E42E95F765CFC8D22D5E98A5.pfx
2F6883858A09215233C2D80690707AC7CD36EAF2 Success C:\Scripts\tcerts\2F6883858A09215233C2D80690707AC7CD36EAF2.pfx
D058A8397FDEF8ECB378406861FA7E6A64C2B1DC Success C:\Scripts\tcerts\D058A8397FDEF8ECB378406861FA7E6A64C2B1DC.pfx
51382C455E6590B00526AB99E5FDB5F63D1C53ED Success C:\Scripts\tcerts\51382C455E6590B00526AB99E5FDB5F63D1C53ED.pfx
D4035B0B69002C00D2AD124EC2CC8FC0D93F0B4B Success C:\Scripts\tcerts\D4035B0B69002C00D2AD124EC2CC8FC0D93F0B4B.pfx
```

Import a certificate
```powershell
PS C:\Scripts> Import-STEncryptionCertificate -Fullname .\D058A8397FDEF8ECB378406861FA7E6A64C2B1DC.pfx

cmdlet Import-STEncryptionCertificate at command pipeline position 1
Supply values for the following parameters:
(Type !? for Help.)
Password: ****

Thumbprint                                 Expires      Subject
----------                                 -------      -------
D058A8397FDEF8ECB378406861FA7E6A64C2B1DC   04/19/2019   CN=portableenc@localhost
```

Import all the certificate files
```powershell
PS C:\Scripts> dir *.pfx | Import-STEncryptionCertificate

cmdlet Import-STEncryptionCertificate at command pipeline position 2
Supply values for the following parameters:
(Type !? for Help.)
Password: ****

Thumbprint                                 Expires      Subject
----------                                 -------      -------
2F6883858A09215233C2D80690707AC7CD36EAF2   04/12/2019   CN=testenc2@localhost
51382C455E6590B00526AB99E5FDB5F63D1C53ED   01/02/2119   CN=testenc@localhost
D058A8397FDEF8ECB378406861FA7E6A64C2B1DC   04/19/2019   CN=portableenc@localhost
D4035B0B69002C00D2AD124EC2CC8FC0D93F0B4B   01/09/2119   CN=portableenc@localhost
EEA15A54F3B50E60E42E95F765CFC8D22D5E98A5   01/12/2019   CN=testenc3@localhost
```
(notice the 2 `portableenc` certs ... bad juju)

