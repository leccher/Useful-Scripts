
# Monitor-EventLog.ps1
# Monitora in tempo reale gli eventi di Windows da un log (default: System)
# Avvio: tasto destro -> Esegui con PowerShell, oppure: powershell -ExecutionPolicy Bypass -File .\Monitor-EventLog.ps1

param(
    [string]$LogName = "System",                    # Altri esempi: "Application", "Security", "Microsoft-Windows-Bluetooth-MTP/Operational"
    [int[]]$Levels = @(2,3,4),                      # 2=Errore, 3=Avviso, 4=Informazioni; aggiungi 1=Critico se vuoi
    [string[]]$ProviderInclude = @(),               # Esempi: "Kernel-PnP","UserPnp","BTHUSB","Bluetooth","USBHUB","PlugPlayManager"
    [int[]]$EventIdInclude = @(),                   # Esempi: 20001 (Bluetooth), 410/420 (PnP), ecc.
    [switch]$NoPopup,                               # Se impostato, non mostra popup: solo console
    [string]$LogToFile = ""                         # Se valorizzato, salva anche su file (es. C:\Temp\EventMonitor.log)
)

Write-Host "🔎 Avvio monitoraggio del log '$LogName'..." -ForegroundColor Cyan

# Costruisci query XML per EventLogWatcher
# Filtra per livelli (se specificati)
$levelFilter = ""
if ($Levels.Count -gt 0) {
    $levelFilter = "(" + (($Levels | ForEach-Object { "System/Level=$_"}) -join " or ") + ")"
}

# Filtra per provider (se specificati)
$providerFilter = ""
if ($ProviderInclude.Count -gt 0) {
    $providerFilter = "(" + ($ProviderInclude | ForEach-Object { "System/Provider[@Name='$_']"} -join " or ") + ")"
}

# Filtra per EventID (se specificati)
$eventIdFilter = ""
if ($EventIdInclude.Count -gt 0) {
    $eventIdFilter = "(" + ($EventIdInclude | ForEach-Object { "System/EventID=$_"} -join " or ") + ")"
}

# Componi il blocco <Select> (usa AND tra i filtri presenti)
$conditions = @()
if ($levelFilter)     { $conditions += $levelFilter }
if ($providerFilter)  { $conditions += $providerFilter }
if ($eventIdFilter)   { $conditions += $eventIdFilter }

$xpath = "*[System"
if ($conditions.Count -gt 0) {
    $xpath += "/" + ($conditions -join " and ")
}
$xpath += "]"

# Crea query per il log indicato
$query = New-Object System.Diagnostics.Eventing.Reader.EventLogQuery(
    $LogName,
    [System.Diagnostics.Eventing.Reader.PathType]::LogName,
    $xpath
)

# Watcher in tempo reale
$watcher = New-Object System.Diagnostics.Eventing.Reader.EventLogWatcher($query)

# Funzione per popup (fallback a console se popup disabilitato)
function Show-EventPopup {
    param($title, $text)
    if ($NoPopup) { return }
    try {
        $wshell = New-Object -ComObject WScript.Shell
        # Icona info (64). Timeout 5s
        $wshell.Popup($text, 5, $title, 64) | Out-Null
    } catch {
        # Se il COM fallisce (esecuzione non interattiva), ignora
    }
}

# Scrittura su file (se richiesto)
function Write-EventFile {
    param($line)
    if (![string]::IsNullOrWhiteSpace($LogToFile)) {
        try {
            Add-Content -LiteralPath $LogToFile -Value $line
        } catch {
            Write-Warning "Impossibile scrivere su file: $LogToFile. Errore: $($_.Exception.Message)"
        }
    }
}

# Azione su ogni evento catturato
$action = {
    param($sender, $e)

    $record = $e.Record
    if (-not $record) { return }

    $time   = $record.TimeCreated
    $prov   = $record.ProviderName
    $id     = $record.Id
    $level  = $record.LevelDisplayName
    $msg    = $null

    try { $msg = $record.FormatDescription() } catch { $msg = "(Nessuna descrizione disponibile)" }

    $header = "[{0}] {1} | ID {2} | Livello: {3}" -f $time, $prov, $id, $level
    Write-Host $header -ForegroundColor Yellow
    Write-Host ($msg) -ForegroundColor Gray
    Write-Host ("-"*80)

    Write-EventFile "$header`n$msg`n$('-'*80)"

    Show-EventPopup -title "Evento Windows: $prov (ID $id)" -text ($msg.Substring(0, [Math]::Min($msg.Length, 400)))
}

# Registra l'handler
$subscription = Register-ObjectEvent -InputObject $watcher -EventName EventRecordWritten -Action $action

# Avvia
$watcher.Enabled = $true
Write-Host "✅ Monitoraggio attivo. Premi Ctrl+C per terminare." -ForegroundColor Green
Write-Host "Suggerimento: per dispositivi, prova i provider: Kernel-PnP, UserPnp, USBHUB, BTHUSB, Bluetooth." -ForegroundColor DarkCyan
Write-Host ("-"*80)

# Attendi eventi
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Pulizia risorse
    $watcher.Enabled = $false
    if ($subscription) { Unregister-Event -SourceIdentifier $subscription.Name }
    $watcher.Dispose()
    Write-Host "🛑 Monitoraggio terminato." -ForegroundColor Red
}
