
@{
    PS_VERSION_REQUIRED = 'Il modulo Jupyter Manager richiede PowerShell 7.0 o superiore. Versione attuale: {0}'

    DEBUG_VENV_ENABLED  = 'Ambiente virtuale attivo in: {0}'
    DEBUG_VENV_NONE     = 'Nessun ambiente virtuale attivo'

    PROMPT_START_JUPYTER = 'Avviare Jupyter Lab? (y/n)'

    JUPYTER_STARTED     = 'Jupyter avviato.'
    JUPYTER_NOT_FOUND   = 'Jupyter non presente o avvio rifiutato.'

    NO_VENV_ENABLE      = 'Nessun ambiente virtuale attivo. Attiva un venv per abilitare Jupyter Lab.'
    JUPYTER_ENABLED     = 'Jupyter Lab abilitato se presente.'

    JUPYTER_INSTALL_OK  = 'Jupyter Lab installato nell''ambiente virtuale corrente.'
    JUPYTER_ALREADY     = 'Jupyter Lab è già installato nell''ambiente virtuale corrente.'
    PIP_NOT_FOUND       = 'pip non trovato nell''ambiente virtuale corrente.'
    NO_VENV_INSTALL     = 'Nessun ambiente virtuale attivo. Attiva un venv per installare Jupyter Lab.'

    HELP_HEADER = '--- Modulo Jupyter Lab Manager ---'

    HELP_TEXT = @"
Gestisce l''avvio e l''installazione di Jupyter Lab
nell''ambiente virtuale Python attualmente attivo.

Comandi disponibili:
  Help-MyJupyterModule   Mostra questo messaggio di aiuto.
  Enable-JupyterLab     Avvia Jupyter Lab nel venv attivo, se presente
  Install-JupyterLab    Installa Jupyter Lab nel venv attivo
"@
}
