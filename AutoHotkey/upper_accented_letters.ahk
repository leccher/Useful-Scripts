#Requires AutoHotkey v2.0
; Assicurati di salvare questo file con codifica "UTF-8 con BOM" 
; per visualizzare correttamente i caratteri accentati.

; --- MAIUSCOLE ACCENTATE ---
; CTRL + SHIFT + tasto accentato
^+à::Send("À")
^+è::Send("È")
^+ì::Send("Ì")
^+ò::Send("Ò")
^+ù::Send("Ù")

; --- RIMAPPATURA TASTI ---
; Il tasto apostrofo (') diventa un (apice)
^+'::Send("´")

; Il tasto trattino (-) diventa una tilde (~)
^+-::Send("~")