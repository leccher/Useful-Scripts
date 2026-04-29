# MyLogger Bash Module

Un modulo Bash semplice e robusto per il logging strutturato, colorato e configurabile.
È pensato per essere usato come **modulo caricabile (`source`)** all’interno di script Bash complessi o modulari.

Supporta:
- livelli di log
- output colorato su `stderr`
- scrittura opzionale su file
- identificazione automatica della funzione chiamante
- caricamento idempotente del modulo

Compatibile con **Bash 4+**.

---

## Caricamento del modulo

Per utilizzare il modulo, caricalo con `source`:

```bash
source mylogger_module.sh
```

Il modulo è **idempotente**: se viene caricato più volte, verrà inizializzato una sola volta.

Se imposti la variabile `DEBUG_BASH_MODULES=true`, il modulo stampa messaggi di debug durante il caricamento.

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
write_log "Il mio messaggio" DEBUG
```

Accetta come parametri
- Messaggio di testo
- Livello di debug del messaggio (ERROR,WARN,INFO,DEBUG)

## Funzioni "ready to use"
Per comodià d'uso il modulo espone alcune scorciatoie:

debug
```Shell
debug "Messaggio di debug"
```

info
```Shell
info "Messaggio informativo"
```

warn
```Shell
warn "Messaggio di warning"
```

error
```Shell
error "Messaggio di errore"
```

## Fomattazzione
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
- ERROR: Roso

I colori sono resettati dopo ogni messaggio.

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

Il modulo fornisce anche una semplice funzione per chiedere input all'utente:

```bash
name=$(prompt "Enter your name: ")
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
- Supporto ANSI colors (terminali standard)


## Note di progettazione
- Il modulo scrive sempre su stderr
- È sicuro caricarlo più volte
- Non sovrascrive funzioni o variabili esterne
- Le funzioni hanno nomi generici pensati per usage interno controllato

## Licenza
Utilizzabile liberamente all’interno di script Bash personali o professionali.
Adattabile e modificabile senza restrizioni.