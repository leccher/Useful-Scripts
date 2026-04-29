
@{
    # Module / Version
    PS_VERSION_REQUIRED = 'Il modulo Python Manager richiede PowerShell 7.0 o superiore. Versione attuale: {0}'

    # Debug / internal
    DEBUG_FIXPATH_CALLED   = 'Chiamata funzione Fix-Path...'
    DEBUG_FIXPATH_FAILED   = 'Impossibile espandere {0}, mantenuto il valore originale.'
    DEBUG_FIXPATH_OK       = 'Fix-Path completato: {0}'

    DEBUG_PYTHON_VER_RAW   = 'Versione Python rilevata: {0}'
    DEBUG_PYTHON_VER_OK    = 'Formato versione Python valido'
    DEBUG_PYTHON_VER_BAD   = 'Formato versione Python non valido'
    DEBUG_PYTHON_NOT_FOUND = 'Comando python non trovato nel PATH'

    # Python version switching
    PYTHON_ALREADY_ACTIVE  = 'La versione Python {0} è già attiva.'
    PYTHON_SWITCH_OK       = 'Switch a Python {0} eseguito.'
    PYTHON_VERSION_UNAVAIL = 'Versione non disponibile: {0}. Disponibili: {1}'
    PYTHON_ACTIVATED      = 'Versione Python attivata: {0}'

    # Virtual env creation / activation
    VENV_NAME_PROMPT   = 'Nome/Suffisso per il venv (Invio per default)'
    VENV_CREATING      = 'Creazione ambiente virtuale: {0}...'
    VENV_READY         = 'Ambiente virtuale pronto: {0}'
    VENV_SELECTED      = 'Ambiente virtuale attivato: {0}'
    VENV_NOT_FOUND     = 'Script di attivazione non trovato.'
    VENV_NONE_FOUND    = 'Nessun ambiente virtuale trovato.'
    VENV_SELECTION_HDR = 'Scegli l''ambiente virtuale:'
    VENV_SELECTION_BAD = 'Scelta non valida.'
    VENV_CANCELLED     = 'Operazione annullata.'
    VENV_AVAILABLE      = 'Ambienti virtuali disponibili: {0}'

    # Jupyter
    JUPYTER_PROMPT     = 'Avviare Jupyter Lab? (y/n)'
    JUPYTER_STARTED    = 'Jupyter Lab avviato.'
    JUPYTER_NOT_FOUND  = 'Jupyter Lab non presente o avvio rifiutato.'

    # Help (multiline)
    HELP_HEADER = '--- Python Manager Module ---'
    HELP_TEXT = @"
Gestisce più installazioni di Python e ambienti virtuali.

Comandi disponibili:
  Enable-Venv            Sceglie o crea un venv e lo attiva
  Enable-VenvAndJupyter  Attiva il venv e avvia Jupyter Lab

Esempio:
  Enable-Venv
"@
}
