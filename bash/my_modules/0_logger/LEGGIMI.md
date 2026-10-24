# MyLogger Bash Module

Un modulo Bash semplice e robusto per il logging strutturato, colorato e configurabile.
È pensato per essere usato come **modulo caricabile (`source`)** all’interno di script Bash complessi o modulari.

Supporta:

- livelli di log configurabili
- output colorato su `stderr`
- scrittura opzionale su file
- identificazione automatica della funzione chiamante
- caricamento idempotente del modulo
- supporto i18n integrato con cataloghi per modulo
- risoluzione automatica della lingua e fallback multilivello
- supporto ai placeholder stile printf (%s)
- localizzazione sia dei messaggi di log che dei prompt utente

Compatibile con **Bash 4+**.

---

## Caratteristiche Principali

- Livelli di log configurabili (DEBUG, INFO, WARN, ERROR)
- Output colorato ANSI scritto su `stderr`
- Logging opzionale su file
- Rilevamento automatico della funzione chiamante
- Caricamento idempotente del modulo per evitare ridefinizioni
- **Supporto i18n integrato e lazy (key=value)** con risoluzione dei messaggi al momento del logging
- iIdentificazione automatica della funzione chiamante nei messaggi di log

---

## Stream di Output

MyLogger scrive sempre i messaggi di log su `stderr`.

Questa scelta progettuale consente alle funzioni Bash di restituire dati tramite `stdout` senza che i messaggi di log interferiscano con le command substitution.

Esempio:

```bash
version=$(get_current_python_version)
venv=$(get_python_venv)
python_bin=$(get_python_bin python3.12)
```

Anche quando vengono emessi messaggi DEBUG, INFO, WARN o ERROR, le variabili cattureranno esclusivamente il valore restituito dalla funzione.

Convenzioni utilizzate da questo framework:

stdout : risultati delle funzioni e output leggibile da altri script o programmi
stderr : messaggi di DEBUG, INFO, WARN ed ERROR

---

## Codici di ritorno

| Codice | Significato |
|---------|------------|
| 0 | Operazione completata |
| 1 | Livello di log inferiore a quello configurato |
| 2 | Modulo disabilitato |
| 11 | Livello di log non valido |
| 12 | Errore nella risoluzione del livello di log corrente |

In generale codici sopra il 10 sono considerati errori bloccanti.

---

## Caricamento del modulo

Per utilizzare il modulo, caricalo con `source`:

```bash
source mylogger_module.sh
```

Il modulo è **idempotente**: se viene caricato più volte, verrà inizializzato una sola volta.

Quando DEBUG_BASH_MODULES=true, il logger passa automaticamente al livello DEBUG indipendentemente dal valore impostato tramite set_log_level().

```Shell
export DEBUG_BASH_MODULES=true
```

## Livelli di log supportati
Il modulo supporta i seguenti livelli di log (in ordine di severità):

- DEBUG
- INFO (default)
- WARN
- ERROR

Ogni messaggio viene mostrato solo se il suo livello è **uguale o superiore** al livello corrente.

### Impostare il livello di log
Per cambiare il livello di log globale:
```Shell
set_log_level DEBUG
```

Valori validi:
```
DEBUG | INFO | WARN | ERROR
```
Esempio:
```Shell
set_log_level WARN
```

## Funzione principale
```Bash
write_log DEBUG "Il mio messaggio"
```

Accetta come parametri
- Livello di log (ERROR,WARN,INFO,DEBUG)
- Testo libero oppure chiave i18n
- Eventuali parametri per la sostituzione dei placeholder (%s)

Esempio
```Shell
write_log INFO python_found "3.12"
```

## Funzioni "ready to use"
Per comodità d'uso il modulo espone alcune scorciatoie:

debug
```Shell
debug "Messaggio di debug"
debug "debug_message" "Nessuno"
```

info
```Shell
info "Messaggio informativo"
info python_found "3.12"
```

warn
```Shell
warn "Messaggio di warning"
warn disk_space_low "/tmp"
```

error
```Shell
error "Messaggio di errore"
error virtualenv_missing ".venv"
```

## Formattazione
Tutti i messaggi:

- includono timestamp
- includono il livello
- includono il nome della funzione chiamante (se presente)
- vengono scritti su stderr

### Output colorato
Il modulo utilizza colori ANSI per distinguere i livelli:

- DEBUG: Viola
- INFO: Verde
- WARN: Giallo
- ERROR: Rosso

I colori sono resettati dopo ogni messaggio.

## Supporto i18n integrato

Il modulo include un sistema di localizzazione integrato che non richiede moduli esterni.

Le traduzioni vengono risolte in modo lazy al momento dell'emissione del log o della visualizzazione di un prompt.

### Cataloghi messaggi

Ogni modulo può avere il proprio catalogo:

```Plain text
my_module/
├── my_module.sh
└── localisation/
    ├── messages.it-IT
    ├── messages.it
    ├── messages.en-EN
    └── messages.en
```
### Formato dei file
```INI
python_found=Python version %s found
virtualenv_missing=Virtual environment '%s' not found
enter_project_name=Enter project name:
```

### Utilizzo

```Shell
info python_found "3.12"

error virtualenv_missing ".venv"

project=$(read_prompt enter_project_name)
```
### Risoluzione della lingua

La lingua viene determinata nel seguente ordine:

- Variabile d'ambiente MY_LANG
- Variabile di sistema LANG
- Catalogo specifico della lingua (messages.it-IT)
- Catalogo generico della lingua (messages.it)
- Catalogo inglese (messages.en-EN)
- Catalogo inglese generico (messages.en)

Esempio
```Shell
export LANG=it_IT.UTF-8
```
Ricerca automatica
```Plain Text
1. messages.it-IT
2. messages.it
3. messages.en-EN
4. messages.en
```


## File di log

### Abilitare il log su file

```bash
enable_log_to_file
```

Oppure specificando il file di log:

```bash
enable_log_to_file "/path/to/logfile.log"
```

Il file di log predefinito è:

```
$HOME/bash_scripts_log.txt
```

### Disabilitare il log su file

```bash
disable_log_to_file
```

---

## Utility Function: Prompt

Il modulo fornisce una funzione per richiedere input all'utente. L'input inserito dall'utente viene restituito tramite stdout, rendendo possibile l'uso diretto tramite command substitution.

Anche i prompt supportano la localizzazione tramite chiavi i18n e placeholder.

Esempio


```bash
name=$(read_prompt "Enter your name: ")
version=$(read_prompt ask_python_version)
project=$(read_prompt select_project "%s" "$default_project")
```

---

## Variabili globali

| Variabile | Descrizione |
|-----------|-------------|
| `MYLOGGER_LOG_LEVEL` | Livello di log corrente (default: INFO) |
| `MYLOGGER_LOG_TO_FILE` | true / false | 
| `MYLOGGER_LOG_FILE_PATH` | Percorso del file di log |
| `MYLOGGER_LOADED` | Flag di caricamento modulo |

## Esempio completo
```bash
#!/bin/bash
source mylogger_module.sh

set_log_level DEBUG
enable_log_to_file "/tmp/app.log"

my_function() {
    debug "Avvio funzione"
    info "Elaborazione in corso"
    warn "Condizione non ottimale"
    error "Errore simulato"
}

my_function
```

## Requisiti

- Bash 4.0 o superiore
- Supporto ANSI color (terminali standard)


## Note di progettazione
- Il modulo scrive sempre su stderr
- È sicuro caricarlo più volte
- Le funzioni di supporto già esistenti vengono rilevate automaticamente e non vengono ridefinite
- Le funzioni pubbliche sono volutamente concise per facilitare l'utilizzo all'interno degli script Bash.
- Identificazione automatica della funzione chiamante nei messaggi di log
- Ogni modulo può mantenere cataloghi di traduzione indipendenti
- I cataloghi vengono individuati automaticamente in base allo script chiamante
- Chiavi o cataloghi mancanti non generano errori fatali
- In caso di mancata risoluzione viene utilizzato il testo originale
- Supporto nativo per placeholder stile printf (%s)

## Licenza
Utilizzabile liberamente all’interno di script Bash personali o professionali.
Adattabile e modificabile senza restrizioni.