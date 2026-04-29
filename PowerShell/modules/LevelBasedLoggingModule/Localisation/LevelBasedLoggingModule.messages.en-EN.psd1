
@{
    # General
    MODULE_DESCRIPTION = 'PowerShell logging module'

    # Log messages
    LOG_FILE_ENABLED   = 'Logging to file enabled: {0}'
    LOG_FILE_DISABLED  = 'Logging to file disabled'
    LOG_FILE_MISSING   = 'Log file path required. Use Enable-LogToFile ''file-path'''

    # Debug / Info
    DEBUG_LEVEL_SET    = 'Log level set to: {0}'
    LOG_TO_FILE_PATH   = 'Log file path: {0}'

    # Help (multiline)
    HELP_TEXT = @"
Write-Log for PowerShell

This module implements the Write-Log function
to provide structured logging for your scripts.

Available levels:
  DEBUG
  INFO
  WARN
  ERROR

The module uses Write-Debug:

Example:
  Set-LogLevel 'DEBUG'
  Write-Log 'Test message' -Level 'WARN'

Optional file logging:
  Enable-LogToFile 'C:\\temp\\app.log'
"@
}
