# MyLogger Bash Module

## Overview

MyLogger is a lightweight Bash module designed to provide structured, colored, and configurable logging capabilities for complex or modular Bash scripts. The module is intended to be loaded via `source` and integrates seamlessly into larger automation frameworks or operational scripts.

The module is built with robustness and maintainability in mind and supports idempotent loading, ensuring safe reuse across multiple script inclusions.

The module can operate both as part of the My Bash framework and as a standalone component. When framework helper functions are not available, MyLogger automatically provides minimal fallback implementations required for its operation.

Compatible with **Bash 4+**.

---

## Key Features

- Configurable log levels (DEBUG, INFO, WARN, ERROR)
- ANSI-colored output written to `stderr`
- Optional file-based logging
- Automatic detection of the calling function
- Idempotent module loading to prevent redefinition
- **Built-in lazy i18n support (key=value)** resolved at log time
- Calling function identified automatically

---

## Output Streams

MyLogger always writes log messages to `stderr`.

This design allows Bash functions to safely return data through
`stdout` without log messages contaminating command substitutions.

Example:

```bash
version=$(get_current_python_version)
venv=$(get_python_venv)
python_bin=$(get_python_bin python3.12)
```

Even when DEBUG, INFO, WARN or ERROR messages are emitted, the captured variables contain only the intended function output.

Conventions used by this framework:

- stdout : function results and machine-readable output
- stderr : DEBUG, INFO, WARN and ERROR messages

---

## Return codes

| Codice | Significato |
|---------|------------|
| 0 | Success |
| 1 | Log level too low (message not logged) |
| 2 | Module skipped (disabled by flag) |
| 11 | Invalid log level passed |
| 12 | Error resolving current log level |

Generally, codes over 10 are considered blocking errors

## Loading the Module

To load the module, use the standard Bash `source` command:

```bash
source mylogger_module.sh
```

The module is idempotent and will initialize only once, even if sourced multiple times.

To enable debug messages during module loading, set the following environment variable:

```bash
export DEBUG_BASH_MODULES=true
```

When DEBUG_BASH_MODULES is set to true, the logger automatically switches to DEBUG level regardless of the configured MYLOGGER_LOG_LEVEL value.

---

## Supported Log Levels

The following log levels are supported, in increasing order of severity:

- DEBUG
- INFO (default)
- WARN
- ERROR

A log message is emitted only if its level is **equal to or higher** than the currently configured log level.

---

## Configuring the Log Level

To change the global log level:

```bash
set_log_level DEBUG
```

Valid values:

```
DEBUG | INFO | WARN | ERROR
```

Example:

```bash
set_log_level WARN
```

---

## Core Logging Function

```bash
write_log DEBUG "Your message or message_key"
write_log INFO "Operation completed"
write_log ERROR "File not found"
```

Parameters:

- Log level (`ERROR`, `WARN`, `INFO`, `DEBUG`)
- Message text **or message key**

---

## Convenience Functions

For common usage, the module exposes the following helper functions:

### Debug
```bash
debug message_key_or_text
```

### Info
```bash
info message_key_or_text
```

### Warning
```bash
warn message_key_or_text
```

### Error
```bash
error message_key_or_text
```

---

## Built-in Lazy i18n Support

MyLogger includes **native internationalization support** without requiring a separate module.

### How It Works

- Log messages may be passed as **keys** instead of raw text
- Keys are resolved at runtime using a `key=value` messages file
- Message files are **loaded lazily** (only when a log is emitted)
- The logger automatically detects the **calling module directory**
- Missing keys or files are **not errors**
  - They generate a DEBUG diagnostic
  - The original message is logged unchanged

### Module Message Files

Each module may define its own message catalog:

```
my_module/
├── my_module.sh
└── localisation/
    ├── messages.it-IT
    └── messages.en-EN
```

### Message File Format

```ini
venv_enabled=Virtualenv activated: %s
python_not_found=Python version %s not found
```

Placeholders follow standard `printf` (`%s`) rules.

### Usage Example

```bash
info venv_enabled "/path/.venv"
error python_not_found "3.12"
warn "This is a custom raw message"
```

### Language Resolution

Language resolution order:

1. MY_LANG
2. LANG (without locale suffix, e.g. UTF-8)
3. Language-specific catalog (messages.it-IT)
4. Generic language catalog (messages.it)
5. English catalog (messages.en-EN)
6. Generic English catalog (messages.en)

---

## Message Formatting

All log messages include:

- Timestamp (`YYYY-MM-DD HH:MM:SS`)
- Log level
- Calling function name (when available)
- Resolved message text

All output is written to `stderr`.

---

## Colored Output

ANSI color codes are used to visually distinguish log levels:

- DEBUG: Purple
- INFO: Green
- WARN: Yellow
- ERROR: Red

Colors are automatically reset after each message.

---

## File-Based Logging

### Enable Logging to File

```bash
enable_log_to_file
```

Or specify a custom log file path:

```bash
enable_log_to_file "/path/to/logfile.log"
```

Default log file location:

```
$HOME/bash_scripts_log.txt
```

### Disable Logging to File

```bash
disable_log_to_file
```

---

## Utility Function: Prompt

The module also provides a simple input helper. The function returns user input through stdout.

```bash
name=$(read_prompt "Enter your name: ")
echo "Your name is $name"
```

---

## Module Variables

| Variable Name | Description |
|--------------|-------------|
| `MYLOGGER_LOG_LEVEL` | Current log level (default: INFO) |
| `MYLOGGER_LOG_TO_FILE` | Enables/disables file logging |
| `MYLOGGER_LOG_FILE_PATH` | Path to the log file |
| `MYLOGGER_LOADED` | Internal module load guard flag

---

## Complete Example

```bash
#!/bin/bash

source mylogger_module.sh

set_log_level DEBUG
enable_log_to_file "/tmp/app.log"

my_function() {
    debug "starting"
    info "THis is a in info"
    warn "Suboptimal condition detected"
    error "Error found"
}

my_function
```

---

## Requirements

- Bash version 4.0 or later
- ANSI-compatible terminal for colored output

---

## Design Notes

- Missing keys are non-fatal and fall back to raw text
- All log output is written to `stderr`
- The module supports safe multiple inclusions
- No external variables or functions are overridden

---

## License

This module is free to use, modify, and integrate into both personal and professional Bash scripts without restriction.
