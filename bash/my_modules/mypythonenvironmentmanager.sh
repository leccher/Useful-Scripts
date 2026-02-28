#!/bin/bash

# ==============================================================================
# Python Environment Manager (Bash Porting)
# ==============================================================================
$LOGGER_PATH="./mylogger.sh"
# Check bash version
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo "Warning: This script require Bash 4.0 or higher."
fi

# Using defined logger, if not found i will use a fallback function
# Altrimenti definisco una funzione di fallback
if ! command -v write_log &> /dev/null; then
    if [[ -f "$LOGGER_PATH" ]]; then
        source "$LOGGER_PATH"
        write_log "Logger module loaded successfully." "INFO"
    else
        write_log() { echo "[$2] $1"; }
        write_log "Logger module NOT found: $LOGGER_PATH" "WARN"
    fi
fi

# --- FUNZIONI INTERNE / PRIVATE ---

fix_path() {
    # In Linux PATH uses ':' as variable separator. 
    # Resolvig duplicates keepiing the order
    export PATH=$(echo -n "$PATH" | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}')
}

get_current_python_version() {
    local raw_version
    if ! raw_version=$(python3 --version 2>&1); then
        return 1
    fi

    if [[ $raw_version =~ ([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

# --- FUNZIONI CORE ---

set_python_version() {
    local version=$1
    local current_v=$(get_current_python_version)

    if [[ "$version" == "$current_v" ]]; then
        write_log "Version $version already setted." "INFO"
        return 0
    fi

    # Simuliamo PYTHON_HOME_* cercando eseguibili nel sistema
    local target_bin="python$version"
    
    if command -v "$target_bin" &> /dev/null; then
        local target_path=$(command -v "$target_bin")
        export PYTHON_HOME=$(dirname "$target_path")
        # Adding to PATH if not inside
        export PATH="$PYTHON_HOME:$PATH"
        fix_path
        write_log "Switch to $target_bin executerd." "INFO"
        return 0
    else
        write_log "Version $version not found." "ERROR"
        return 1
    fi
}

create_python_venv() {
    local version=$1
    local name=$2

    if [[ -z "$version" ]]; then
        version=$(get_current_python_version)
    fi

    if [[ -z "$name" ]]; then
        read -p "Name/Suffix for venv (Enter as default): " name
    fi

    local venv_name
    if [[ -n "$name" ]]; then
        venv_name=".venv_${version}_${name}"
    else
        venv_name=".venv_${version}"
    fi

    if [[ ! -d "$venv_name" ]]; then
        write_log "Creating venv: $venv_name..." "INFO"
        "python$version" -m venv "$venv_name"
    fi
    echo "$venv_name"
}

get_python_venv() {
    # Check for VSCode. Even if it is not standard in bash, we can test env variables
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        echo "vscode"
        return 2
    fi

    local folders=($(ls -d .venv* 2>/dev/null))
    
    if [[ ${#folders[@]} -eq 0 ]]; then
        write_log "No venv found." "WARN"
        return 1
    fi

    echo -e "\nChoose the virtual environment:"
    for i in "${!folders[@]}"; do
        echo "$((i+1)). ${folders[$i]}"
    done

    read -p "Number (0 for exit, default 1): " sel
    [[ -z "$sel" ]] && sel=1
    [[ "$sel" == "0" ]] && return 1

    local idx=$((sel-1))
    if [[ $idx -ge 0 && $idx -lt ${#folders[@]} ]]; then
        echo "${folders[$idx]}"
        return 0
    fi
    return 1
}

enable_python_venv() {
    local folder=$1
    
    if [[ -z "$folder" ]]; then
        local res=$(get_python_venv)
        # If get_python_venv fails, whe create a new one
        if [[ $? -ne 0 ]]; then
            folder=$(create_python_venv)
        else
            folder=$res
        fi
    fi

    # In Linux: bin/activate
    local activate_script="$folder/bin/activate"
    if [[ -f "$activate_script" ]]; then
        source "$activate_script"
        write_log "Enabled $folder" "INFO"
        return 0
    fi
    write_log "Acivate script no found." "ERROR"
    return 1
}

start_jupyter_lab() {
    local folder=$1
    local bin="$folder/bin/jupyter-lab"
    
    if [[ -f "$bin" ]]; then
        read -p "Starting Jupyter Lab? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            "$bin"
        fi
    fi
}

# --- WRAPPERS PUBBLICI ---

enable_venv() {
    enable_python_venv "$1"
}

enable_venv_and_jupyter() {
    local venv=$(get_python_venv)
    if [[ -n "$venv" ]]; then
        enable_python_venv "$venv"
        start_jupyter_lab "$venv"
    fi
}

show_pem_help() {
    echo -e "\n--- Python Manager Module Help (BASH) ---"
    echo "enable_venv          : Sceglie/crea un venv e lo attiva."
    echo "enable_venv_and_jupyter : Attiva venv e avvia Jupyter."
    echo "set_python_version [v]   : Cambia la versione di Python attiva."
}