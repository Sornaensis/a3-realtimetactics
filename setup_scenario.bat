@echo off

set /p directory="Paste name of mission directory in quotations: "

cd %directory%
cd ..

xcopy /s scenario_setup %directory%

mklink /D %directory%\rts RTS_Mode

set /p non="Press enter to exit... "