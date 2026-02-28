#!/bin/bash

# ==============================================================================
# Module: Logger.sh (Bash 4.0+)
# Description: Porting of Write-Log PowerShell module for Linux/macOS.
# ==============================================================================

# Global configuration variables
export LOG_LEVEL="INFO"
export LOG_TO_FILE=false
export LOG_FILE_PATH="$HOME/bash_scripts_log.txt"

# Level maps using Associative Array (Bash 4+)
declare -A LOG_LEVEL_MAP
LOG_LEVEL_MAP=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
)

# ANSI Color Codes for Terminal Output
CLR_DEBUG="\e[35m"  # Magenta
CLR_INFO="\e[32m"   # Green
CLR_WARN="\e[33m"   # Yellow
CLR_ERROR="\e[31m"  # Red
CLR_RESET="\e[0m"   # Reset

write_log() {
    local message="$1"
    local level="${2:-INFO}" # Default to INFO if not provided
    local caller="${FUNCNAME[1]}"

    if [[ "$caller" == "main" ]]; then
        $caller = ""
    else
        $caller = "[$caller]"
    fi
    
    # Check if level exists in map
    if [[ -z "${LOG_LEVEL_MAP[$level]}" ]]; then
        level="INFO"
    fi

    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local formatted="[$timestamp][$level]$caller $message"

    # Priority logic: Compare current level value with global level value
    if [[ ${LOG_LEVEL_MAP[$level]} -ge ${LOG_LEVEL_MAP[$LOG_LEVEL]} ]]; then
        
        # Determine color
        local color=$CLR_RESET
        case "$level" in
            "DEBUG") color=$CLR_DEBUG ;;
            "INFO")  color=$CLR_INFO ;;
            "WARN")  color=$CLR_WARN ;;
            "ERROR") color=$CLR_ERROR ;;
        esac
        # Print to console (stderr is better for logs)
        echo -e "${color}${formatted}${CLR_RESET}" >&2
        # Log to file if enabled
        if [ "$LOG_TO_FILE" = true ]; then
            echo "$formatted" >> "$LOG_FILE_PATH"
        fi
    fi
}

enable_log_to_file() {
    local file="$1"
    if [[ -n "$file" ]]; then
        set_log_file_path "$file"
    fi
    if [[ -z "$LOG_FILE_PATH" ]]; then
        echo -e "\e[33mWarning: Log file path needed. Usage: enable_log_to_file 'path/to/file'\e[0m"
        return
    fi
    export LOG_TO_FILE=true
    echo "Logging to file enabled: $LOG_FILE_PATH"
}

disable_log_to_file() {
    export LOG_TO_FILE=false
}

set_log_file_path() {
    export LOG_FILE_PATH="$1"
}

set_log_level() {
    local level="${1^^}" # Convert to uppercase
    if [[ -n "${LOG_LEVEL_MAP[$level]}" ]]; then
        export LOG_LEVEL="$level"
    else
        echo "Invalid level. Possible: DEBUG, INFO, WARN, ERROR"
    fi
}

show_log_help() {
    echo -e "${CLR_INFO}Write-Log for Bash (v4+)${CLR_RESET}"
    echo "This script implements a level-based logging system."
    echo -e "Levels: DEBUG, INFO, WARN, ERROR"
    echo ""
    echo "Usage:"
    echo "  set_log_level 'DEBUG'"
    echo "  write_log 'My message' 'WARN'"
    echo ""
    echo "File Logging:"
    echo "  enable_log_to_file '/tmp/mylog.txt'"
    echo "  disable_log_to_file"
}

# In Bash, 'Export-ModuleMember' doesn't exist. 
# Functions are available once you 'source' the script.