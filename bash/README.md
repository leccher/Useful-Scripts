
# .bashrc_custom – Custom Bash Configuration

## Overview

The `.bashrc_custom` file acts as a modular extension to the standard `~/.bashrc`, allowing advanced Bash configuration and optional plugins without directly altering the primary configuration file.

---

## Key Features

- Automatic integration with custom modules
- Automatic execution of specific scripts for each module on directory change (loading virtual environments, running special features etc.)
- Designed for modular Bash environments

---

## Integration with .bashrc

The inclusion of sourcing of `.bashrc_custom` into `~/.bashrc` is handled by the helper script:

```bash
add_mybashrc_custom.sh
```

This script:
- safely appends `source /real/path/to/.bashrc_custom` to `~/.bashrc`
- avoids duplicate entries
- provides user-friendly status output

---

## Modularity

If any module is not needed, just switch to `true` first check or delete module folder from structure.

```bash
# change to true if you don't want this module is used:
if [ false ]; then
...
```

---

## Basic log features
Some basilar logging features are provided, if no advanced logger module is loaded.

They does not allow filtering output by a selected base log level.

```bash
# Using defined logger, if not found i will use a fallback function
if ! command -v write_log &> /dev/null; then
    write_log() { echo "[$2] $1" >&2; }
    debug() { write_log "$*" DEBUG; }
    info()  { write_log "$*" INFO; }
    warn()  { write_log "$*" WARN; }
    error() { write_log "$*" ERROR; }
fi
```

---

## Requirements

- Bash 4.0 or later
- `curl`
- `sudo` privileges to install evntual system dependencies

---

## Design Notes

- `.bashrc_custom` is intentionally separated from the main `.bashrc` for maintainability
- The script is idempotent and safe to reload
- Automation is activated only when needed files or folders by modules exist.

---

## License

Free to use, modify, and redistribute for both personal and professional use without restrictions.
