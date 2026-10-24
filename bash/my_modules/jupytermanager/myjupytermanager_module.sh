#!/bin/bash
## --- Jupyter Manager Module Help (BASH) ---
## - start_jupyter_lab  : Start jupyter lab if present in the current venv when the directory changes.
## - install_jupyter_lab   : Install Jupyter Lab in the current venv.
## - show_mjm_help : Show this help message.
##
## Return values:
## - 0   Success
## - 1   Generic non-fatal failure
## - 2   Module skipped
## - 3   Module already loaded
##
## Error codes (>10):
## - 11  Jupyter Lab installation failed
## - 12  Python manager module required but not loaded
## - 15  Bash version < 4.0

#% MODULE_NAME=jupytermanager
#% MODULE_DEPENDENCIES=pythonvenv


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
# Debugging and logging functions
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
if ! declare -F resolve_i18n >/dev/null; then
    resolve_i18n() {
        local key="$1"
        shift

        # No real translation support in standalone mode.
        # Return the key (optionally formatted with printf arguments).
        printf -- "$key" "$@"
    }
fi
if ! declare -F read_prompt >/dev/null; then
    read_prompt() {
        local prompt="$1"
        local response

        read -r -p "$prompt" response
        printf -- '%s\n' "$response"
    }
fi
#debug ">>> ENTER myjupitermanager module"
debug "jupyter_module_enter"

# change to true if you don't want this module is used:
if false; then
    #debug ">>> myjupytermanager module skipped (disabled by flag)"
    debug "jupyter_module_skipped"
    # Return code for skipped by flag
    return 2
fi

if [[ -n "${MYJUPYTERMAN_LOADED:-}" ]]; then
    #debug ">>> myjupytermanager module skipped (already loaded)"
    debug "jupyter_module_already_loaded"
    return 3
fi
if ! declare -F get_python_venv >/dev/null; then
    error "python_manager_required"
    return 12
fi
export MYJUPYTERMAN_LOADED=1
# Check bash version
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    #error "This script require Bash 4.0 or higher."
    error "bash_version_error"
    return 15
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
        local choice
        # Prompt the user to start Jupyter Lab
        #read_prompt "Starting Jupyter Lab? (y/n): " choice
        choice=$(read_prompt "start_jupyter_lab_prompt")
        if [[ "$choice" == "y" ]]; then
            "$bin"
        fi
    fi
}

install_jupyter_lab() {
    # check if we are in a venv, if not return error
    if [[ -z "$VIRTUAL_ENV" ]]; then
        local venv rc
        venv=$(get_python_venv)
        rc=$?

        if (( rc == 0 )); then
            enable_python_venv "$venv"
        fi
    fi
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local bin="$VIRTUAL_ENV/bin/jupyter-lab"
        if [[ -f "$bin" ]]; then
            #info "Jupyter Lab is already installed in the current virtual environment."
            info "jupyter_installed"
            return 0
        else
            if ! pip install jupyterlab; then
                #error "Failed to install Jupyter Lab. Please check your pip configuration and try again."
                error "jupyter_install_failed"
                return 11
            fi
            #info "Jupyter Lab installed successfully in the current virtual environment."
            info "jupyter_install_success"
            return 0
        fi
    else
        #error "No active virtual environment. Please activate a virtual environment before installing Jupyter Lab."
        error "jupyter_no_active_venv"
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
#debug "Loaded: Jupyter Manager module for Bash. Use 'show_pem_help' for usage instructions."
debug "jupyter_module_loaded"
#debug "<<< EXIT myjupytermanager module"
debug "jupyter_module_exit"