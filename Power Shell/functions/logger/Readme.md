# Power Shell Level Based Logging Function

This script contains a function simulating a solution used in many languages based on log level system

The levels can be:
* DEBUG
* INFO
* WARN
* ERROR

Where DEBUG > INFO > WARN > ERROR.


## How to use it
Download the script (eg, C:\Users\MyUser\Scripts\lblf.ps1).
In your script include it and call Write-Log funciton passing the desired log Level

```PowerShell
Write-Log "This is a message for debug" "DEBUG"
```

Somewhere in the top of your script, you can decide the level of log you want to see by setting up LogLevel varable:
```PowerShell
$Global:LogLevel = "INFO"
```

And from your script you will see just messages since to desired level, not lower.

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
. "C:\Users\MyUser\Scripts\lblf.ps1"
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
