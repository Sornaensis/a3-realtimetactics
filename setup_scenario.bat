@echo off

set /p directory="Paste name of mission directory in quotations: "

cd %directory%
cd ..

mklink /D %directory%\rts %directory%\..\RTS_Mode
mklink /D %directory%\scen_fw %directory%\..\Scenario_FW

set /p non="Press enter to exit... "