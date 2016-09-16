@echo off

set arg0=%0
for /f %%i in ("%arg0%") do set fname=%%~ni

set helpOpt=false
if "%1"=="?"  set helpOpt=true
if "%1"=="/?" set helpOpt=true
if "%1"=="-?" set helpOpt=true
if "%helpOpt%"=="true" (

echo/
echo Syntax:
echo  %fname% ?             [displays this option list]
REM echo  %fname% {-opt1}{-opt2} [default: runs CHECKRACK with no option]
echo  %fname%       {rack#} [default: runs CHECKRACK with no option; checks everything]
echo  %fname% -c    {rack#} [checks everything ^& runs cfg2time; e.g. %fname% -c j for Rack-J]
echo  %fname% -u    {rack#} [checks everything ^& runs BTCUS update ^& cfg2time]
echo  %fname% /cron {rack#} [checks if BTCUS auto-update is enabled]
echo  %fname% /temp {rack#} [REQUIRES PHP to run; gets temperature of a specific rack]
echo  %fname% /os   {rack#} [checks for supported OS version on a specific rack]
echo  %fname% /hqip {rack#} [checks for suported HQIP version on a specific rack]
echo  %fname% /dut  {rack#} [gets list of DUT on a specific rack]
echo  %fname% /pc   {rack#} [checks linux condition of a specific rack PC]
echo  %fname% /port         [checks port status on a specific switch/rack]
echo  %fname% /run          [gets running status for all racks]
echo  %fname% /alltemp      [REQUIRES PHP; gets temperature on all racks; very slow]
echo  %fname% /log          [opens log file checkrack.log]
goto _end
)

if "%1"=="/log" goto _viewlog
if "%1"=="/LOG" goto _viewlog

set s=cr_folder
if not exist %s% echo/&echo %fname% files not set up correctly. . . aborting now.&goto _end 

if "%1"=="/cron" goto _cron
if "%1"=="/CRON" goto _cron
if "%1"=="/temp" goto _temp
if "%1"=="/TEMP" goto _temp
if "%1"=="/run"  goto _run
if "%1"=="/RUN"  goto _run
if "%1"=="/os"   goto _os
if "%1"=="/OS"   goto _os
if "%1"=="/hqip" goto _hqip
if "%1"=="/HQIP" goto _hqip
if "%1"=="/port" goto _port
if "%1"=="/PORT" goto _port
if "%1"=="/alltemp" goto _alltemp
if "%1"=="/ALLTEMP" goto _alltemp
if "%1"=="/pc"   goto _pc
if "%1"=="/PC"   goto _pc
if "%1"=="/dut"   goto _dut
if "%1"=="/DUT"   goto _dut

%s%\checkrack %1 %2
goto _end

:_cron
%s%\checkcron.bat %2
goto _end

:_temp
%s%\checktemp.bat %2
goto _end

:_run
%s%\checkrun.bat
goto _end

:_os
%s%\checkos.bat %2
goto _end

:_hqip
%s%\checkhqip.bat %2
goto _end

:_port
%s%\checkport.bat
goto _end

:_pc
%s%\checkpc.bat %2
goto _end

:_dut
%s%\checkdut.bat %2
goto _end

:_viewlog
start notepad.exe %appdata%\checkrack.log
goto _endnopause

:_alltemp
%s%\checkalltemp.bat



:_end
echo/
pause
:_endnopause
