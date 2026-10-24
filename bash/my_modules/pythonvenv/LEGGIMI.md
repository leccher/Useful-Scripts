
# MyPythonEnvironment Module

## Panoramica

**MyPythonEnvironment Module** è un modulo Bash avanzato per la gestione dell'ambiente Python, progettato per semplificare:

- il cambio di versione Python
- la creazione e l'attivazione di virtual environment
- l'attivazione automatica dei virtual environment in base alla directory

Il modulo è pensato per essere caricato dinamicamente tramite `source` e per integrarsi in ecosistemi Bash modulari.

Compatibile con **Bash 4+**.

---

## Funzionalità principali

- Cambio della versione Python attiva
- Creazione di virtual environment Python (`venv`)
- Attivazione e disattivazione dei virtual environment
- Ricerca automatica dei virtual environment nella directory corrente
- Attivazione automatica tramite directory watcher
- Supporto alla localizzazione tramite il modulo `MyLogger`
- Menu interattivo per la selezione del virtual environment
- Compatibilità con framework Bash modulari

---

## Stream di Output

Questo modulo segue la stessa separazione stdout/stderr utilizzata da MyLogger.

Le funzioni che restituiscono un valore scrivono il risultato su `stdout`, mentre i messaggi di log vengono inviati a `stderr`.

Esempi:

```bash
version=$(get_python_version)
venv=$(get_python_venv)
python_bin=$(get_python_bin python3.12)
```

Questo consente di utilizzare le command substitution senza che i messaggi di log interferiscano con i valori restituiti.

Convenzioni utilizzate:

- stdout: risultati delle funzioni e output utilizzabile da altri script
- stderr: messaggi DEBUG, INFO, WARN ed ERROR

---

## Codici di ritorno

| Codice | Descrizione |
|---------|-------------|
| `0` | Successo |
| `1` | Errore non bloccante (ad esempio annullamento da parte dell'utente) |
| `2` | Modulo disabilitato |
| `3` | Modulo già caricato |
| `4` | Nessun virtual environment trovato |
| `11` | Versione Python richiesta non trovata |
| `12` | Impossibile determinare la versione Python corrente |
| `13` | Nessun eseguibile Python compatibile trovato |
| `14` | Script di attivazione del virtual environment non trovato |
| `15` | Versione di Bash inferiore alla 4 |
| `99` | Argomento non valido |

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

Se il nome non viene specificato, verrà richiesto all'utente oppure verrà creato un ambiente con il formato:

```Plain Text
.venv_<versione>
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

Il modulo espone un hook richiamabile dai watcher di cambio directory:

```bash
mypem::module_directory_watcher
```

Questa funzione può essere richiamata automaticamente da `.bashrc` o script di cambio directory.

Il comportamento è il seguente:

- se viene trovato un virtual environment compatibile, viene proposto o attivato
- se sono presenti più virtual environment, viene mostrato un menu di selezione
- se non è presente alcun virtual environment, la directory viene ignorata
- il watcher non crea automaticamente nuovi virtual environment

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

In modalità standalone il modulo fornisce implementazioni di fallback per le funzioni di logging e localizzazione. Quando disponibile, l'integrazione con `MyLogger` offre funzionalità avanzate di logging e i18n.

---

## Note di progettazione

- Compatibile con framework Bash modulari
- Può essere utilizzato anche in modalità standalone
- Utilizza stdout per i valori restituiti e stderr per i messaggi di log
- Supporta il caricamento multiplo sicuro (idempotenza)
- Nessuna modifica permanente al sistema
- Rilevamento automatico dei virtual environment nella directory corrente
- Le directory che non contengono virtual environment vengono ignorate automaticamente
- Supporto alla localizzazione tramite risoluzione i18n

---

## Licenza

Utilizzabile liberamente in contesti personali o professionali. Modificabile e redistribuibile senza restrizioni.
