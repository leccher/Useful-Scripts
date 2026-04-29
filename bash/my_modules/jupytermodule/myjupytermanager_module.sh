#!/bin/bash
## --- Python Manager Module Help (BASH) ---
## - start_jupyter_lab  : Start jupyter lab if present in the current venv when the directory changes.
## - install_jupyter_lab   : Install Jupyter Lab in the current venv.
## - show_mjm_help : Show this help message.
# change to true if you don't want this module is used:
if [ false ]; then
    if [[ -n "${MYLOGGER_LOADED:-}" ]]; then
        debug ">>> myjupytermanager module skipped (disabled by flag)"
    fi
    return
fi
[[ "$DEBUG_BASH_MODULES" == true ]] && echo ">>> ENTER myjupytermanager module"

if [[ -n "${MYJUPYTERMAN_LOADED:-}" ]]; then
    [[ "$DEBUG_BASH_MODULES" == true ]] && echo ">>> myjupytermanager module skipped (already loaded)"
    return
fi
export MYJUPYTERMAN_LOADED=1
# ==============================================================================
# Python Environment Manager (Bash Porting)
# ==============================================================================
# Check bash version
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo "Warning: This script require Bash 4.0 or higher."
    return;
fi

# --- FUNZIONI INTERNE / PRIVATE ---
fix_path() {
    # In Linux PATH uses ':' as variable separator. 
    # Resolvig duplicates keepiing the order
    export PATH=$(echo -n "$PATH" | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}')
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

install_jupyter_lab() {
    # check if we are in a venv, if not return error
    if [[ -z "$VIRTUAL_ENV" ]]; then
        error "No active virtual environment. Please activate a virtual environment before installing Jupyter Lab."
        return 1
    fi
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local bin="$VIRTUAL_ENV/bin/jupyter-lab"
        if [[ -f "$bin" ]]; then
            info "Jupyter Lab is already installed in the current virtual environment."
            return 0
        else
            if ! pip install jupyterlab; then
                error "Failed to install Jupyter Lab. Please check your pip configuration and try again."
                return 2
            fi
            info "Jupyter Lab installed successfully in the current virtual environment."
            return 0
        fi
    else
        error "No active virtual environment. Please activate a virtual environment before installing Jupyter Lab."
        return 1
    fi
}

# --- WRAPPERS PUBBLICI ---

# This method is called by .bashrc_custom when the directory changes, if the module is loaded
# Module identifiler + :: + module_diretory_watcher
myjm::module_directory_watcher(){
    # if we are in a venv, VIRTUAL_ENV is setted, so we can check if jupyter lab is present in the venv and ask to start it
    if [[ -n "$VIRTUAL_ENV" ]]; then
        start_jupyter_lab "$VIRTUAL_ENV"
    fi
}

show_mjm_help() {
    grep '^## - ' "${BASH_SOURCE[0]}" | sed 's/^## - //'
}
[[ "$DEBUG_BASH_MODULES" == true ]] && echo -e "\e[32m Loaded: Python Environment Manager module for Bash. Use 'show_pem_help' for usage instructions.\e[0m"
[[ "$DEBUG_BASH_MODULES" == true ]] && echo "<<< EXIT 2_mypythonenvironmentmanager.sh"