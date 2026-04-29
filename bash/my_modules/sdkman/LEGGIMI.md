
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
- Installazione automatica di SDKMAN! se assente
- Supporto a `.sdkmanrc` per cambio versione automatico
- Hook di attivazione basato sulla directory

---

## Attivazione automatica per directory

Il modulo espone la funzione:

```bash
sdkman::module_directory_watcher
```

Questa funzione:
- verifica la presenza del file `.sdkmanrc` nella directory corrente
- se presente, esegue `sdk env` per applicare l'ambiente corretto

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
- Permessi di installazione (sudo) per prerequisiti di sistema

---

## Note di progettazione

- Il modulo è autonomo e non richiede configurazione manuale
- L'installazione SDKMAN! avviene secondo le linee guida ufficiali
- Nessuna modifica globale permanente viene effettuata senza esplicita necessità
- Il watcher opera solo se `.sdkmanrc` è presente

---

## Licenza

Modulo libero e riutilizzabile per scopi personali o professionali.
Modificabile e redistribuibile senza restrizioni.
