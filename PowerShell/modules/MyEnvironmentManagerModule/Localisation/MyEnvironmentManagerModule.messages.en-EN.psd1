
@{
    MODULE_TITLE = 'My Environment Manager Module'

    DEBUG_ANALYZE_VAR = 'Analyzing variable: {0}'
    DEBUG_VALUE_FOUND = 'Value found: {0}'
    DEBUG_REPLACE = 'Replacing {0} -> {1}'

    ERROR_VAR_NOT_DEFINED = "Error: Variable '{0}' is not defined"
    WARN_MEMM_PREFIX = 'MEMM: {0}'

    VAR_RESOLVED_SUCCESS = "Variable '{0}' successfully resolved."

    DEBUG_MODE_STATUS = 'Debug mode: {0}'

    HELP_TITLE = '--- My Environment Manager Module ---'
    HELP_DESCRIPTION = @"
Recursively resolves references among environment variables (e.g. %VAR%).
Available commands:
 - Resolve-RecursiveVariable 'VAR_NAME' : Resolve and apply to current session."
 - Set-MyEnvironmentManagerDebug $true/$false : Enable or disable detailed logs.'

Example:
    Resolve-RecursiveVariable 'PATH'
"@
}
