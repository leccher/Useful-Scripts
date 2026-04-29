
@{
    # Module / Version
    PS_VERSION_REQUIRED = 'The Python Manager module requires PowerShell 7.0 or higher. Current version: {0}'

    # Debug / internal
    DEBUG_FIXPATH_CALLED   = 'Fix-Path function called...'
    DEBUG_FIXPATH_FAILED   = 'Failed to expand {0}, keeping original value.'
    DEBUG_FIXPATH_OK       = 'Fix-Path completed: {0}'

    DEBUG_PYTHON_VER_RAW   = 'Detected Python version: {0}'
    DEBUG_PYTHON_VER_OK    = 'Valid Python version format'
    DEBUG_PYTHON_VER_BAD   = 'Invalid Python version format'
    DEBUG_PYTHON_NOT_FOUND = 'Python command not found in PATH'

    # Python version switching
    PYTHON_ALREADY_ACTIVE  = 'Python version {0} is already active.'
    PYTHON_SWITCH_OK       = 'Switched to Python {0}.'
    PYTHON_VERSION_UNAVAIL = 'Unavailable version: {0}. Available: {1}'
    PYTHON_ACTIVATED      = 'Activated Python version: {0}'

    # Virtual env creation / activation
    VENV_NAME_PROMPT   = 'Name/Suffix for venv (Enter for default)'
    VENV_CREATING      = 'Creating virtual environment: {0}...'
    VENV_READY         = 'Virtual environment ready: {0}'
    VENV_SELECTED      = 'Virtual environment activated: {0}'
    VENV_NOT_FOUND     = 'Activation script not found.'
    VENV_NONE_FOUND    = 'No virtual environment found.'
    VENV_SELECTION_HDR = 'Choose virtual environment:'
    VENV_SELECTION_BAD = 'Invalid selection.'
    VENV_CANCELLED     = 'Operation cancelled.'
    VENV_AVAILABLE      = 'Available virtual environments: {0}'

    # Jupyter
    JUPYTER_PROMPT     = 'Start Jupyter Lab? (y/n)'
    JUPYTER_STARTED    = 'Jupyter Lab started.'
    JUPYTER_NOT_FOUND  = 'Jupyter Lab not found or startup declined.'

    # Help (multiline)
    HELP_HEADER = '--- Python Manager Module ---'
    HELP_TEXT = @"
Manages multiple Python installations and virtual environments.

Available commands:
  Enable-Venv            Selects or creates a venv and activates it
  Enable-VenvAndJupyter  Activates venv and starts Jupyter Lab

Example:
  Enable-Venv
"@
}
