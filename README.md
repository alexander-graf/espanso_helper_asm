# Espanso Helper - Assembly Version

Ein einfacher und robuster Helper für Espanso, geschrieben in x86 Assembly für Windows.

## Features

- ✅ **Neue Einträge hinzufügen** - Schnell und einfach
- ✅ **Alle Einträge anzeigen** - Übersicht über bestehende Matches
- ✅ **Ordner öffnen** - Direkter Zugriff auf den Espanso-Ordner
- ✅ **Universeller Pfad** - Funktioniert auf jedem Windows-System
- ✅ **Robuste YAML-Formatierung** - Korrekte Windows-Zeilenenden (CRLF)
- ✅ **Schnelle Bedienung** - Enter drücken für neuen Eintrag

## Installation

### Voraussetzungen

- Windows 10/11
- MASM32 (Microsoft Macro Assembler)
- Espanso installiert

### Build

1. MASM32 installieren (falls noch nicht geschehen)
2. Repository klonen
3. `build.bat` ausführen

```bash
git clone <repository-url>
cd espanso_helper_asm
.\build.bat
```

## Verwendung

### Menü

```
=== ESPANSO HELPER - EINFACHE VERSION ===
1. Neuen Eintrag hinzufügen
2. Alle Einträge anzeigen
3. Ordner öffnen
0. Beenden
Wähle eine Option (1, 2, 3 oder 0):
```

### Schnellstart

- **Enter drücken** = Neuen Eintrag hinzufügen (wie Option 1)
- **1** = Neuen Eintrag hinzufügen
- **2** = Alle Einträge anzeigen
- **3** = Espanso-Ordner im Explorer öffnen
- **0** = Programm beenden

### Beispiel

```
Trigger eingeben: hello
Replace eingeben: Hallo Welt!
Erfolgreich!
```

Erstellt automatisch:
```yaml
  - trigger: hello
    replace: Hallo Welt!
```

## Technische Details

### Datei-Struktur

- **YAML-Datei**: `%APPDATA%\espanso\match\assembler.yml`
- **Format**: UTF-8 ohne BOM, CRLF-Zeilenenden
- **Struktur**: Standard Espanso YAML-Format

### Besonderheiten

- **Universeller Pfad**: Verwendet `%APPDATA%` für Systemunabhängigkeit
- **Robuste Dateierstellung**: Erstellt Datei automatisch falls nicht vorhanden
- **Korrekte Formatierung**: Kein UTF-8 BOM (verursacht Espanso-Probleme)
- **Windows-kompatibel**: CRLF-Zeilenenden für Espanso

### Assembly-Details

- **Architektur**: x86 (32-bit)
- **Assembler**: MASM32
- **APIs**: Windows API (Kernel32, User32, Shell32)
- **Dateioperationen**: Native Windows-Funktionen

## Troubleshooting

### Espanso erkennt Änderungen nicht

- Programm erstellt korrekte YAML-Dateien
- Espanso lädt automatisch neu
- Falls Probleme: Espanso neu starten

### Build-Fehler

- MASM32 korrekt installiert?
- Alle Include-Pfade korrekt?
- `build.bat` im Projektverzeichnis ausführen

### Pfad-Probleme

- Programm verwendet `%APPDATA%` automatisch
- Funktioniert auf allen Windows-Systemen
- Keine manuellen Pfadanpassungen nötig

## Entwicklung

### Projektstruktur

```
espanso_helper_asm/
├── espanso_helper_simple_final.asm  # Hauptquellcode
├── build.bat                        # Build-Skript
├── README.md                        # Diese Datei
└── .gitignore                       # Git-Ignore
```

### Build-Prozess

1. **Assembler**: `ml /c /coff espanso_helper_simple_final.asm`
2. **Linker**: `link.exe` mit Console-Subsystem
3. **Libraries**: kernel32.lib, user32.lib, masm32.lib, shell32.lib

### Erweiterungen

Das Programm ist modular aufgebaut und kann einfach erweitert werden:
- Neue Menüpunkte hinzufügen
- Zusätzliche YAML-Operationen
- Weitere Dateiformate

## Lizenz

Freie Verwendung für private und kommerzielle Zwecke.

## Credits

Entwickelt in Assembly für maximale Performance und minimale Größe.
Optimiert für Espanso und Windows-Systeme. 