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
You must import this module via PowerShell native Import-Module command

```powershell
import-module SecureTokens
```

From there you can:

| Set-SecureTokenFolder | Set (and save) the location of the files that hold secured tokens |
| Get-SecureTokenFolder | Returns the path to the tokens folder |
| Add-SecureToken | Add a token to the secured tokens file |
| Get-SecureToken | Returns the Token for the specified Name |
| Get-SecureTokenList | Returns the names of all tokens |
| Get-SecureTokenHelp | List commands available in the SecureTokens Module |

The module will automatically show these commands on load (it runs
Get-SecureTokenHelp) unless you use the `-ArgumentList $true` command.

## Examples

### Example 1
Importing the module

```powershell
Import-Module .\SecureTokens.psd1 -Force
Attempting to load SecureTokens config file...
  Loaded config file
  Path to SecureTokens (C:\Users\user\AppData\Roaming\SecureTokens) is valid

Getting available functions...

Command               Description
-------               -----------
Add-SecureToken       Add a token to the secured tokens file
Get-SecureTokenFolder Returns the path to the tokens folder
Get-SecureTokenHelp   List commands available in the SecureTokens Module
Get-SecureTokenList   Returns the names of all tokens
Set-SecureTokenFolder Set (and save) the location of the files that hold secured tokens
```

### Example 2
Saving a token called Aida

```powershell
Add-SecureToken -Name 'Aida' -Token '1234-5678-9'
Saved token to C:\Users\user\AppData\Roaming\SecureTokens\Aida.txt
```

### Example 3
Listing all tokens

```powershell
Get-SecureTokenList
Aida
Candy
Myne
Myne2
```

### Example 4, 5, & 6
Filtering saved tokens (regex!)

All that start with C:
```powershell
Get-SecureTokenList -Filter C
Candy
```

All that have a y in the name
```powershell
Get-SecureTokenList -Filter "\w+y"
Myne
Myne2
```

All that have a digit in the name
```powershell
Get-SecureTokenList -Filter "\d"
Myne2
```

### Example 7
Viewing a token

```powershell
Get-SecureToken -Name 'Aida'

Name       Token
----       -----
Aida       1234-5678-9
```




