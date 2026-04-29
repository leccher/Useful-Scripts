
# MyPythonEnvironment Module

## Panoramica

**MyPythonEnvironment Module** è un modulo Bash avanzato per la gestione dell'ambiente Python, progettato per semplificare:

- il cambio di versione Python
- la creazione e l'attivazione di virtual environment
- l'attivazione automatica dei virtual environment in base alla directory
- l'integrazione con Jupyter Lab

Il modulo è pensato per essere caricato dinamicamente tramite `source` e per integrarsi in ecosistemi Bash modulari.

Compatibile con **Bash 4+**.

---

## Caricamento del modulo

```bash
source mypythonenvironment_module.sh
```

Il modulo è **idempotente**: se caricato più volte, viene inizializzato una sola volta.

Per abilitare messaggi di debug durante il caricamento:

```bash
export DEBUG_BASH_MODULES=true
```

---

## Funzionalità principali

- Cambio versione Python disponibile sul sistema
- Creazione di virtual environment Python (`venv`)
- Attivazione/disattivazione dei venv
- Attivazione automatica del venv al cambio directory
- Integrazione opzionale con Jupyter Lab
- Logging integrato tramite modulo `mylogger`

---

## Gestione versione Python

### Cambiare versione Python attiva

```bash
set_python_version 3.10
```

Il modulo individua automaticamente l'eseguibile `pythonX.Y` disponibile e aggiorna la variabile `PATH`.

---

## Virtual Environment

### Creare un virtual environment

```bash
create_python_venv 3.10 myproject
```

Risultato:
```
.venv_3.10_myproject/
```

### Attivare un virtual environment

```bash
enable_venv
```

Viene mostrato un menu interattivo se sono presenti più venv.

### Disattivare il virtual environment

```bash
disable_python_venv
```

---

## Attivazione automatica

Il modulo espone una funzione watcher per l'attivazione automatica del venv:

```bash
mypem::module_directory_watcher
```

Questa funzione può essere richiamata automaticamente da `.bashrc` o script di cambio directory.

---

## Integrazione Jupyter Lab

```bash
enable_venv_and_jupyter
```

Oppure:

```bash
enable_venv_if_present
```

Avvia Jupyter Lab se disponibile nel venv attivo.

---

## Variabili di ambiente

| Variabile | Descrizione |
|----------|------------|
| `PYTHON_HOME` | Percorso Python attivo |
| `VIRTUAL_ENV` | Virtual environment attivo |
| `MYPYTHON_LOADED` | Flag di caricamento modulo |

---

## Requisiti

- Bash 4.0 o superiore
- Python 3 installato sul sistema
- Modulo `mylogger` opzionale

---

## Note di progettazione

- Nessuna dipendenza esterna obbligatoria
- Logging resiliente con fallback automatico
- Compatibilità con VSCode e shell interattive
- Nessuna modifica permanente al sistema

---

## Licenza

Utilizzabile liberamente in contesti personali o professionali. Modificabile e redistribuibile senza restrizioni.
