
# MyPythonEnvironment Module

## Overview

**MyPythonEnvironment Module** is an enterprise-grade Bash module designed to streamline Python environment management. It provides robust utilities for:

- switching Python versions
- creating and activating virtual environments
- automatic activation of virtual environments based on the current directory

The module is designed for dynamic loading via `source` and seamless integration into modular Bash ecosystems.

Compatible with **Bash 4+**.

---

## Output Streams

This module follows the same stdout/stderr separation model used by the MyLogger module.

Functions that return values write their results to `stdout`, while log messages are written to `stderr`.

Examples:

```bash
version=$(get_python_version)
venv=$(get_python_venv)
python_bin=$(get_python_bin python3.12)
```

This allows command substitutions to work correctly without log messages contaminating captured output.

Conventions used by this module:

- stdout: function results and machine-readable output
- stderr: DEBUG, INFO, WARN and ERROR messages

---

## Return Codes 
| Code | Description | |--------|------------| 
| `0` | Success | 
| `1` | Generic non-fatal failure (for example, user cancelled an operation) |
| `2` | Module skipped (disabled by configuration) | 
| `3` | Module already loaded |
| `4` | No virtual environment found | 
| `11` | Requested Python version not found | 
| `12` | Unable to determine current Python version | 
| `13` | No compatible Python executable found | 
| `14` | Virtual environment activation script not found | 
| `15` | Bash version lower than 4.0 | 
| `99` | Invalid function argument |

Codes over 10 are cosidered blocking errors

---

## Module Loading

```bash
source mypythonenvironment_module.sh
```

The module is **idempotent** and will initialize only once, even if sourced multiple times.

Enable debug messages during module loading:

```bash
export DEBUG_BASH_MODULES=true
```

---

## Key Features

- Switch between installed Python versions
- Create Python virtual environments (`venv`)
- Activate and deactivate virtual environments
- Automatic virtual environment detection
- Optional automatic activation through directory watchers
- Integrated localization support through the `MyLogger` module
- Interactive virtual environment selection
- Compatible with modular Bash frameworks

---

## Python Version Management

### Switch active Python version

```bash
set_python_version 3.10
```

The module dynamically resolves the requested Python executable and updates the `PATH` environment variable.

---

## Virtual Environment Management

### Create a virtual environment

```bash
create_python_venv 3.10 myproject
```

Result:
```
.venv_3.10_myproject/
```

### Activate a virtual environment

```bash
enable_venv
```

An interactive menu is displayed when multiple environments are detected.

### Deactivate the active virtual environment

```bash
disable_python_venv
```

---

## Automatic Activation

The module exposes a directory watcher hook:

```bash
mypem::module_directory_watcher
```

This hook can be called automatically from `.bashrc`, PROMPT_COMMAND, or custom directory-change handlers.

Behaviour:

- If a matching virtual environment is found, it is automatically activated.
- If multiple virtual environments are found, the user can choose which one to activate.
- If no virtual environment is found, the directory is ignored.
- The watcher never creates new virtual environments automatically.

---

## Environment Variables

| Variable | Description |
|----------|------------|
| `PYTHON_HOME` | Active Python installation path |
| `VIRTUAL_ENV` | Active virtual environment |
| `MYPYTHON_LOADED` | Module load guard flag |

---

## Requirements

- Bash 4.0 or later
- Python 3 installed on the system
- MyLogger module recommended for full logging and localization support

---

## Design Notes

- No mandatory external dependencies
- Resilient logging with automatic fallback
- Compatible with interactive shells and VSCode terminals
- No permanent system modifications

---

## License

Free to use, modify, and redistribute for both personal and professional use without restrictions.
