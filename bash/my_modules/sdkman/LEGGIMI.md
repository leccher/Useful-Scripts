
# SDKMAN Bash Module

## Panoramica

Questo modulo fornisce un'integrazione semplice e automatica di **SDKMAN!** all'interno di un ambiente Bash modulare.

Il modulo:
- verifica la presenza di SDKMAN!
- installa automaticamente SDKMAN! se non presente
- gestisce i prerequisiti (`zip`, `unzip`)
- abilita il cambio automatico delle versioni SDK tramite file `.sdkmanrc`
- espone un *directory watcher* compatibile con sistemi modulari Bash

Il modulo è pensato per essere caricato tramite `source` ed integrato in `.bashrc` o sistemi di moduli dinamici.

Compatibile con **Bash 4+**.

---

## Cosìè SDKMAN!

SDKMAN! è uno strumento che permette di installare e gestire facilmente più versioni di diversi Software Development Kit (SDK) e strumenti legati all'ecosistema JVM, tra cui:

- Java
- Maven
- Gradle
- Kotlin
- Groovy
- Scala
- Spring Boot

Il modulo:

- verifica la presenza di SDKMAN!
- propone l'installazione di SDKMAN! se non presente
- verifica la disponibilità dei prerequisiti richiesti (`zip`, `unzip`)
- propone l'installazione dei prerequisiti mancanti
- abilita il cambio automatico delle versioni SDK tramite file `.sdkmanrc`
- espone un *directory watcher* compatibile con sistemi Bash modulari
- integra il supporto i18n e logging del framework

---

### Perché utilizzare questo modulo

Quando si lavora su progetti differenti è frequente dover utilizzare versioni diverse degli strumenti di sviluppo.

Ad esempio:

**Progetto A**

```text
Java 17
Maven 3.9
```

```text
Java 21
Gradle 9
```

Senza questo modulo è necessario ricordarsi di eseguire manualmente:

```Shell
sdk man
```

ogni volta che si entra nella directory del progetto.

Il modulo automatizza questa operazione tramite il meccanismo di directory watcher utilizzato dal framework.

### File .sdkmanrc

SDKMAN! permette di definire le versioni richieste direttamente all'interno del progetto tramite un file .sdkmanrc.

Esempio:

```Plain Text
java=21.0.8-tem
maven=3.9.11
gradle=9.1.0
```

Quando si entra in una directory che contiene questo file, il modulo applica automaticamente l'ambiente corretto.

---

## Caricamento del modulo

Se scaricato insieme al pacchetto **usefull_scripts** è caricato dal file **.bashrc_custom**.

```bash
source sdkman_module.sh
```

Al primo caricamento:
- se SDKMAN! non è installato, viene avviata l'installazione
- vengono verificati e installati (`apt`) i pacchetti `zip` e `unzip` con `sudo`.

---

## Funzionalità principali

- Integrazione automatica con SDKMAN!
- Installazione guidata di SDKMAN!
- Verifica automatica delle dipendenze (zip, unzip)
- Supporto nativo all'i18n
- Cambio automatico delle versioni tramite .sdkmanrc
- Hook di attivazione basato sulla directory corrente
- Compatibilità con framework Bash modulari
- Supporto al caricamento multiplo sicuro (idempotenza)

---

## Codici di ritorno

| Codice | Descrizione |
|--------|------------|
| `0` | Successo |
| `1` | Errore non bloccante o operazione annullata dall'utente |
| `2` | Modulo disabilitato |
| `3` | Modulo giù caricato |
| `15` | Versione Bash inferiore alla 4.0 |

## Stream di Output

Il modulo segue la stessa convenzione utilizzata dagli altri moduli del framework.

Convenzioni:

stdout: valori restituiti dalle funzioni
stderr: messaggi DEBUG, INFO, WARN ed ERROR

Questo consente l'integrazione con command substitution e script automatizzati senza contaminare l'output funzionale con i messaggi di log.

---

## Attivazione automatica per directory

Il modulo espone la funzione:

```bash
sdkman::module_directory_watcher
```

Comportamento:
- controlla la presenza del file .sdkmanrc
- se presente esegue sdk env
- applica automaticamente le versioni SDK richieste dal progetto
- evita riesecuzioni inutili quando la directory corrente non cambia

Può essere chiamata automaticamente da `.bashrc` o da un gestore di cambio directory.

---

## Esempio di utilizzo con .bashrc

```bash
# dopo aver caricato il modulo
sdkman::module_directory_watcher
```

Con una directory che contiene `.sdkmanrc`, SDKMAN! applicherà automaticamente la configurazione SDK.

---

## Requisiti

- Bash 4.0 o superiore
- `curl`
- `zip`, `unzip` (installati automaticamente se mancanti)
- SDKMAN! (rilevato automaticamente e installabile dal modulo)
- Permessi di installazione (sudo) per prerequisiti di sistema

---

## Note di progettazione

- Compatibile con framework Bash modulari
- Supporta il caricamento multiplo sicuro
- Utilizza implementazioni di fallback per logging e i18n quando necessario
- Richiede interazione utente solo quando SDKMAN! o le dipendenze non sono disponibili
- Segue la procedura ufficiale di installazione di SDKMAN!
- Non modifica il sistema se non dopo esplicita conferma dell'utente
- Il watcher agisce solamente in presenza di un file `.sdkmanrc`
- Riduce il rischio di utilizzare versioni errate degli SDK tra progetti differenti

---

## Licenza

Modulo libero e riutilizzabile per scopi personali o professionali.
Modificabile e redistribuibile senza restrizioni.

---