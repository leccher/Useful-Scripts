
@{
    MODULE_TITLE = 'Modulo My Environment Manager'

    DEBUG_ANALYZE_VAR = 'Analisi variabile: {0}'
    DEBUG_VALUE_FOUND = 'Valore trovato: {0}'
    DEBUG_REPLACE = 'Sostituzione {0} -> {1}'

    ERROR_VAR_NOT_DEFINED = "Errore: Variabile '{0}' non definita"
    WARN_MEMM_PREFIX = 'MEMM: {0}'

    VAR_RESOLVED_SUCCESS = "Variabile '{0}' risolta correttamente."

    DEBUG_MODE_STATUS = 'Modalità debug: {0}'

    HELP_TITLE = "--- Modulo My Environment Manager ---"
    HELP_DESCRIPTION = @"
Risoluzione ricorsiva di riferimenti tra variabili di ambiente (es. %VAR%).
Comandi disponibili:
 - Resolve-RecursiveVariable 'NOME_VAR' : Risolve e applica alla sessione corrente.
 - Set-MyEnvironmentManagerDebug $true/$false : Abilita o disabilita i log dettagliati.

Esempio:
    Resolve-RecursiveVariable 'PATH'
"@
}
