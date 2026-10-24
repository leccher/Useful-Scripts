# SDKMAN Bash Module

## Overview

This module provides seamless **SDKMAN!** integration for modular Bash environments.

It automatically:
- detects whether SDKMAN! is installed
- installs SDKMAN! if missing
- verifies and installs required system dependencies (`zip`, `unzip`)
- enables automatic SDK version switching via `.sdkmanrc`
- exposes a directory watcher hook compatible with modular Bash systems

The module is designed to be loaded via `source` and integrated into `.bashrc` or custom shell frameworks.

Compatible with **Bash 4+**.

---

## What is SDKMAN!?

SDKMAN! is a command-line tool for managing multiple versions of software development kits (SDKs) on Unix-based systems.

It is commonly used to install and switch between different versions of:

- Java
- Maven
- Gradle
- Kotlin
- Groovy
- Spring Boot
- Scala
- and many other JVM-related tools

Without SDKMAN!, changing versions often requires manually modifying environment variables such as `PATH` and `JAVA_HOME`.

SDKMAN! simplifies this process and allows projects to declare their required tool versions through a `.sdkmanrc` file.

---

### Why This Module Is Useful

When working on multiple projects, different SDK versions are often required.

Example:

Project A:

```text
Java 17
Maven 3.9
```

Project B:

```Plain text
Java 21
Maven 4.0
```

Using SDKMAN! alone, you must remember to manually execute:

```Shell
sdk env
```

every time you enter a project directory.

This module automates that process.

When a directory contains a .sdkmanrc file, the module automatically applies the correct SDK versions through the directory watcher hook:

```Shell
sdkman::module_directory_watcher
```

This makes switching between projects seamless and reduces environment configuration mistakes.

---

### Example .sdkmanrc 

```text 
java=21.0.8-tem 
maven=3.9.11 
gradle=9.1.0
```

When entering a directory containing this file, the module automatically invokes:

```Shell
sdk env
```

and activates the specified SDK versions.

---

## Output Streams

This module follows the same stdout/stderr separation model used by the other framework modules.

Conventions:

- stdout: function results and command output
- stderr: DEBUG, INFO, WARN and ERROR messages

This allows the module to integrate safely with command substitutions and shell automation.

---

## Return Codes

| Code | Description |
|--------|------------|
| `0` | Success |
| `1` | Generic non-fatal failure |
| `2` | Module skipped |
| `3` | Module already loaded |
| '15' | Bash version less then 4.0 |

---

## Module Loading

If used with **useful-scripts** it is automatically loaded by **.bashrc_custom**.

```bash
source sdkman_module.sh
```

On first load:

- SDKMAN! installation is proposed if not present
- required system packages (`zip`, `unzip`) are checked
- missing dependencies can be installed after user confirmation

---

## Key Features

- Automatic SDKMAN! integration
- Interactive SDKMAN! installation
- Automatic dependency verification (`zip`, `unzip`)
- Built-in i18n support
- `.sdkmanrc`-based SDK version switching
- Directory-based activation hook
- Compatible with modular Bash frameworks

---

## Automatic Directory Activation

The module exposes the following function:

```bash
sdkman::module_directory_watcher
```

Behavior:
- checks for the presence of a `.sdkmanrc` file in the current directory
- executes `sdk env` to apply the correct SDK environment

This function is intended to be invoked automatically when changing directories. The watcher keeps track of the last processed directory to avoid unnecessary repeated SDK environment activation.

---

## Example Integration with .bashrc

```bash
# after loading the module
sdkman::module_directory_watcher
```

When entering a directory containing `.sdkmanrc`, SDKMAN! will automatically apply the required SDK version.

---

## Requirements

- Bash 4.0 or later
- SDKMAN! (automatically detected and optionally installed)
- `curl`
- `zip` and `unzip` (automatically installed if missing)
- `sudo` privileges to install system dependencies

---

## Design Notes

- Minimal user interaction only when SDKMAN! or required dependencies are missing
- SDKMAN! installation follows official guidelines
- Use fallback functions for logging and i18n when needed
- Riskless of using bad version of SDK in different projects
- Directory watcher activates only when `.sdkmanrc` is present

---

## License

Free to use, modify, and redistribute for both personal and professional purposes without restrictions.

---