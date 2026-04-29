
# .bashrc_custom – Configurazione Bash Personalizzata

## Panoramica

Il file `.bashrc_custom` è un’estensione modulare del file `~/.bashrc`, progettata per contenere configurazioni Bash avanzate e plug-in opzionali senza modificare direttamente il file principale.

---

## Funzionalità principali

- Integrazione automatica di moduli custom
- Esecuzione di funzioini specifiche dopo l'esecuzione del comando "cd cartella/di/destinazione". In particolare alcuni moduli identificano dei file o cartelle presenti e chiedono all'utente di attivare eventuali comportamenti.
- Compatibilità con sistemi Bash modulari

---

## Integrazione con .bashrc

L’inclusione dell'esecuzione di `.bashrc_custom` nel file `~/.bashrc` avviene tramite lo script di supporto:

```bash
add_mybashrc_custom.sh
```

Questo script:
- aggiunge in modo sicuro il comando `source /real/path/to/.bashrc_custom` al file `~/.bashrc`
- evita duplicazioni
- fornisce output informativo durante l’esecuzione

---

## Modularità

Se alcuni moduli non sono richiesti, basta impostare il primo controllo a `true` oppure cancellarli dalla struttura.

```bash
# change to true if you don't want this module is used:
if [ false ]; then
...
```

---

## Funzioni base di log
Alcune funzioni di log di base sono fornite, se non installato il modulo  specifico.

In questo caso non è possibile filtrare i messaggi in base ad un livello di log.

```bash
# Using defined logger, if not found i will use a fallback function
if ! command -v write_log &> /dev/null; then
    write_log() { echo "[$2] $1" >&2; }
    debug() { write_log "$*" DEBUG; }
    info()  { write_log "$*" INFO; }
    warn()  { write_log "$*" WARN; }
    error() { write_log "$*" ERROR; }
fi
```

---

## Requisiti

- Bash 4.0 o superiore
- `curl`
- Eventuali permessi sudo per l’installazione dei pacchetti di sistema necessari ai moduli.

---

## Note di progettazione

- `.bashrc_custom` è separato dal file `.bashrc` principale per facilitare manutenzione e portabilità
- Il codice è idempotente e sicuro da ricaricare
- L’automazione si attiva solo se nei casi in cui i file necessari ai moduli sono presenti

---

## Licenza

Utilizzabile liberamente in contesti personali o professionali.
Redistribuibile e modificabile senza restrizioni.
