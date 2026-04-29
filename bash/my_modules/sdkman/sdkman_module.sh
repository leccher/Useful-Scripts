#! /bin/bash
## --- SDKMAN! Module Help (BASH) ---
## - sdkman::module_directory_watcher : Automatically switch SDK versions when changing directories with .sdkmanrc files.
## - show_sdkman_help : Show this help message.
# SDKMAN! integration for bash

# Check if sdkman exists or source and install if not present
if [[ ! -d "$HOME/.sdkman" ]]; then
    # SDKMAN need zip and unzip to work properly, so we check for them before sourcing SDKMAN
    if ! command -v zip &> /dev/null; then
        echo "SDKMAN: zip not found, installing..."
        sudo apt get install zip -y
    fi
    if ! command -v unzip &> /dev/null; then
        echo "SDKMAN: unzip not found, installing..."
        sudo apt get install unzip -y
    fi
    echo "SDKMAN: sdk not found, installing..."
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
    if [[ -f ".sdkmanrc" ]]; then
        sdk env
    fi
}