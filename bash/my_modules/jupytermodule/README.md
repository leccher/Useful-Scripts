
# MyPythonEnvironment Module

## Overview

**MyPythonEnvironment Module** is an enterprise-grade Bash module designed to streamline Python environment management. It provides robust utilities for:

- switching Python versions
- creating and activating virtual environments
- automatic activation of virtual environments based on the current directory
- optional integration with Jupyter Lab

The module is designed for dynamic loading via `source` and seamless integration into modular Bash ecosystems.

Compatible with **Bash 4+**.

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
- Automatically activate venvs when entering directories
- Optional Jupyter Lab integration
- Integrated logging via `mylogger` module

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

This function can be called automatically from `.bashrc` or directory-change handlers.

---

## Jupyter Lab Integration

```bash
enable_venv_and_jupyter
```

Or:

```bash
enable_venv_if_present
```

Starts Jupyter Lab if available in the active virtual environment.

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
- Optional `mylogger` module

---

## Design Notes

- No mandatory external dependencies
- Resilient logging with automatic fallback
- Compatible with interactive shells and VSCode terminals
- No permanent system modifications

---

## License

Free to use, modify, and redistribute for both personal and professional use without restrictions.
