
# my_powershell_profile_scripts.ps1

## Panoramica

Il file **`my_powershell_profile_scripts.ps1`** è uno script di profilo PowerShell progettato per creare un ambiente di lavoro **modulare, estendibile ed event‑driven**.

Lo script viene eseguito automaticamente all’avvio di PowerShell (in base al profilo selezionato) e fornisce:

- caricamento automatico di moduli PowerShell personalizzati
- intercettazione del cambio directory
- delega ai moduli di azioni specifiche per cartella (es. attivazione venv Python)
- un meccanismo sicuro per disabilitare temporaneamente i watcher

---

## Profili PowerShell

PowerShell supporta diversi profili, che determinano **quando** e **per chi** lo script viene eseguito.

Percorsi principali:

- **AllUsersAllHosts**  
  `C:\Program Files\PowerShell\7\profile.ps1`

- **AllUsersCurrentHost**  
  `C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1`

- **CurrentUserAllHosts**  
  `C:\Users\YOUR_USER\Documents\PowerShell\profile.ps1`

- **CurrentUserCurrentHost**  
  `C:\Users\YOUR_USER\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

Per verificare i profili disponibili:

```powershell
$PROFILE | Select-Object *
```

---

## Creazione del profilo

Se il file di profilo non esiste, può essere creato con:

```powershell
New-Item -ItemType File -Path $PROFILE -Force
```

Oppure per un profilo specifico:

```powershell
New-Item -ItemType File -Path "$env:USERPROFILE\Documents\PowerShell\Profile.ps1" -Force
```

---

## Gestione dei Moduli PowerShell
Questo progetto include un sistema di caricamento e scaricamento automatico dei moduli PowerShell, basato sulle dipendenze dichiarate nei file .psd1 e sullo stato reale della sessione.
L’obiettivo è:

- caricare e scaricare tutti i moduli presenti nella cartella modules
- senza dover elencare manualmente i moduli
- rispettando le dipendenze tra moduli
- evitando ordini di caricamento errati o stati incoerenti


### Caricamento dei moduli (Load-MyPowerShellModules)
La funzione `Load-MyPowerShellModules` carica automaticamente tutti i moduli presenti nella cartella `modules`, risolvendo le dipendenze in modo incrementale e basandosi solo sullo stato reale della sessione PowerShell.

**Come funziona**

- Individua tutti i moduli presenti nella cartella modules
- Verifica quali moduli sono già caricati nella sessione

Carica solo i moduli:

- non ancora caricati
- le cui dipendenze (RequiredModules nel .psd1) sono già soddisfatte


Ripete il processo finché:

- tutti i moduli sono caricati ✅
- oppure non è più possibile fare progressi (dipendenze mancanti o cicliche) ⚠️


Questo approccio evita:

- caricamenti in ordine casuale
- errori dovuti a dipendenze non ancora disponibili
- assunzioni su uno stato iniziale “pulito” della sessione

Codici di ritorno

- Code = 0 → tutti i moduli sono stati caricati correttamente
- Code > 0 → caricamento parziale (alcuni moduli non caricabili)
- Code < 0 → errore reale (es. cartella moduli mancante)

Esempio d’uso
```PowerShell
Load-MyPowerShellModules
```

### Scaricamento dei moduli (Unload-MyPowerShellModules)
La funzione Unload-MyPowerShellModules scarica i moduli caricati in modo sicuro, evitando di rimuovere moduli ancora necessari ad altri.

Come funziona

- Individua tutti i moduli gestiti (presenti nella cartella modules)
- Verifica quali moduli sono effettivamente caricati nella sessione

Scarica solo i moduli che:

- non sono richiesti da nessun altro modulo ancora caricato


Ripete il processo finché:

- tutti i moduli sono stati scaricati ✅
- oppure rimangono moduli che non è possibile scaricare senza rompere dipendenze ⚠️

Lo scaricamento avviene quindi in ordine inverso rispetto alle dipendenze, anche se l’ordine di caricamento originale non è noto.

Codici di ritorno

Code = 0 → tutti i moduli sono stati scaricati correttamente
Code > 0 → scaricamento parziale (dipendenze inverse ancora attive)
Code < 0 → errore reale

Esempio d’uso
```PowerShell
Unload-MyPowerShellModules
```

À## Modalità -DryRun (simulazione)
Sia `Load-MyPowerShellModules` che `Unload-MyPowerShellModules` supportano la modalità `-DryRun`.

La modalità DryRun consente di simulare completamente il caricamento o lo scaricamento dei moduli, senza modificare in alcun modo la sessione PowerShell.

Cosa fa -DryRun

- ✅ esegue tutta la logica di risoluzione delle dipendenze
- ✅ verifica lo stato reale dei moduli (Get-Module)
- ✅ mostra esattamente cosa verrebbe caricato o scaricato
- ❌ NON chiama Import-Module
- ❌ NON chiama Remove-Module
- ❌ NON modifica lo stato della sessione

La modalità DryRun restituisce gli stessi codici di ritorno dell’esecuzione reale, rendendola ideale per:

- test
- debug
- validazione delle dipendenze
- uso in script automatici o CI

#### Esempi d’uso

Simulazione del caricamento:
```PowerShell
Load-MyPowerShellModules -DryRun
```

Simulazione dello scaricamento:
```PowerShell
Unload-MyPowerShellModules -DryRun
```

Esempio di output tipico:
```Plain Text
[DRY-RUN] Would load module LocalizationHelperModule
[DRY-RUN] Would load module LevelBasedLogginModule
[DRY-RUN] Would load module MyEnvironmentManagerModule
```

### Note sulle dipendenze

- Le dipendenze tra moduli devono essere dichiarate esclusivamente nel campo **RequiredModules** dei file `.psd1`
- Il sistema non utilizza ordini predefiniti o liste manuali
- Tutte le decisioni sono basate sullo stato reale della sessione PowerShell

Questo garantisce un comportamento prevedibile anche in:

- sessioni non pulite
- reload parziali
- ambienti di sviluppo

---

## Directory Watcher

È implementata una funzione centrale:

```powershell
Invoke-DirectoryWatcher
```

Funzioni principali:

- traccia l'ultima directory visitata
- rileva il cambio directory
- cerca dinamicamente funzioni che rispettano la convenzione:

```
*:__ModuleDirectoryWatcher
```

- invoca ciascun watcher trovato
- isola errori provenienti dai moduli

Ogni modulo può quindi reagire in modo autonomo al cambio directory.

---

## Disabilitazione dinamica dei watcher

È possibile disabilitare temporaneamente i watcher impostando la variabile di ambiente:

```powershell
$env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING = 1
```

Alla successiva esecuzione di `Set-Location`:

- i watcher non verranno eseguiti
- la variabile verrà rimossa automaticamente

Questo approccio è utile per script automatici o operazioni batch.

---

## Override di Set-Location

Per intercettare in modo affidabile il cambio di directory, lo script ridefinisce la funzione:

```powershell
Set-Location
```

Il wrapper:

- chiama il comando originale `Microsoft.PowerShell.Management\Set-Location`
- gestisce errori di percorso
- invoca `Invoke-DirectoryWatcher` solo quando appropriato

Questo approccio è preferibile all’override di `prompt`, poiché `Set-Location` rappresenta semanticamente l’evento di cambio directory.

---

## Vantaggi architetturali

- Nessun registry centrale
- Convenzione invece di configurazione
- Moduli completamente disaccoppiati
- Comportamento coerente tra Bash e PowerShell
- Framework facilmente estendibile

---

## Licenza

Lo script è liberamente utilizzabile, modificabile e redistribuibile
per uso personale o professionale.
