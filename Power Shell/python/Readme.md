# Power Shell useful functions to manage python installations

This script contains some functions that could be useful for a python developer in a windows OS.
It helps manages different python versions installed in windows enabling the desired, creating venv with desired one and so on.


## Requirements
The script requirea you have installed the python and pip versions you use and that you add some varables i your windows environment:

* PYTHON_HOME_version1 = "C:\path\to\python\v1"
* PYTHON_HOME_version2 = "C:\path\to\python\v2"
* PYTHON_HOME = %PYTHON_HOME_version1%

version1, version2, ... should be in form 3_13, 3_11, ...

In PATH variable just add %PYTHON_HOME% and if you enable 'Windows Recursive Environment Variable Resolver module"|https://github.com/leccher/PowerShellScript---Windows-Recursive-Environment-Variables-Resolver
you have the desired version as enabled in windows.

# Script functions

## Enable Python version
This feature set the environment to working with a specific (already installed) version of python.
When you install new version of Python you must install respective pip version add respective 'PYTHON_PATH_version' variable in the environment.

To use it type

```PowerShell
pspf.ps1 setversion 3.13
```

and from now system (and current session of PowerShell) will use 3.13 python (and pip) version.

## Enalbe specific Python venv
Using 
```PowerShell
pspf.ps1 newvenv 3.13 3.13_test
```

Script tries to create a venv for the 3.13 version of Python with name .venv_3.13_test.
The specific vesion of python must be installed in system.

If no name is passed, the name of venv folder will be .venv_3.13

## Create specific Python venv by version and name

Using 
```PowerShell
pspf.ps1 setvenv .venv_3.13_test
```

Script tries to enable a venv in .venv_3.13_test forlder.

If no name is passed, the scripts shows a list of availabe folders with name starting with .venv
and asks to user to choose une. User can choose to create new one using current python version enabled.

# Python Virtual Environment and Jupyter Lab enabler
This script contains two functions that can enable the desired python venv if it is present and if in the selected venv, 
starts the jupyter notebook installed inside.

# Enable features in Power Shell sessions
You can enable the features of the script by adding it in Power Shell profile.

To just load script without using any feature, use:
```PowerShell
pspf.ps1 load
```

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
