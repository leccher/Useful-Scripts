
@{
    PS_VERSION_REQUIRED = 'The Jupyter Manager module requires PowerShell 7.0 or higher. Current version: {0}'

    DEBUG_VENV_ENABLED  = 'Virtual environment enabled in: {0}'
    DEBUG_VENV_NONE     = 'No virtual environment enabled'

    PROMPT_START_JUPYTER = 'Start Jupyter Lab? (y/n)'

    JUPYTER_STARTED     = 'Jupyter started.'
    JUPYTER_NOT_FOUND   = 'Jupyter not found or startup declined.'

    NO_VENV_ENABLE      = 'No virtual environment enabled. Activate a venv to enable Jupyter Lab.'
    JUPYTER_ENABLED     = 'Jupyter Lab enabled if present.'

    JUPYTER_INSTALL_OK  = 'Jupyter Lab installed in the current virtual environment.'
    JUPYTER_ALREADY     = 'Jupyter Lab is already installed in the current virtual environment.'
    PIP_NOT_FOUND       = 'pip not found in the current virtual environment.'
    NO_VENV_INSTALL     = 'No virtual environment enabled. Activate a venv to install Jupyter Lab.'

    HELP_HEADER = '--- Jupyter Lab Manager Module ---'

    HELP_TEXT = @"
Manages startup and installation of Jupyter Lab
within the currently active Python virtual environment.

Available commands:
  Help-MyJupyterModule   Show this help message.
  Enable-JupyterLab     Starts Jupyter Lab in the active venv, if present
  Install-JupyterLab    Installs Jupyter Lab in the active venv
"@
}
