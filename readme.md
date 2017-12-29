# SecuredTokens

## Overview

I wrote this module as a way to manage passwords and application api tokens
used by my scripts. Rather than save them un-encrypted or un-obfuscated where
anyone and everyone could either read them or figure them out, this leverages
the built-in features of the PowerShell secure-string.

Is it absolutely secure? No, not really. But it is limited to decoding only
by the user who creates them on the machine they're created on, so that helps.
A little.

### Folder for Tokens
I default the tokens to the user's AppData\Roaming folder:

```
C:\Users\username\AppData\Roaming\SecureTokens
```

Each file is a simple text file with using the token name as the filename
and holding the encrypted string in the body of the file. You can change
the name, but don't change the content!

### Usage
You must import this module via the PowerShell native Import-Module command

```powershell
import-module SecureTokens
```

From there you can:

Command                 | Description
--- | ---
Set-SecureTokenFolder   | Set (and save) the location of the files that hold secured tokens
Get-SecureTokenFolder   | Returns the path to the tokens folder
Add-SecureToken         | Add a token to the secured tokens file
Get-SecureToken         | Returns the Token for the specified Name
Get-SecureTokenList     | Returns the names of all tokens
Get-SecureTokenHelp     | List commands available in the SecureTokens Module

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
PS C:\Scripts> Import-Module .\SecureTokens.psd1 -Force
Attempting to load SecureTokens config file...
  Loaded config file
  Path to SecureTokens (C:\Users\user\AppData\Roaming\SecureTokens) is valid

Getting available functions...

Command               Description
-------               -----------
Add-SecureToken       Add a token to the secured tokens file
Get-SecureToken       Returns the Token for the specified Name
Get-SecureTokenFolder Returns the path to the tokens folder
Get-SecureTokenHelp   List commands available in the SecureTokens Module
Get-SecureTokenList   Returns the names of all tokens
Set-SecureTokenFolder Set (and save) the location of the files that hold secured tokens
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

To check the location
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
PS C:\Scripts> Get-SecureTokenList -Filter "\d"
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
````


