# Windows Recursive Environment Variables Resolver

In Windows OS (10,11) environment, if you use a variable with a reference 
to a variable that refers to another one, 
Windows does not resolve the variables recursively but stops at the first level.

```
PYTHON_HOME_13_3=c:\path\to\python_13.3
PYTHON_HOME_12=c:\path\to\python_12.4
PYTHON_HOME=%PYTHON_HOME_13_3%
PATH=...;%PYTHON_HOME%;...
(Get-Item "Env:PATH").value
...;%PYTHON_HOME%;...
```

The script is used to resolve this limit.

## How to use it
Download the script (eg, C:\Users\MyUser\Scripts\wervr.ps1) and make it to be used when you create 
a new instance of PowerShell itself, or if you use Terminal, add it to its configuration file.

```PowerShell
. C:\Users\MyUser\Scripts\wervr.ps1
$res = Resolve-EnvVaraibleRecursive("PATH")
if ($res.Code -ne 0) {
	Write-Host -noNeLine "Warning: "
	Write-Host $result.Value
}else{
	Set-Item -Path "Env:PATH" -Value $res.Value
}
```

If you just need to update the variable you can use the "Wrapper" that does the same.
```PowerShell
. C:\Users\MyUser\Scripts\wervr.ps1
Resolve-EnvVaraibleRecursive-Wrapper("PATH")
```

## Enable features in Power Shell sessions
You can enable the features of this script by adding it in Power Shell profile.

### ✅ 1. Using PowerShell profile
NB: This method works EVERY TIME you open an instance of PowerShell.
This is the way I suggest using

PowerShell uses a profile file executed for each new instance.
You can add the scripts here.

#### 🔍 Check if profile file exists:
Open PowerShell and type

```PowerShell
$PROFILE
```

It should show the path to the PowerShell profile file, or not
```
C:\Users\Lorenzo\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

#### 🛠 If profile file does not exist, create it

```PowerShell
if (!(Test-Path -Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force
}
```

#### Editing file

Open the profile file using your preferred editor and add this new line:

```PowerShell
. "C:\Path\To\Your\Script.ps1"
```

In our example

```PowerShell
. "C:\Users\MyUser\Scripts\wervr.ps1"
```

Ensure using point (.) at the beginning to execute the script in the current session.

### ✅ 2. Enable in Windows Terminal (if you use it)
NB: This stuff works only when you use PowerShell inside Windows Terminal.

If you use Windows Terminal (the terminal that has tabs in the head of the window), you can configure the PowerShell profile to execute the script when you run it.

#### Using Windows Terminal GUI
1. Open Windows Terminal and open the menu under the down arrow at the top, on the left of the profile name (eg, PowerShell).
2. Choose "Settings" and open the "Settings" tab
3. Click on "Open JSON file" you see at the left bottom of the window.
4. In the opened editor, search profile "PowerShell" (not Windows PowerShell) 

```JSON
"commandline": "powershell.exe -NoExit -File \"C:\\Path\\To\\Your\\Script.ps1\""
```

###@ Editing directly the file
Open file 

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

and edit PowerShell profile (not "Windows PowerShell")

```JSON
"commandline": "powershell.exe -NoExit -File \"C:\\Path\\To\\Your\\Script.ps1\""
```
