#!/bin/bash
## --- Logger Module Help (BASH) ---
## - set_log_level [LEVEL] : Set the minimum log level (DEBUG, INFO, WARN, ERROR).
## - enable_log_to_file [FILE_PATH] : Enable logging to a file (optional path).
## - disable_log_to_file : Disable logging to a file.
## - debug/info/warn/error [MESSAGE] : Log a message at the specified level.
## - read_prompt [PROMPT] : Display a prompt and read user input (returns the input)
# change to true if you don't want this module is used:
if [ false ]; then
    if [[ -n "${MYLOGGER_LOADED:-}" ]]; then
        debug ">>> mylogger module skipped (disabled by flag)"
    fi
    return
fi
[[ "$DEBUG_BASH_MODULES" == true ]] && echo ">>> ENTER mylogger module"

if [[ -n "${MYLOGGER_LOADED:-}" ]]; then
    [[ "$DEBUG_BASH_MODULES" == true ]] && echo ">>> mylogger module skipped (already loaded)"
    return
fi
export MYLOGGER_LOADED=1

MYLOGGER_LOG_LEVEL="INFO"
MYLOGGER_LOG_TO_FILE=false
MYLOGGER_LOG_FILE_PATH="$HOME/bash_scripts_log.txt"

log_level_value() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        *) return 1 ;;
    esac
}

CLR_DEBUG="\e[35m"
CLR_INFO="\e[32m"
CLR_WARN="\e[33m"
CLR_ERROR="\e[31m"
CLR_RESET="\e[0m"




write_log() {
    local level="$1"
    shift;
    local message="$1"
    shift;
    
    local caller
    caller="$(__log_caller)"

    if [[ "$caller" == "main" || -z "$caller" ]]; then
        caller=""
    else
        [[ -n "$caller" ]] && caller="[$caller]"
    fi

    local lvl cur
    lvl=$(log_level_value "$level") || return
    cur=$(log_level_value "$MYLOGGER_LOG_LEVEL") || return

    (( lvl < cur )) && return

    local timestamp formatted color
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    local resolved
    resolved="$(__log_resolve_message "$message" $@)"

    formatted="[$timestamp][$level]$caller $resolved"

    # formatted="[$timestamp][$level]$caller $message"

    case "$level" in
        DEBUG) color=$CLR_DEBUG ;;
        INFO)  color=$CLR_INFO ;;
        WARN)  color=$CLR_WARN ;;
        ERROR) color=$CLR_ERROR ;;
        *) color=$CLR_RESET ;;
    esac

    echo -e "${color}${formatted}${CLR_RESET}" >&2

    if [[ "$MYLOGGER_LOG_TO_FILE" == true ]]; then
        echo "$formatted" >>"$MYLOGGER_LOG_FILE_PATH"
    fi
}

read_log() {
    local message="$1"
    shift;
    local resolved
    if [[ "$DEBUG_BASH_MODULES" == true ]]; then
        debug "Prompt message before resolution: $message"
    fi
    resolved="$(__log_resolve_message "$message" $@)"
    if [[ "$DEBUG_BASH_MODULES" == true ]]; then
        debug "Prompt message after resolution: $resolved"
    fi
    read -p "$resolved" response
    if [[ "$DEBUG_BASH_MODULES" == true ]]; then
        debug "User input: $response"
    fi
}


__log_caller() {
    local i
    for ((i=1; i<${#FUNCNAME[@]}; i++)); do
        case "${FUNCNAME[$i]}" in
            debug|info|warn|error|write_log)
                continue
                ;;
            *)
                echo "${FUNCNAME[$i]}"
                return
                ;;
        esac
    done
    echo ""
}


set_log_level() {
    local level="${1^^}"

    if log_level_value "$level" >/dev/null; then
        export MYLOGGER_LOG_LEVEL="$level"
    else
        echo "Invalid level. Possible: DEBUG, INFO, WARN, ERROR"
        return 1
    fi
}

enable_log_to_file() {
    local file="$1"
    [[ -n "$file" ]] && export MYLOGGER_LOG_FILE_PATH="$file"
    export MYLOGGER_LOG_TO_FILE=true
}

disable_log_to_file() {
    export MYLOGGER_LOG_TO_FILE=false
}

debug() { write_log DEBUG "$@"; }
info()  { write_log INFO "$@"; }
warn()  { write_log WARN "$@"; }
error() { write_log ERROR "$@"; }
read_prompt() { return read_log "$@"; }

show_logger_help() {
    grep '^## - ' "${BASH_SOURCE[0]}" | sed 's/^## - //'
}

[[ "$DEBUG_BASH_MODULES" == true ]] && echo -e "\e[32m Loaded: Write-Log module for Bash (v4+). Use 'show_log_help' for usage instructions.\e[0m"
[[ "$DEBUG_BASH_MODULES" == true ]] && echo "<<< EXIT mylogger module"
# Functions are available once you 'source' the script.