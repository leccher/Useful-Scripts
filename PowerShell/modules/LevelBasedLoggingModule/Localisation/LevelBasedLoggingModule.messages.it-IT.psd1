
@{
    # General
    MODULE_DESCRIPTION = 'Modulo di logging per PowerShell'

    # Log messages
    LOG_FILE_ENABLED   = 'Logging su file abilitato: {0}'
    LOG_FILE_DISABLED  = 'Logging su file disabilitato'
    LOG_FILE_MISSING   = 'Percorso file di log necessario. Usa Enable-LogToFile ''percorso-file'''

    # Debug / Info
    DEBUG_LEVEL_SET    = 'Livello di log impostato a: {0}'
    LOG_TO_FILE_PATH   = 'Percorso file di log: {0}'

    # Help (multiline)
    HELP_HEADER = '--- Modulo Logger per Powershell ---'
    HELP_TEXT = @"
Questo modulo implementa la funzione Write-Log
per fornire logging strutturato nei tuoi script.

Livelli disponibili:
  DEBUG
  INFO
  WARN
  ERROR

Come usare Write-Log:

Esempio:
  Set-LogLevel 'DEBUG'
  Write-Log 'Messaggio di test' -Level 'WARN'

Logging su file opzionale:
  Enable-LogToFile 'C:\\temp\\app.log'
"@
}
