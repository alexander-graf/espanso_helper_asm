@echo off
setlocal

REM Immer die Hauptdatei bauen
set "filename=espanso_helper_simple_final"

REM Assemble
ml /c /coff %filename%.asm
if errorlevel 1 goto :error

REM Compile resources (if icon exists)
if exist rabbit.ico (
    rc espanso_helper.rc
    if errorlevel 1 goto :error
    set "resource_file=espanso_helper.res"
) else (
    set "resource_file="
)

REM Link using Microsoft linker
if defined resource_file (
    \masm32\bin\link.exe /subsystem:console %filename%.obj %resource_file% \masm32\lib\kernel32.lib \masm32\lib\user32.lib \masm32\lib\masm32.lib \masm32\lib\shell32.lib /out:%filename%.exe
) else (
    \masm32\bin\link.exe /subsystem:console %filename%.obj \masm32\lib\kernel32.lib \masm32\lib\user32.lib \masm32\lib\masm32.lib \masm32\lib\shell32.lib /out:%filename%.exe
)
if errorlevel 1 goto :error

echo Build successful! Starting %filename%.exe...
%filename%.exe
goto :eof

:error
echo Build failed!
exit /b 1 