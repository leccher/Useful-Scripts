
# my_powershell_profile_scripts.ps1

## Overview

The **`my_powershell_profile_scripts.ps1`** file is a PowerShell profile script designed to build a **modular, extensible, and event‑driven shell environment**.

It executes automatically at PowerShell startup (depending on the profile in use) and provides:

- automatic loading of custom PowerShell modules
- reliable directory change detection
- delegation of folder‑specific logic to modules (for example Python venv activation)
- a safe mechanism to temporarily disable directory watchers

---

## PowerShell Profiles

PowerShell supports multiple profile scopes that define **when** and **for whom** a profile script is executed.

Common profile locations:

- **AllUsersAllHosts**  
  `C:\Program Files\PowerShell\7\profile.ps1`

- **AllUsersCurrentHost**  
  `C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1`

- **CurrentUserAllHosts**  
  `C:\Users\YOUR_USER\Documents\PowerShell\profile.ps1`

- **CurrentUserCurrentHost**  
  `C:\Users\YOUR_USER\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

To inspect available profiles:

```powershell
$PROFILE | Select-Object *
```

---

## Creating the Profile

If the profile file does not exist, it can be created using:

```powershell
New-Item -ItemType File -Path $PROFILE -Force
```

Or for a specific profile:

```powershell
New-Item -ItemType File -Path "$env:USERPROFILE\Documents\PowerShell\Profile.ps1" -Force
```

---

## Default user module folder
Usually user modules are in '$HOME\Documents\PowerShell\Modules` folder.

### Custom module (like these)
You can specify a script that loads specific modules like this one.

---

# Module Management

This project includes an automatic PowerShell module loading and unloading system, based on dependencies declared in `.psd1` files and the actual runtime state of the session.

The goals are:

- load and unload all modules located in the `modules` folder
- without manually listing module names
- while respecting module dependencies
- avoiding incorrect load order or inconsistent states

---

## Loading modules (`Load-MyPowerShellModules`)

The `Load-MyPowerShellModules` function automatically loads all modules found in the `modules` folder, resolving dependencies incrementally and relying only on the actual PowerShell session state.

**How it works**

- Detects all modules in the `modules` folder
- Checks which modules are already loaded in the session

It loads only the modules that are:

- not already loaded
- whose dependencies (`RequiredModules` in the `.psd1`) are already satisfied

The process repeats until:

- all modules are loaded ✅
- or no further progress is possible (missing or circular dependencies) ⚠️

This approach avoids:

- random load order
- errors caused by unavailable dependencies
- assumptions about a clean initial session state

**Return codes**

- Code = 0 → all modules loaded successfully
- Code > 0 → partial load (some modules could not be loaded)
- Code < 0 → real error (e.g. missing modules folder)

Example usage:

```powershell
Load-MyPowerShellModules
```

---

### Unloading modules (`Unload-MyPowerShellModules`)

The `Unload-MyPowerShellModules` function safely unloads modules, preventing the removal of modules that are still required by others.

**How it works**

- Detects all managed modules (located in the `modules` folder)
- Checks which modules are currently loaded

It unloads only modules that:

- are not required by any other currently loaded module

The process repeats until:

- all modules are unloaded ✅
- or some modules cannot be unloaded without breaking dependencies ⚠️

Modules are therefore unloaded in reverse dependency order, even when the original load order is unknown.

**Return codes**

- Code = 0 → all modules unloaded successfully
- Code > 0 → partial unload (reverse dependencies still active)
- Code < 0 → real error

Example usage:

```powershell
Unload-MyPowerShellModules
```

---

## Internationalisation and Log Level modules
**Internaztionalisation** and **Loggging** modules are implemented to provide these two abilities.
### Internazionalisation module
This  custom profile allows creating modules with **i18n** features. Thies feature is implementing in other modules using localised files ('en-EN', 'it-IT') inside module `Localisation` folder. Here the local files must follow the rule `[module-name].messages.[localisation].psd1`.
Each file hse an HASH table with talking keys used in module code.

Here an example of `InternationalisationModule.messages.rn-EN.psd1`.
```PowerShell
@{
    # General
    MODULE_DESCRIPTION = 'PowerShell internationalisation module'

    HELP_HEADER = '--- Internationalisation Helper Module (i18n) ---'

    # Help (multiline)
    HELP_TEXT = @"
contains 2 functions:
- Import-ModuleMessages: imports a set of localized messages for a given module and language.
- Get-LocalizedMessage: retrieves a localized message by its ID and optional arguments.
"@
}
```

Example using in module code.
```PowerShell
function Show-i18n-Help {
	Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id HELP_HEADER)
	Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id HELP_TEXT)
}
```

Most advanced use with message and args inside:
```PowerShell
DEBUG_REPLACE = 'Replacing {0} -> {1}'
```

Used:
```PowerShell
Write-Host "[DEBUG] $(Get-LocalizedMessage -Id 'DEBUG_REPLACE' -Args $oldValue, $newValue)" -foregroundColor DarkGray
```

### Logging module
`LevelBasedLoggingModule` provide some base eature to help logging and debugging your script with `DEBUG,INFO,WARN,ERROR` levels logic. A thresholder level can be assigned to the session using `Set-LogLevel` function. Is also provided to write log into file using `Enable-LogToFile` (`Disable-LogToFile` to stop writing).

Logging module is provided feature by `Write-Log` function that format message adding date-time data, level and message `[timestamp][level] Message` and some defined colours.

The module provide 3 funtions to write messages on console:
- Write-LogWithDebug: If level of message and `LogLevel` is `DEBUG` uses PowerShell `Write-Debug` to write messages
- Write-LogWithoutDebug: `Write-Host` is used to write all messages in console.
- Write-LogWithStyle: Colours of output is provided using `$PSStyle` module.

To set the specific function change value of `$script:LoggingFunction` to the name of function you want:

```PowerShell
$script:LoggingFunction = 'Wrtie-LogWithStyle'
```

---

## `-DryRun` mode (simulation)

Both `Load-MyPowerShellModules` and `Unload-MyPowerShellModules` support `-DryRun` mode.

DryRun mode fully simulates module loading or unloading without modifying the PowerShell session.

**What `-DryRun` does**

- ✅ executes the full dependency resolution logic
- ✅ checks the real module state (`Get-Module`)
- ✅ shows exactly what would be loaded or unloaded
- ❌ does NOT call `Import-Module`
- ❌ does NOT call `Remove-Module`
- ❌ does NOT modify the session state

DryRun returns the same return codes as real execution, making it ideal for:

- testing
- debugging
- dependency validation
- use in automation scripts or CI pipelines

### Example usage

Simulate loading:

```powershell
Load-MyPowerShellModules -DryRun
```

Simulate unloading:

```powershell
Unload-MyPowerShellModules -DryRun
```

Typical output example:

```text
[DRY-RUN] Would load module LocalizationHelperModule
[DRY-RUN] Would load module LevelBasedLogginModule
[DRY-RUN] Would load module MyEnvironmentManagerModule
```

---

## Dependency notes

- Module dependencies must be declared exclusively in the **RequiredModules** field of `.psd1` files
- The system does not rely on predefined orders or manual lists
- All decisions are based on the actual PowerShell session state

This guarantees predictable behavior even in:

- non-clean sessions
- partial reloads
- development environments

---

## Directory Watcher Mechanism of modules

A central function is implemented:

```powershell
Invoke-DirectoryWatcher
```

Responsibilities:

- track the last visited directory
- detect directory changes
- dynamically discover functions following the convention:

```
*:__ModuleDirectoryWatcher
```

- invoke each discovered watcher
- isolate errors originating from individual modules

Each module can independently react to directory changes.

---

### Dynamically Disabling Watchers

Directory watchers can be **temporarily disabled** by setting the environment variable:

```powershell
$env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING = 1
```

On the next `Set-Location` invocation:

- watcher execution is skipped
- the environment variable is automatically removed

This is especially useful for automation scenarios or batch operations.

---

## Set-Location Override

To reliably detect directory changes, the script overrides the:

```powershell
Set-Location
```

function.

The wrapper:

- calls the original `Microsoft.PowerShell.Management\Set-Location`
- gracefully handles invalid paths
- invokes `Invoke-DirectoryWatcher` only when appropriate

This approach is preferred over overriding `prompt`, as `Set-Location` directly represents a directory‑change event.

---

## Architectural Benefits

- No central module registry
- Convention over configuration
- Fully decoupled modular design
- Easily extensible without modifying core logic

---

## Add your module

Is quite easy adding your own module (eg for java features or other). Just add new folder inside PowerShell\modules and create your `*.psm1` (with code) and `*psd1` (with module descriprion and selected esternalized functions).

### Example 
Suppose you want to pool from a source a git repository when you enter a folder containing the local copy of repo. If you want automate this you can create a `mygit` folder in modules and there execute these commands:
```PowerShell
$moduleName = "Resolve-EnvVariableRecursivelyLocalisationHelper"
$basePath  = "$HOME\Lavoro\Useful-Scripts\PowerShell\modules"

New-ModuleManifest `
  -Path "$basePath\$moduleName\$moduleName.psd1" `
  -RootModule "$moduleName.psm1" `
  -ModuleVersion "0.1.0" `
  -Author "Lorenzo Eccher" `
  -CompanyName "cripergine" `
  -Description "Module to implement localisation"
```

In `MyGitModule.psm1` insert:

```PowerShell
function mygit:__ModuleDirectoryWatcher {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      Write-Error "Git not installed or not in your PATH."
      return
  }

  if (-not (Test-Path ".git")) {
      Write-Host "Not in a Git repository, skip git push."
      return
  }

  try {
      git status --porcelain | Out-Null
      git push
      Write-Host "`git push` successfully completed." -ForegroundColor Green
  }
  catch {
      Write-Error "Error executing `git push`: $_"
  }
}
```

And to export the function
```PowerShell
Export-ModuleMember -Function mygit__:ModuleDirectoryWatcher
```

In associated module file `MyGitModule.psd1`
```PowerShell
...
RootModule = 'MyGitModule.psm1'
...
FunctionsToExport = @('mygit:__ModuleDirectoryWatcher')
...
```

---

# Scripts provided
This framework provide some usefull scripts used to semplify few features. The scripts are grouped in some folders by features
- compress: **ZipContentsIn.ps1**: used to easily compress a folder in a zip. It needs just `folderPath` parameter of folder you want to compress.
- curl: **mycurl.ps1**: used to 'curl' an URL specifing method and data if method consent it. Data can be provided as JSON as content of file (if file exists) or text content directly.
- events: **Event-Listener.ps1**: used to monitoring events
- utility: **freeram.ps1** used to forcely free ram, **install.ps1**: used to use winget with default usefull parameters, **winget_repair.ps1**: to repair `winget` if it is broken somehow.

## License

This script is free to use, modify, and redistribute
for both personal and professional purposes.
