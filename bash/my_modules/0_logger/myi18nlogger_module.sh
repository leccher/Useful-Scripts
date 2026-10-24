#!/bin/bash
## --- Logger Module Help with i18n capabilities (BASH) ---
## If thes folder where your script is working contains a subfolder named "localisation" with message files (e.g., messages.en-EN, messages.it-IT), the logger will automatically resolve message keys to the corresponding messages in the current language.
## Set MY_LANG environment variable to choose the language (default: en-EN).
## - set_log_level [LEVEL] : Set the minimum log level (DEBUG, INFO, WARN, ERROR).
## - enable_log_to_file [FILE_PATH] : Enable logging to a file (optional path).
## - disable_log_to_file : Disable logging to a file.
## - debug/info/warn/error [MESSAGE] : Log a message at the specified level.
## - read_prompt [PROMPT] : Display a prompt and read user input (returns the input)
##
## Return values:
## - 0 : Success
## - 1 : Log level too low (message not logged)
## - 2 : Module skipped (disabled by flag)
## - 11 : Invalid log level passed to write_log or set_log_level
## - 12 : Error resolving current log level
## - >10 : Other errors 

# Standalone compatibility: provide framework helpers if missing
: "${C_RESET:=\e[0m}"
: "${C_CYAN:=\e[36m}"
: "${C_GREEN:=\e[32m}"
: "${C_YELLOW:=\e[33m}"
: "${C_RED:=\e[31m}"
if ! declare -F is_debug >/dev/null; then
    is_debug () {
        [[ "$DEBUG_BASH_MODULES" == true ]]
    }
fi
# Debugging and logging internal functions
if ! declare -F debug >/dev/null; then
    debug() {
        is_debug && echo -e "${C_CYAN}[M_DEBUG]${C_RESET} $*" >&2
    }
fi
if ! declare -F info >/dev/null; then
    info() {
        echo -e "${C_GREEN}[M_INFO ] ${C_RESET} $*" >&2
    }
fi
if ! declare -F error >/dev/null; then
    error() {
        echo -e "${C_RED}[M_ERROR] ${C_RESET} $*" >&2
    }
fi
if ! declare -F warn >/dev/null; then
    warn() {
        echo -e "${C_YELLOW}[M_WARN ] ${C_RESET} $*" >&2
    }
fi

# change to true if you don't want this module is used:
if false; then
    debug ">>> mylogger module skipped (disabled by flag)"
    # Return code for skipped by flag
    return 2
fi


debug ">>> ENTER mylogger module"
if [[ -n "${MYLOGGER_LOADED:-}" ]]; then
    debug ">>> mylogger module already loaded"
    return 0
fi
MYLOGGER_LOADED=1
readonly MYLOGGER_MODULE_FILE="${BASH_SOURCE[0]}"
MYLOGGER_LOG_LEVEL="INFO"
MYLOGGER_LOG_TO_FILE=false
MYLOGGER_LOG_FILE_PATH="$HOME/bash_scripts_log.txt"
if is_debug; then
    MYLOGGER_LOG_LEVEL="DEBUG"
fi

# i18n features
__i18n_find_caller_file() {
    local i

    for ((i=1; i<${#FUNCNAME[@]}; i++)); do
        case "${FUNCNAME[$i]}" in
            resolve_i18n|write_log|debug|info|warn|error|read_prompt)
                continue
                ;;
            *)
                printf '%s\n' "${BASH_SOURCE[$i]}"
                return
                ;;
        esac
    done
}

__i18n_debug() {
    is_debug && echo -e "${C_CYAN}[i18n DEBUG]${C_RESET} $*" >&2
}

resolve_i18n() {
    local lang="${MY_LANG:-${LANG%%.*}}"
    lang="${lang//_/-}"
    [[ -n "$lang" ]] || lang="en-EN"
    local short_lang="${lang%%-*}"
        
    local key="$1"
    shift

    # File chiamante reale
    local caller_file="$(__i18n_find_caller_file)"

    # Se non riesco a risalire al chiamante → messaggio raw
    if [[ -z "$caller_file" ]]; then
        __i18n_debug "Unable to find an external caller for 'resolve_i18n', using raw message"
        printf -- "%s" "$key"
        return 1
    fi

    local module_dir
    module_dir="$(cd "$(dirname "$caller_file")" && pwd)"

    local msg_file="$module_dir/localisation/messages.$lang"
    [[ -f "$msg_file" ]] || msg_file="$module_dir/localisation/messages.$short_lang"
    [[ -f "$msg_file" ]] || msg_file="$module_dir/localisation/messages.en-EN"
    [[ -f "$msg_file" ]] || msg_file="$module_dir/localisation/messages.en"

    # Se non esiste alcun file messaggi → debug + raw
    if [[ ! -f "$msg_file" ]]; then
        __i18n_debug "no messages file for module '$(basename "$module_dir")', using raw message"
        printf -- "%s" "$key"
        return 1
    fi

    local value
    value="$(awk -F= -v k="$key" '$1==k {print substr($0,index($0,$2)); exit}' "$msg_file")"

    # ✅ CHIAVE NON TROVATA → comportamento richiesto
    if [[ -z "$value" ]]; then
        __i18n_debug "key '$key' not found in $(basename "$msg_file"), using raw message"
        printf -- "%s" "$key"
        return 1
    fi

    # ✅ CHIAVE TROVATA → printf-style (%s)
    printf -- "$value" "$@"
}

# log functions
__log_caller() {
    local i
    for ((i=1; i<${#FUNCNAME[@]}; i++)); do
        case "${FUNCNAME[$i]}" in
            resolve_i18n|write_log|debug|info|warn|error|read_prompt)
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

log_level_value() {
    case "$1" in
        #DEBUG) echo 0 ;;
        #INFO)  echo 1 ;;
        #WARN)  echo 2 ;;
        #ERROR) echo 3 ;;
        DEBUG) printf '0\n' ;;
        INFO)  printf '1\n' ;;
        WARN)  printf '2\n' ;;
        ERROR) printf '3\n' ;;
        *) return 1 ;;
    esac
}
set_log_level() {
    local level="${1^^}"

    if log_level_value "$level" &>/dev/null; then
        MYLOGGER_LOG_LEVEL="$level"
    else
        echo "Invalid level. Possible: DEBUG, INFO, WARN, ERROR"
        return 11
    fi
}

enable_log_to_file() {
    local file="$1"
    [[ -n "$file" ]] && MYLOGGER_LOG_FILE_PATH="$file"
    MYLOGGER_LOG_TO_FILE=true
}

disable_log_to_file() {
    MYLOGGER_LOG_TO_FILE=false
}

CLR_DEBUG=${C_CYAN} ##"\e[35m"
CLR_INFO=${C_GREEN} ##"\e[32m"
CLR_WARN=${C_YELLOW} ##"\e[33m"
CLR_ERROR=${C_RED} ##"\e[31m"
CLR_RESET=${C_RESET} ##"\e[0m"

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
    lvl=$(log_level_value "$level") || return 11
    cur=$(log_level_value "$MYLOGGER_LOG_LEVEL") || return 12

    (( lvl < cur )) && return 1

    local timestamp formatted color
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    local resolved rc
    resolved="$(resolve_i18n "$message" "$@")"
    rc=$?
    if (( rc != 0 )); then
        __i18n_debug "message key '$message' not found, using raw message"
        printf -v resolved "$message" "$@"
    fi

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

read_prompt() {
    local message="$1"
    shift
    local resolved rc
    __i18n_debug "Prompt message before resolution: $message"
    resolved="$(resolve_i18n "$message" "$@")"
    rc=$?
    if (( rc != 0 )); then
        __i18n_debug "message key '$message' not found, using raw message"
        printf -v resolved "$message" "$@"
    fi
    __i18n_debug "Prompt message after resolution: $resolved"
    local response
    read -r -p "$resolved" response
    rc=$?

    if (( rc != 0 )); then
        __i18n_debug "EOF received from user"
    else
        __i18n_debug "User input: $response"
    fi
    printf '%s\n' "$response"
}

# Redefine functions using write_log for logging
debug() { write_log DEBUG "$@"; }
info()  { write_log INFO "$@"; }
warn()  { write_log WARN "$@"; }
error() { write_log ERROR "$@"; }

show_logger_help() {
    grep '^## - ' "$MYLOGGER_MODULE_FILE" | sed 's/^## - //'
}

debug "Loaded: Write-Log module for Bash (v4+). Use 'show_logger_help' for usage instructions."
debug "<<< EXIT mylogger module"
# Functions are available once you 'source' the script.