@echo off
setlocal

REM Immer die Hauptdatei bauen
set "filename=espanso_helper_simple_final"

REM Assemble
ml /c /coff %filename%.asm
if errorlevel 1 goto :error

REM Link using Microsoft linker
\masm32\bin\link.exe /subsystem:console %filename%.obj \masm32\lib\kernel32.lib \masm32\lib\user32.lib \masm32\lib\masm32.lib /out:%filename%.exe
if errorlevel 1 goto :error

echo Build successful! Starting %filename%.exe...
%filename%.exe
goto :eof

:error
echo Build failed!
exit /b 1 