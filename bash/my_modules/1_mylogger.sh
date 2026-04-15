#!/bin/bash
[[ "$DEBUG_BASH_MODULES" == true ]] && echo ">>> ENTER 1_mylogger.sh"

if [[ -n "${MYLOGGER_LOADED:-}" ]]; then
    [[ "$DEBUG_BASH_MODULES" == true ]] && echo ">>> 1_mylogger.sh skipped (already loaded)"
    return
fi
export MYLOGGER_LOADED=1

LOG_LEVEL="INFO"
LOG_TO_FILE=false
LOG_FILE_PATH="$HOME/bash_scripts_log.txt"

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
    local message="$1"
    local level="${2:-INFO}"
    
    local caller
    caller="$(__log_caller)"

    if [[ "$caller" == "main" || -z "$caller" ]]; then
        caller=""
    else
        [[ -n "$caller" ]] && caller="[$caller]"
    fi

    local lvl cur
    lvl=$(log_level_value "$level") || return
    cur=$(log_level_value "$LOG_LEVEL") || return

    (( lvl < cur )) && return

    local timestamp formatted color
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    formatted="[$timestamp][$level]$caller $message"

    case "$level" in
        DEBUG) color=$CLR_DEBUG ;;
        INFO)  color=$CLR_INFO ;;
        WARN)  color=$CLR_WARN ;;
        ERROR) color=$CLR_ERROR ;;
        *) color=$CLR_RESET ;;
    esac

    echo -e "${color}${formatted}${CLR_RESET}" >&2

    if [[ "$LOG_TO_FILE" == true ]]; then
        echo "$formatted" >>"$LOG_FILE_PATH"
    fi
}

prompt(){
    local prompt_message="$1"
    read -p "$prompt_message" response
    echo "$response"
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
        export LOG_LEVEL="$level"
    else
        echo "Invalid level. Possible: DEBUG, INFO, WARN, ERROR"
        return 1
    fi
}

enable_log_to_file() {
    local file="$1"
    [[ -n "$file" ]] && LOG_FILE_PATH="$file"
    LOG_TO_FILE=true
}

disable_log_to_file() {
    LOG_TO_FILE=false
}

debug() { write_log "$*" DEBUG; }
info()  { write_log "$*" INFO; }
warn()  { write_log "$*" WARN; }
error() { write_log "$*" ERROR; }


[[ "$DEBUG_BASH_MODULES" == true ]] && echo -e "\e[32m Loaded: Write-Log module for Bash (v4+). Use 'show_log_help' for usage instructions.\e[0m"
[[ "$DEBUG_BASH_MODULES" == true ]] && echo "<<< EXIT 1_mylogger.sh"
# Functions are available once you 'source' the script.