#!/bin/bash
# Using defined logger, if not found i will use a fallback function
if ! command -v write_log &> /dev/null; then
    if [[ -f "$LOGGER_PATH" ]]; then
        source "$LOGGER_PATH"
        write_log "Logger module loaded successfully." "INFO"
    else
        write_log() { echo "[$2] $1"; }
        write_log "Logger module NOT found: $LOGGER_PATH" "WARN"
    fi
fi


# Recursive core function
resolve_variable_recursive() {
    local var_name="$1"
    local current_value
    
    write_log "Analyzing variable: $var_name" "DEBUG"

    # Get environment variable value
    # We use indirect expansion ${!var} to retrieve the value from the name
    current_value="${!var_name}"

    if [[ -z "$current_value" ]]; then
        write_log "Variable '$var_name' is empty or not defined." "WARN"
        echo -n "" # Ritorna stringa vuota
        return 1
    fi

    # Regex to find patterns like %VAR%
    # searching for %VAR%
    if [[ "$current_value" =~ %([a-zA-Z_][a-zA-Z0-9_]*)% ]]; then
        local matched_pattern="${BASH_REMATCH[0]}"
        local nested_name="${BASH_REMATCH[1]}"

        write_log "Found nested reference: $matched_pattern" "DEBUG"

        # RECURSIVE CALL
        local resolved_nested=$(resolve_variable_recursive "$nested_name")
        
        # Replace the matched pattern with the resolved value
        local new_value="${current_value//$matched_pattern/$resolved_nested}"
        
        write_log "Replaced $matched_pattern with $resolved_nested" "DEBUG"
        echo -n "$new_value"
    else
        write_log "No nested variable found. Returning raw value." "DEBUG"
        echo -n "$current_value"
    fi
}

# Wrapper to update the environment
resolve_and_export() {
    local var_name="$1"
    local final_value
    
    final_value=$(resolve_variable_recursive "$var_name")
    
    if [[ $? -eq 0 ]]; then
        export "$var_name=$final_value"
        write_log "Variable '$var_name' successfully updated in environment." "DEBUG"
    else
        write_log "Failed to resolve '$var_name'." "WARN"
    fi
}