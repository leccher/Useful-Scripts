#!/bin/bash
## --- Python Manager Module Help (BASH) ---
## - enable_venv          : Choose which venv to activate.
## - set_python_version [v]   : Change the active Python version.
## - create_python_venv [v] [name] : Create a new venv with the specified Python version and optional name.
## - show_pem_help : Show this help message.
##
## Return values:
## - 0   Success
## - 1   Generic function failure not blocking the script execution (e.g., user canceled a prompt)
## - 2   Module skipped (disabled by flag)
## - 3   Module already loaded
## - 4   No venv found
##
## Error codes (>10):
## - 11  Requested Python version not found
## - 12  Unable to determine current Python version
## - 13  No compatible Python executable found
## - 14  Virtual environment activation script not found
## - 15  Bash version < 4.0
## - 99  Invalid function argument

#% MODULE_NAME=pythonvenv
#% MODULE_DEPENDENCIES=

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
        echo -e "${C_RED}[M_ERROR] ${C_RESET} $*" >&2 >&2
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

#debug ">>> ENTER mypythonenvironmentmanager module"
debug "mypythonenvironmentmanager_module_enter"

# change to true if you don't want this module is used:
if false; then
    #debug ">>> mypythonenvironmentmanager module skipped (disabled by flag)"
    debug "mypythonenvironmentmanager_module_skipped"
    # Return code for skipped by flag
    return 2
fi

if [[ -n "${MYPYTHONVENV_LOADED:-}" ]]; then
    debug "mypythonenvironmentmanager_module_already_loaded"
    [[ "$DEBUG_BASH_MODULES" == true ]] && info ""
    return 3
fi
export MYPYTHONVENV_LOADED=1
export MYPYTHONVENV_VENV_FOLDERS=".venv*"
export MYPYTHONVENV_LAST_USED_FILE=".mmypyman"
# ==============================================================================
# Python Environment Manager (Bash Porting)
# ==============================================================================
# Check bash version
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    error "module_require_bash_4"
    return 15;
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
        return 12
    fi

    if [[ $raw_version =~ ([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

get_python_version() {
    get_current_python_version
}
# --- FUNZIONI CORE ---
# Set the active Python version by adjusting the PATH and PYTHON_HOME environment variables.
set_python_version() {
    local version=$1
    local current_v=$(get_current_python_version)

    if [[ "$version" == "$current_v" ]]; then
        info "python_already_setted" $version
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
        info "python_switched" $target_bin
        return 0
    fi
    error "python_not_found" $version
    return 1
}

# Create a new Python virtual environment with the specified version and optional name.
create_python_venv() {
    local version=$1
    local name=$2
    set_log_level "DEBUG"
    #debug "Passed version=$version, name=$name"
    debug "create_python_venv" $version $name
    if [[ -z "$version" ]]; then
        version=$(get_current_python_version)
        if [[ $? -ne 0 ]]; then
            #error "Unable to determine current Python version."
            error "python_version_not_determined"
            return 12
        fi
    fi
    debug "python_current_version" $version

    if [[ -z "$name" ]]; then
        #read -p "Name/Suffix for venv (Enter as default): [.venv]" name
        name=$(read_prompt "create_venv_name_prompt")
    fi

    local venv_name python_bin
    if [[ -n "$name" ]]; then
        venv_name=".venv_${version}_${name}"
    else
        venv_name=".venv_${version}"
    fi
    #debug "Now venv_name is $venv_name"
    debug "venv_name_resolved" $venv_name

    if [[ ! -d "$venv_name" ]]; then
        #debug "Creating venv: $venv_name..."
        debug "creating_venv" $venv_name
        python_bin=$(get_python_bin "python$version") || return $?
        #debug "python_bin resolved to: $python_bin"
        debug "python_bin_resolved" $python_bin
        if [[ -z "$python_bin" ]]; then
            #error "Python version $version not found. Cannot create venv."
            error "python_version_not_found" $version
            return 11
        fi
        #debug "Executing: $python_bin -m venv $venv_name"
        debug "executing_venv_creation" "$python_bin -m venv $venv_name"
        "$python_bin" -m venv "$venv_name"
    fi
    info "Venv created: $venv_name"
    echo "$venv_name"
    return 0
}

get_python_bin() {
    local python_bin="$1"

    [[ -z "$python_bin" ]] && {
        #error "Usage: find_python_and_print_version <python_executable_name>"
        error "python_bin_argument_required"
        return 99
    }

    # Estrae il prefisso (pythonX)
    local base="${python_bin%%.*}"

    # Estrae la versione completa dopo python
    local version="${python_bin#python}"

    # Genera i candidati in ordine di fallback
    local candidates=(
        "$python_bin"
        "${base}.${version%.*}"
        "$base"
    )

    for candidate in "${candidates[@]}"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done

    #error "No compatible python executable found for '$python_bin'"
    error "python_executable_not_found" "$python_bin"
    return 13
}

# Used to check if venv folder exists and eventually chose the one to enable
get_python_venv() {
    #local folders=($(ls -d .venv* 2>/dev/null))
    #local folders=(.venv*)
    shopt -s nullglob
    local folders=( $MYPYTHONVENV_VENV_FOLDERS )
    shopt -u nullglob
    if [[ ${#folders[@]} -eq 0 ]]; then
        #debug "No venv found."
        debug "no_venv_found"
        return 4
    fi
    local prompt_msg choice
    if [[ ${#folders[@]} -eq 1 ]]; then
        info "choose_venv_one_venv_found" ${folders[0]}
        prompt_msg=$(resolve_i18n "choose_venv_one_venv_found_prompt" "${folders[0]}")
        choice=$(read_prompt "$prompt_msg")
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "${folders[0]}"
            return 0
        fi
    fi
    # ✅ MENU → STDERR
    local version sel
    prompt_msg=$(resolve_i18n "choose_venv_found_prompt")$'\n'
    for i in "${!folders[@]}"; do
        prompt_msg+="$((i + 1)). ${folders[$i]}"$'\n'
    done
    prompt_msg+=$'\n'
    version=$(get_current_python_version) || return $?
    prompt_msg+=$(resolve_i18n "choose_venv_found_prompt_version" "$version")$'\n'
    sel=$(read_prompt "$prompt_msg")
    [[ -z "$sel" ]] && sel=1
    [[ "$sel" == "0" ]] && return 1

    local idx=$((sel-1))
    if [[ $idx -ge 0 && $idx -lt ${#folders[@]} ]]; then
        # ✅ VALORE → STDOUT
        echo "${folders[$idx]}"
        return 0
    fi
    return 1 # Invalid selection
}

disable_python_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate 2>/dev/null || return 1
        #info "Virtual environment deactivated."
        info "venv_deactivated"
        return 0
    else
        #warn "No active virtual environment to deactivate."
        warn "no_venv_to_deactivate"
        return 0
    fi
}
enable_python_venv() {
    local folder=$1
    
    if [[ -z "$folder" ]]; then
        local res rc
        res=$(get_python_venv)
        rc=$?
        case $rc in
            0)
                folder=$res
                ;;
            4)
                folder=$(create_python_venv)
                ;;
            *)
                #error "No venv found or created. Cannot enable."
                error "no_venv_found_or_created"
                return $rc
                ;;
        esac
    fi

    # In Linux: bin/activate
    local activate_script="$folder/bin/activate"
    if [[ -f "$activate_script" ]]; then
        source "$activate_script"
        #info "Enabled $folder"
        info "venv_enabled" "$folder"
        return 0
    fi
    #error "Activate script not found."
    error "activate_script_not_found"
    return 14
}
# --- WRAPPERS PUBBLICI ---

enable_venv() {
    enable_python_venv "$1"
}

# This method is called by .bashrc_custom when the directory changes, if the module is loaded
# Module identifiler + :: + module_diretory_watcher
mypem::module_directory_watcher(){
    local venv=$(get_python_venv)
    if [[ -n "$venv" ]]; then
        enable_python_venv "$venv"
    fi
}

show_pem_help() {
    grep '^## - ' "${BASH_SOURCE[0]}" | sed 's/^## - //'
}
#debug "Loaded: Python Environment Manager module for Bash. Use 'show_pem_help' for usage instructions."
debug "mypythonenvironmentmanager_module_loaded"
#debug "<<< EXIT mypythonenvironmentmanager module"
debug "mypythonenvironmentmanager_module_exit"