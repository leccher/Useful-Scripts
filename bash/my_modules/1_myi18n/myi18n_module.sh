#!/bin/bash
## --- i18n Module Help (BASH) ---
## - resolve_i18n [KEY] [ARGS...] : Resolve a message key to the corresponding message in the current language, with optional printf-style arguments.
## - show_i18n_help : Show this help message.
# change to true if you don't want this module is used:
if [ false ]; then
    if [[ -n "${MYLOGGER_LOADED:-}" ]]; then
        debug "module_loading_skipped_by_flag"
    fi
    return
fi
[[ "$DEBUG_BASH_MODULES" == true ]] && info "module_start_code"

resolve_i18n() {
    local key="$1"
    shift

    # File chiamante reale
    local caller_file="${BASH_SOURCE[3]}"

    # Se non riesco a risalire al chiamante → messaggio raw
    if [[ -z "$caller_file" ]]; then
        printf "%s" "$key"
        return 0
    fi

    local module_dir
    module_dir="$(cd "$(dirname "$caller_file")" && pwd)"

    local msg_file="$module_dir/localisation/messages.$MY_LANG"
    [[ -f "$msg_file" ]] || msg_file="$module_dir/localisation/messages.en-EN"

    # Se non esiste alcun file messaggi → debug + raw
    if [[ ! -f "$msg_file" ]]; then
        debug "i18n: no messages file for module '$(basename "$module_dir")'"
        printf "%s" "$key"
        return 0
    fi

    local value
    value="$(awk -F= -v k="$key" '$1==k {print substr($0,index($0,$2)); exit}' "$msg_file")"

    # ✅ CHIAVE NON TROVATA → comportamento richiesto
    if [[ -z "$value" ]]; then
        debug "i18n: key '$key' not found in $(basename "$msg_file"), using raw message"
        printf "%s" "$key"
        return 0
    fi

    # ✅ CHIAVE TROVATA → printf-style (%s)
    printf "$value" "$@"
}

show_i18n_help() {
    grep '^## - ' "${BASH_SOURCE[0]}" | sed 's/^## - //'
}

[[ "$DEBUG_BASH_MODULES" == true ]] && info "Loaded: i18n module for Bash. Use 'show_i18n_help' for usage instructions."
[[ "$DEBUG_BASH_MODULES" == true ]] && info "<<< EXIT myi18n_module.sh"