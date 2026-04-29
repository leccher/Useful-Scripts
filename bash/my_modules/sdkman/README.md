
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

## Module Loading

If used with **useful-scripts** it is automatically loaded by **.bashrc_custom**.

```bash
source sdkman_module.sh
```

On first load:
- SDKMAN! installation is triggered if not present
- required system packages (`zip`, `unzip`) are checked and installed using `apt` using `sudo`.

---

## Key Features

- Automatic SDKMAN! integration
- Zero-touch SDKMAN! installation
- `.sdkmanrc`-based SDK version switching
- Directory-based activation hook

---

## Automatic Directory Activation

The module exposes the following function:

```bash
sdkman::module_directory_watcher
```

Behavior:
- checks for the presence of a `.sdkmanrc` file in the current directory
- executes `sdk env` to apply the correct SDK environment

This function is intended to be invoked automatically when changing directories.

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
- `curl`
- `zip` and `unzip` (automatically installed if missing)
- `sudo` privileges to install system dependencies

---

## Design Notes

- Fully autonomous module requiring no manual configuration
- SDKMAN! installation follows official guidelines
- No persistent system modifications beyond SDKMAN! installation
- Directory watcher activates only when `.sdkmanrc` is present

---

## License

Free to use, modify, and redistribute for both personal and professional purposes without restrictions.
