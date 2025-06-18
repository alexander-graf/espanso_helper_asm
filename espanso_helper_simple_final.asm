.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\masm32.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\masm32.lib

; --- Prototypen ---
validate_yaml_file PROTO
read_single_line_replace PROTO
append_entry_to_file PROTO
read_and_display_entries PROTO
wait_for_key PROTO
write_entry_to_file PROTO
expand_appdata PROTO

.data
    yaml_template db "%APPDATA%\espanso\match\assembler.yml", 0
    yaml_file db 256 dup(0)
    appdata_var db "APPDATA", 0
    espanso_path db "\espanso\match\assembler.yml", 0
    
    menu_title db "=== ESPANSO HELPER - EINFACHE VERSION ===", 13, 10, 0
    menu_option1 db "1. Neuen Eintrag hinzufügen", 13, 10, 0
    menu_option2 db "2. Alle Einträge anzeigen", 13, 10, 0
    menu_option0 db "0. Beenden", 13, 10, 0
    menu_prompt db "Wähle eine Option (1, 2 oder 0): ", 0
    msg_choice db "Deine Wahl: ", 0
    msg_invalid db "Ungültige Eingabe!", 13, 10, 0
    msg_enter_trigger db "Trigger eingeben: ", 0
    msg_enter_replace db "Replace eingeben: ", 0
    msg_success db "Erfolgreich!", 13, 10, 0
    msg_error db "Fehler!", 13, 10, 0
    msg_file_not_found db "Datei nicht gefunden!", 13, 10, 0
    msg_invalid_format db "Ungültiges Dateiformat! 'matches:' fehlt am Anfang.", 13, 10, 0
    msg_file_ok db "Datei ist gültig.", 13, 10, 0
    msg_no_entries db "Keine Einträge gefunden.", 13, 10, 0
    msg_press_key db "Drücke eine Taste zum Fortfahren...", 0
    
    input_buffer db 256 dup(0)
    trigger_buffer db 256 dup(0)
    replace_buffer db 1024 dup(0)
    temp_buffer db 8192 dup(0)
    
    file_handle dd 0
    bytes_read dd 0
    bytes_written dd 0
    
    matches_string db "matches:", 0
    dash_space db "  - ", 0
    trigger_header db "trigger: ", 0
    replace_header db "    replace: ", 0
    crlf db 13, 10, 0
    
    display_header db "=== Alle Einträge ===", 13, 10, 0
    file_error_msg db "Fehler beim Öffnen der Datei.", 13, 10, 0
    file_buffer db 8192 dup(0)

.code
start:
    ; Konsolen-Codepage auf UTF-8 setzen
    invoke SetConsoleOutputCP, 65001
    invoke SetConsoleCP, 65001
    
    ; %APPDATA% erweitern
    invoke expand_appdata
    test eax, eax
    jz exit_program
    
    ; Hauptschleife
main_loop:
    invoke StdOut, addr menu_title
    invoke StdOut, addr menu_option1
    invoke StdOut, addr menu_option2
    invoke StdOut, addr menu_option0
    invoke StdOut, addr menu_prompt
    invoke StdIn, addr input_buffer, 256
    mov al, byte ptr [input_buffer]
    cmp al, 0
    je add_entry
    cmp al, '1'
    je add_entry
    cmp al, '2'
    je show_entries
    cmp al, '0'
    je exit_program
    invoke StdOut, addr msg_invalid
    jmp main_loop

show_entries:
    invoke validate_yaml_file
    test eax, eax
    jz show_entries_error
    invoke read_and_display_entries
    invoke wait_for_key
    jmp main_loop

show_entries_error:
    invoke StdOut, addr msg_error
    invoke wait_for_key
    jmp main_loop

add_entry:
    invoke validate_yaml_file
    test eax, eax
    jz add_entry_error
    invoke StdOut, addr msg_enter_trigger
    invoke StdIn, addr trigger_buffer, 256
    invoke StdOut, addr msg_enter_replace
    invoke read_single_line_replace
    invoke append_entry_to_file
    test eax, eax
    jz add_entry_error
    invoke StdOut, addr msg_success
    jmp main_loop

add_entry_error:
    invoke StdOut, addr msg_error
    jmp main_loop

exit_program:
    invoke ExitProcess, 0

; --- Einzelzeichen-Ausgabe ---
; putchar wird entfernt

; --- Auf Taste warten ---
wait_for_key PROC
    invoke StdOut, addr msg_press_key
    invoke StdIn, addr input_buffer, 256
    ret
wait_for_key ENDP

; --- YAML-Datei validieren ---
validate_yaml_file PROC
    invoke CreateFile, addr yaml_file, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je create_new_file
    
    invoke ReadFile, file_handle, addr temp_buffer, 8192, addr bytes_read, NULL
    test eax, eax
    jz validate_fail
    
    invoke CloseHandle, file_handle
    
    ; Prüfen ob Datei leer ist
    cmp bytes_read, 0
    je create_new_file
    
    ; Prüfen ob "matches:" am Anfang steht (nach möglichem UTF-8 BOM)
    mov esi, offset temp_buffer
    
    ; Prüfen ob UTF-8 BOM vorhanden ist
    cmp byte ptr [esi], 0EFh
    jne check_matches_direct
    cmp byte ptr [esi+1], 0BBh
    jne check_matches_direct
    cmp byte ptr [esi+2], 0BFh
    jne check_matches_direct
    
    ; UTF-8 BOM vorhanden, "matches:" nach BOM suchen
    add esi, 3
    
check_matches_direct:
    mov edi, offset matches_string
    mov ecx, 8  ; Länge von "matches:"
    repe cmpsb
    jne create_new_file  ; Wenn kein "matches:" gefunden, neue Datei erstellen
    
    mov eax, 1
    ret

create_new_file:
    ; Neue Datei mit "matches:" erstellen (ohne UTF-8 BOM)
    invoke CreateFile, addr yaml_file, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je validate_fail
    
    ; "matches:" schreiben
    invoke WriteFile, file_handle, addr matches_string, 8, addr bytes_written, NULL
    test eax, eax
    jz validate_fail
    
    ; LF nach "matches:"
    invoke WriteFile, file_handle, addr crlf, 2, addr bytes_written, NULL
    test eax, eax
    jz validate_fail
    
    ; Datei schließen
    invoke CloseHandle, file_handle
    
    mov eax, 1
    ret

validate_fail:
    mov eax, 0
    ret

validate_yaml_file ENDP

; --- Einzeiliges Replace lesen ---
read_single_line_replace PROC
    invoke StdIn, addr replace_buffer, 1024
    ret
read_single_line_replace ENDP

; --- Einträge lesen und anzeigen ---
read_and_display_entries PROC
    invoke CreateFile, addr yaml_file, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je display_fail
    
    invoke ReadFile, file_handle, addr file_buffer, 8192, addr bytes_read, NULL
    test eax, eax
    jz display_fail
    
    invoke CloseHandle, file_handle
    
    ; Dateiinhalt anzeigen
    invoke StdOut, addr file_buffer
    ret

display_fail:
    mov eax, 0
    ret
read_and_display_entries ENDP

; --- Eintrag zur Datei hinzufügen ---
append_entry_to_file PROC
    ; Datei öffnen (append)
    invoke CreateFile, addr yaml_file, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je append_fail
    
    ; Datei-Pointer ans Ende setzen
    invoke SetFilePointer, file_handle, 0, NULL, FILE_END
    
    ; Neuen Eintrag schreiben
    invoke write_entry_to_file
    test eax, eax
    jz append_fail
    
    ; Datei schließen
    invoke CloseHandle, file_handle
    
    mov eax, 1
    ret

append_fail:
    mov eax, 0
    ret

append_entry_to_file ENDP

; --- Eintrag in Datei schreiben ---
write_entry_to_file PROC
    ; Trigger schreiben
    invoke WriteFile, file_handle, addr dash_space, 4, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    invoke WriteFile, file_handle, addr trigger_header, 9, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    invoke lstrlen, addr trigger_buffer
    mov ecx, eax
    invoke WriteFile, file_handle, addr trigger_buffer, ecx, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; LF
    invoke WriteFile, file_handle, addr crlf, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Replace schreiben
    invoke WriteFile, file_handle, addr replace_header, 13, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    invoke lstrlen, addr replace_buffer
    mov ecx, eax
    invoke WriteFile, file_handle, addr replace_buffer, ecx, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; LF
    invoke WriteFile, file_handle, addr crlf, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    mov eax, 1
    ret
write_fail:
    mov eax, 0
    ret
write_entry_to_file ENDP

; --- %APPDATA% erweitern ---
expand_appdata PROC
    ; %APPDATA% Umgebungsvariable abrufen
    invoke GetEnvironmentVariable, addr appdata_var, addr yaml_file, 256
    test eax, eax
    jz expand_fail
    
    ; Pfad mit "espanso\match\assembler.yml" erweitern
    invoke lstrcat, addr yaml_file, addr espanso_path
    test eax, eax
    jz expand_fail
    
    mov eax, 1
    ret
expand_fail:
    mov eax, 0
    ret
expand_appdata ENDP

end start 