#! /bin/bash
## --- SDKMAN! Module Help (BASH) ---
## - sdkman::module_directory_watcher : Automatically switch SDK versions when changing directories with .sdkmanrc files.
## - show_sdkman_help : Show this help message.
##
## Return values:
## - 0   Success
## - 1   Generic non-fatal failure
## - 2   Module skipped
## - 3   Module already loaded
## - 15  Bash version < 4.0

#% MODULE_NAME=mysdkman
#% MODULE_DEPENDENCIES=
# SDKMAN! integration for bash
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

#debug ">>> ENTER mysdkman module"
debug "mysdkman_module_enter"
# change to true if you don't want this module is used:
if false; then
    #debug ">>> mypythonenvironmentmanager module skipped (disabled by flag)"
    debug "mysdkman_module_skipped"
    # Return code for skipped by flag
    return 2
fi
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    error "module_require_bash_4"
    return 15
fi

if [[ -n "${MYSDKMAN_LOADED:-}" ]]; then
    debug "mysdkman_module_already_loaded"
    return 3
fi
MYSDKMAN_LOADED=1
MYSDKMAN_LAST_ENEBLED_DIR=""

# Check if sdkman exists or source and install if not present
if [[ ! -d "$HOME/.sdkman" ]]; then
    # SDKMAN need zip and unzip to work properly, so we check for them before sourcing SDKMAN
    if ! command -v zip &> /dev/null; then
        ##response=$(read_prompt "SDKMAN: zip not found. Would youl ike to install it? (y/n): ")
        response=$(read_prompt "sdkman_zip_not_found_prompt")
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            ##error "SDKMAN: zip not found, cannot install SDKMAN without it."
            error "sdkman_zip_not_found_error"
            return 1
        fi
        ##info "SDKMAN: Installing zip..."
        info "sdkman_zip_installing"
        sudo apt get install zip -y
    fi
    if ! command -v unzip &> /dev/null; then
        ##response=$(read_prompt "SDKMAN: unzip not found. Would you like to install it? (y/n): ")
        response=$(read_prompt "sdkman_unzip_not_found_prompt")
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            ##error "SDKMAN: unzip not found, cannot install SDKMAN without it."
            error "sdkman_unzip_not_found_error"
            return 1
        fi
        ##info "SDKMAN: Installing unzip..."
        info "sdkman_unzip_installing"
        sudo apt get install unzip -y
    fi
    response=$(read_prompt "sdkman_not_found_prompt")
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        ##error "SDKMAN: sdk not found, cannot continue without it."
        error "sdkman_not_found_error"
        return 1
    fi
    ##info "SDKMAN: sdk not found, installing..."
    info "sdkman_installing"
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi
show_sdkman_help() {
    grep '^## - ' "${BASH_SOURCE[0]}" | sed 's/^## - //'
}

# This method is called by .bashrc_custom when the directory changes, if the module is loaded
# Module identifiler + :: + module_diretory_watcher
# if current folder contains .sdkmanrc, execute sdk env to switch to the correct SDK version
sdkman::module_directory_watcher(){
    local current_dir="$PWD"
    if [[ "$current_dir" == "$MYSDKMAN_LAST_ENEBLED_DIR" ]]; then
        return 0
    fi
    MYSDKMAN_LAST_ENEBLED_DIR="$current_dir"
    if [[ -f ".sdkmanrc" ]]; then
        sdk env
    fi
}

#debug "Loaded: SDKMAN Manager module for Bash. Use 'show_sdkman_help' for usage instructions."
debug "mysdkman_module_loaded"
#debug "<<< EXIT mysdkman_module"
debug "mysdkman_module_exit"