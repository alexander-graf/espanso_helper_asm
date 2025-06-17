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

.data
    ; Dateipfad zur YAML-Datei
    yaml_file db "C:\Users\crazykungfu\AppData\Roaming\espanso\match\assembler.yml", 0
    
    ; Menüoptionen
    menu_title db "=== ESPANSO HELPER - ASSEMBLER VERSION ===", 13, 10, 0
    menu_option1 db "1. Alle Einträge anzeigen", 13, 10, 0
    menu_option2 db "2. Neuen Eintrag hinzufügen", 13, 10, 0
    menu_option3 db "3. Eintrag bearbeiten", 13, 10, 0
    menu_option4 db "4. Eintrag löschen", 13, 10, 0
    menu_option5 db "5. Datei validieren", 13, 10, 0
    menu_option6 db "6. Beenden", 13, 10, 0
    menu_prompt db "Wähle eine Option (1-6): ", 0
    
    ; Nachrichten
    msg_choice db "Deine Wahl: ", 0
    msg_invalid db "Ungültige Eingabe!", 13, 10, 0
    msg_enter_trigger db "Trigger eingeben: ", 0
    msg_enter_replace db "Replace eingeben (Ende mit 'END' in neuer Zeile): ", 13, 10, 0
    msg_enter_index db "Index des zu bearbeitenden Eintrags eingeben: ", 0
    msg_enter_delete db "Index des zu löschenden Eintrags eingeben: ", 0
    msg_success db "Erfolgreich!", 13, 10, 0
    msg_error db "Fehler!", 13, 10, 0
    msg_file_not_found db "Datei nicht gefunden!", 13, 10, 0
    msg_invalid_format db "Ungültiges Dateiformat! 'matches:' fehlt am Anfang.", 13, 10, 0
    msg_file_ok db "Datei ist gültig.", 13, 10, 0
    msg_no_entries db "Keine Einträge gefunden.", 13, 10, 0
    msg_press_key db "Drücke eine Taste zum Fortfahren...", 0
    
    ; Buffer für Eingaben
    input_buffer db 256 dup(0)
    trigger_buffer db 256 dup(0)
    replace_buffer db 2048 dup(0)
    temp_buffer db 8192 dup(0)
    output_buffer db 256 dup(0)
    
    ; Datei-Handles
    file_handle dd 0
    temp_handle dd 0
    
    ; Variablen
    bytes_read dd 0
    bytes_written dd 0
    file_size dd 0
    current_index dd 0
    entry_count dd 0
    target_index dd 0

.code
start:
    ; Hauptschleife
main_loop:
    ; Menü anzeigen
    invoke StdOut, addr menu_title
    invoke StdOut, addr menu_option1
    invoke StdOut, addr menu_option2
    invoke StdOut, addr menu_option3
    invoke StdOut, addr menu_option4
    invoke StdOut, addr menu_option5
    invoke StdOut, addr menu_option6
    invoke StdOut, addr menu_prompt
    
    ; Benutzereingabe lesen
    invoke StdIn, addr input_buffer, 256
    
    ; Eingabe verarbeiten
    mov al, [input_buffer]
    cmp al, '1'
    je show_entries
    cmp al, '2'
    je add_entry
    cmp al, '3'
    je edit_entry
    cmp al, '4'
    je delete_entry
    cmp al, '5'
    je validate_file
    cmp al, '6'
    je exit_program
    
    ; Ungültige Eingabe
    invoke StdOut, addr msg_invalid
    jmp main_loop

; Funktion: Alle Einträge anzeigen
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

; Funktion: Neuen Eintrag hinzufügen
add_entry:
    invoke validate_yaml_file
    test eax, eax
    jz add_entry_error
    
    ; Trigger eingeben
    invoke StdOut, addr msg_enter_trigger
    invoke StdIn, addr trigger_buffer, 256
    
    ; Replace eingeben
    invoke StdOut, addr msg_enter_replace
    invoke read_multiline_replace
    
    ; Eintrag zur Datei hinzufügen
    invoke append_entry_to_file
    test eax, eax
    jz add_entry_error
    
    invoke StdOut, addr msg_success
    jmp main_loop

add_entry_error:
    invoke StdOut, addr msg_error
    jmp main_loop

; Funktion: Eintrag bearbeiten
edit_entry:
    invoke validate_yaml_file
    test eax, eax
    jz edit_entry_error
    
    ; Erst alle Einträge anzeigen
    invoke read_and_display_entries
    
    ; Index eingeben
    invoke StdOut, addr msg_enter_index
    invoke StdIn, addr input_buffer, 256
    
    ; Index konvertieren
    invoke atodw, addr input_buffer
    mov target_index, eax
    
    ; Neuen Trigger eingeben
    invoke StdOut, addr msg_enter_trigger
    invoke StdIn, addr trigger_buffer, 256
    
    ; Neues Replace eingeben
    invoke StdOut, addr msg_enter_replace
    invoke read_multiline_replace
    
    ; Eintrag bearbeiten
    invoke edit_entry_in_file
    test eax, eax
    jz edit_entry_error
    
    invoke StdOut, addr msg_success
    jmp main_loop

edit_entry_error:
    invoke StdOut, addr msg_error
    jmp main_loop

; Funktion: Eintrag löschen
delete_entry:
    invoke validate_yaml_file
    test eax, eax
    jz delete_entry_error
    
    ; Erst alle Einträge anzeigen
    invoke read_and_display_entries
    
    ; Index eingeben
    invoke StdOut, addr msg_enter_delete
    invoke StdIn, addr input_buffer, 256
    
    ; Index konvertieren
    invoke atodw, addr input_buffer
    mov target_index, eax
    
    ; Eintrag löschen
    invoke delete_entry_from_file
    test eax, eax
    jz delete_entry_error
    
    invoke StdOut, addr msg_success
    jmp main_loop

delete_entry_error:
    invoke StdOut, addr msg_error
    jmp main_loop

; Funktion: Datei validieren
validate_file:
    invoke validate_yaml_file
    test eax, eax
    jz validate_error
    
    invoke StdOut, addr msg_file_ok
    invoke wait_for_key
    jmp main_loop

validate_error:
    invoke StdOut, addr msg_invalid_format
    invoke wait_for_key
    jmp main_loop

; Programm beenden
exit_program:
    invoke ExitProcess, 0

; Funktion: Auf Taste warten
wait_for_key PROC
    invoke StdOut, addr msg_press_key
    invoke StdIn, addr input_buffer, 256
    ret
wait_for_key ENDP

; Funktion: YAML-Datei validieren
validate_yaml_file PROC
    ; Datei öffnen
    invoke CreateFile, addr yaml_file, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je validate_fail
    
    ; Datei lesen
    invoke ReadFile, file_handle, addr temp_buffer, 8192, addr bytes_read, NULL
    test eax, eax
    jz validate_fail
    
    ; Datei schließen
    invoke CloseHandle, file_handle
    
    ; Prüfen ob "matches:" am Anfang steht
    mov esi, offset temp_buffer
    mov edi, offset matches_string
    mov ecx, 8  ; Länge von "matches:"
    repe cmpsb
    jne validate_fail
    
    mov eax, 1  ; Erfolg
    ret

validate_fail:
    mov eax, 0  ; Fehler
    ret

matches_string db "matches:", 0

validate_yaml_file ENDP

; Funktion: Mehrzeiliges Replace lesen
read_multiline_replace PROC
    mov edi, offset replace_buffer
    mov ecx, 0  ; Zeichenzähler
    
read_line:
    invoke StdIn, addr input_buffer, 256
    
    ; Prüfen ob "END" eingegeben wurde
    mov esi, offset input_buffer
    cmp byte ptr [esi], 'E'
    jne not_end
    cmp byte ptr [esi+1], 'N'
    jne not_end
    cmp byte ptr [esi+2], 'D'
    jne not_end
    cmp byte ptr [esi+3], 0
    je read_done
    
not_end:
    ; Zeile in Buffer kopieren
    mov esi, offset input_buffer
    mov al, [esi]
    cmp al, 0
    je read_done
    
copy_line:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    inc ecx
    cmp al, 0
    jne copy_line
    
    ; Neue Zeile hinzufügen
    mov byte ptr [edi-1], 13
    mov byte ptr [edi], 10
    add edi, 2
    add ecx, 2
    
    jmp read_line

read_done:
    mov byte ptr [edi], 0
    ret

read_multiline_replace ENDP

; Funktion: Einträge lesen und anzeigen
read_and_display_entries PROC
    ; Datei öffnen
    invoke CreateFile, addr yaml_file, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je display_fail
    
    ; Datei lesen
    invoke ReadFile, file_handle, addr temp_buffer, 8192, addr bytes_read, NULL
    test eax, eax
    jz display_fail
    
    ; Datei schließen
    invoke CloseHandle, file_handle
    
    ; Einträge parsen und anzeigen
    invoke parse_and_display_yaml
    ret

display_fail:
    mov eax, 0
    ret

read_and_display_entries ENDP

; Funktion: YAML parsen und anzeigen
parse_and_display_yaml PROC
    mov esi, offset temp_buffer
    mov ecx, 0  ; Eintragszähler
    
    ; "matches:" überspringen
    add esi, 8
    
parse_loop:
    ; Nach Trigger suchen
    mov al, [esi]
    cmp al, 0
    je parse_done
    
    cmp al, '-'
    jne next_char
    
    ; Trigger gefunden
    inc ecx
    push ecx
    push esi
    
    ; Index ausgeben
    invoke dwtoa, ecx, addr output_buffer
    invoke StdOut, addr output_buffer
    invoke StdOut, addr dot_space
    
    ; Trigger ausgeben
    add esi, 2  ; "- " überspringen
    invoke output_until_newline, esi
    
    ; Nach "replace:" suchen
    invoke find_replace_section, esi
    test eax, eax
    jz parse_next
    
    ; Replace ausgeben
    invoke StdOut, addr replace_label
    invoke output_replace_content, eax
    
    pop esi
    pop ecx
    
next_char:
    inc esi
    jmp parse_loop

parse_done:
    cmp ecx, 0
    jne parse_exit
    invoke StdOut, addr msg_no_entries

parse_exit:
    ret

dot_space db ". ", 0
replace_label db "  Replace: ", 0

parse_and_display_yaml ENDP

; Hilfsfunktionen
output_until_newline PROC uses esi
    mov esi, [esp+4]
    
output_char:
    mov al, [esi]
    cmp al, 13
    je output_done
    cmp al, 10
    je output_done
    cmp al, 0
    je output_done
    
    invoke putchar, eax
    inc esi
    jmp output_char

output_done:
    invoke StdOut, addr newline
    ret 4

newline db 13, 10, 0

output_until_newline ENDP

find_replace_section PROC uses esi
    mov esi, [esp+4]
    
find_replace:
    mov al, [esi]
    cmp al, 0
    je find_fail
    
    cmp al, 'r'
    jne find_next
    
    ; "replace:" prüfen
    cmp byte ptr [esi+1], 'e'
    jne find_next
    cmp byte ptr [esi+2], 'p'
    jne find_next
    cmp byte ptr [esi+3], 'l'
    jne find_next
    cmp byte ptr [esi+4], 'a'
    jne find_next
    cmp byte ptr [esi+5], 'c'
    jne find_next
    cmp byte ptr [esi+6], 'e'
    jne find_next
    cmp byte ptr [esi+7], ':'
    jne find_next
    
    ; Replace-Sektion gefunden
    add esi, 8
    mov eax, esi
    ret 4

find_next:
    inc esi
    jmp find_replace

find_fail:
    mov eax, 0
    ret 4

find_replace_section ENDP

output_replace_content PROC uses esi
    mov esi, [esp+4]
    
    ; Leerzeichen überspringen
skip_spaces:
    mov al, [esi]
    cmp al, ' '
    jne output_start
    inc esi
    jmp skip_spaces

output_start:
    ; Replace-Inhalt ausgeben
    invoke output_until_newline, esi
    ret 4

output_replace_content ENDP

; Funktion: Eintrag zur Datei hinzufügen
append_entry_to_file PROC
    ; Datei öffnen (append)
    invoke CreateFile, addr yaml_file, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
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

; Funktion: Eintrag in Datei schreiben
write_entry_to_file PROC
    ; Trigger schreiben
    invoke WriteFile, file_handle, addr dash_space, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    invoke WriteFile, file_handle, addr trigger_buffer, 256, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Neue Zeile
    invoke WriteFile, file_handle, addr newline, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; "replace:" schreiben
    invoke WriteFile, file_handle, addr replace_header, 9, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Replace-Inhalt schreiben
    invoke WriteFile, file_handle, addr replace_buffer, 2048, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Neue Zeile
    invoke WriteFile, file_handle, addr newline, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    mov eax, 1
    ret

write_fail:
    mov eax, 0
    ret

dash_space db "- ", 0
replace_header db "  replace:", 0

write_entry_to_file ENDP

; Funktion: Eintrag in Datei bearbeiten
edit_entry_in_file PROC
    ; Temporäre Datei erstellen
    invoke CreateFile, addr temp_file, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov temp_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je edit_fail
    
    ; Original-Datei öffnen
    invoke CreateFile, addr yaml_file, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je edit_fail
    
    ; Datei kopieren und Eintrag ersetzen
    invoke copy_and_replace_entry
    test eax, eax
    jz edit_fail
    
    ; Dateien schließen
    invoke CloseHandle, file_handle
    invoke CloseHandle, temp_handle
    
    ; Temporäre Datei umbenennen
    invoke DeleteFile, addr yaml_file
    invoke MoveFile, addr temp_file, addr yaml_file
    
    mov eax, 1
    ret

edit_fail:
    mov eax, 0
    ret

temp_file db "temp_assembler.yml", 0

edit_entry_in_file ENDP

; Funktion: Eintrag aus Datei löschen
delete_entry_from_file PROC
    ; Temporäre Datei erstellen
    invoke CreateFile, addr temp_file, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov temp_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je delete_fail
    
    ; Original-Datei öffnen
    invoke CreateFile, addr yaml_file, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je delete_fail
    
    ; Datei kopieren und Eintrag überspringen
    invoke copy_and_skip_entry
    test eax, eax
    jz delete_fail
    
    ; Dateien schließen
    invoke CloseHandle, file_handle
    invoke CloseHandle, temp_handle
    
    ; Temporäre Datei umbenennen
    invoke DeleteFile, addr yaml_file
    invoke MoveFile, addr temp_file, addr yaml_file
    
    mov eax, 1
    ret

delete_fail:
    mov eax, 0
    ret

delete_entry_from_file ENDP

; Funktion: Datei kopieren und Eintrag ersetzen
copy_and_replace_entry PROC
    ; "matches:" schreiben
    invoke WriteFile, temp_handle, addr matches_string, 8, addr bytes_written, NULL
    test eax, eax
    jz copy_fail
    
    ; Datei lesen
    invoke ReadFile, file_handle, addr temp_buffer, 8192, addr bytes_read, NULL
    test eax, eax
    jz copy_fail
    
    ; Datei parsen und kopieren
    mov esi, offset temp_buffer
    add esi, 8  ; "matches:" überspringen
    mov ecx, 0  ; Eintragszähler
    
copy_loop:
    mov al, [esi]
    cmp al, 0
    je copy_done
    
    cmp al, '-'
    jne copy_char
    
    ; Eintrag gefunden
    inc ecx
    cmp ecx, target_index
    je replace_entry
    
    ; Eintrag normal kopieren
    invoke copy_entry_to_temp, esi
    jmp next_entry
    
replace_entry:
    ; Neuen Eintrag schreiben
    invoke write_new_entry_to_temp
    ; Alten Eintrag überspringen
    invoke skip_entry, esi
    mov esi, eax
    
next_entry:
    jmp copy_loop
    
copy_char:
    inc esi
    jmp copy_loop

copy_done:
    mov eax, 1
    ret

copy_fail:
    mov eax, 0
    ret

copy_and_replace_entry ENDP

; Funktion: Datei kopieren und Eintrag überspringen
copy_and_skip_entry PROC
    ; "matches:" schreiben
    invoke WriteFile, temp_handle, addr matches_string, 8, addr bytes_written, NULL
    test eax, eax
    jz copy_fail
    
    ; Datei lesen
    invoke ReadFile, file_handle, addr temp_buffer, 8192, addr bytes_read, NULL
    test eax, eax
    jz copy_fail
    
    ; Datei parsen und kopieren
    mov esi, offset temp_buffer
    add esi, 8  ; "matches:" überspringen
    mov ecx, 0  ; Eintragszähler
    
copy_loop:
    mov al, [esi]
    cmp al, 0
    je copy_done
    
    cmp al, '-'
    jne copy_char
    
    ; Eintrag gefunden
    inc ecx
    cmp ecx, target_index
    je skip_this_entry
    
    ; Eintrag normal kopieren
    invoke copy_entry_to_temp, esi
    jmp next_entry
    
skip_this_entry:
    ; Eintrag überspringen
    invoke skip_entry, esi
    mov esi, eax
    
next_entry:
    jmp copy_loop
    
copy_char:
    inc esi
    jmp copy_loop

copy_done:
    mov eax, 1
    ret

copy_fail:
    mov eax, 0
    ret

copy_and_skip_entry ENDP

; Hilfsfunktionen für Dateioperationen
copy_entry_to_temp PROC uses esi
    mov esi, [esp+4]
    
    ; Eintrag bis zum nächsten "-" oder Ende kopieren
copy_loop:
    mov al, [esi]
    cmp al, 0
    je copy_done
    
    cmp al, '-'
    je copy_done
    
    ; Zeichen schreiben
    invoke WriteFile, temp_handle, esi, 1, addr bytes_written, NULL
    test eax, eax
    jz copy_fail
    
    inc esi
    jmp copy_loop

copy_done:
    mov eax, esi
    ret 4

copy_fail:
    mov eax, 0
    ret 4

copy_entry_to_temp ENDP

write_new_entry_to_temp PROC
    ; Trigger schreiben
    invoke WriteFile, temp_handle, addr dash_space, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    invoke WriteFile, temp_handle, addr trigger_buffer, 256, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Neue Zeile
    invoke WriteFile, temp_handle, addr newline, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; "replace:" schreiben
    invoke WriteFile, temp_handle, addr replace_header, 9, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Replace-Inhalt schreiben
    invoke WriteFile, temp_handle, addr replace_buffer, 2048, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    ; Neue Zeile
    invoke WriteFile, temp_handle, addr newline, 2, addr bytes_written, NULL
    test eax, eax
    jz write_fail
    
    mov eax, 1
    ret

write_fail:
    mov eax, 0
    ret

write_new_entry_to_temp ENDP

skip_entry PROC uses esi
    mov esi, [esp+4]
    
    ; Eintrag bis zum nächsten "-" oder Ende überspringen
skip_loop:
    mov al, [esi]
    cmp al, 0
    je skip_done
    
    cmp al, '-'
    je skip_done
    
    inc esi
    jmp skip_loop

skip_done:
    mov eax, esi
    ret 4

skip_entry ENDP

end start 