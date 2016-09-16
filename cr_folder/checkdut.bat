@echo off
echo/&echo/&echo/
echo ^>^>^>^> Get List of DUT on Rack ^<^<^<^<

REM Get input ======================
call getinput.bat %1
set /a x=0
setlocal EnableDelayedExpansion
for /F "tokens=*" %%i in (getinput_dir\getinput_out.txt) do (
   set /a x=x+1
   set VAR!x!=%%i
)

set      logfile=%VAR2%
set enteredvalue=%VAR3%
set     rackname=%VAR4%
set         pcIP=%VAR5%
set      hostnet=%VAR6%
set       nodeid=%VAR7%
set         pdu3=%VAR8%
set          v22=%VAR9%
set        PCcnt=%VAR10%


:_cont

set tempdir=checkdut_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir%
set pingout=%tempdir%^\pingout.txt
set plinkout1=%tempdir%^\plinkout1.txt

REM Check if PC is reachable ======================
REM Start ping test to PC
ping -n 1 %pcIP% > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout%
) || (
  echo PC is not available; skipping PC check !!
  del/Q %pingout%
  goto _fin
)

REM Verify PC hostname ===================
plink.exe -ssh tester@%pcIP% -pw fortinet "hostname|grep '.*'" > %pingout% 2>NUL
set /p hostname=<%pingout%
del/Q %pingout%

cls
if "%rackname%"=="%hostname%" echo/ &echo Rack requested is "%rackname%"
if NOT "%rackname%"=="%hostname%" echo/ &echo Rack requested is "%rackname%"; Actual host name is:"%hostname%"
set rackname=%hostname%

REM ////////////////////////////////////////////////
set /a dutnum=0
set /a dutall=0
set /a status=0



REM ===============================================
REM Check if test is running on rack ==============
plink.exe -ssh tester@%pcIP% -pw fortinet "ps -e|grep FGT" >%pingout%
FINDSTR /C:"FGT_Tester" %pingout% >nul && (
  set status=1
) || (
  REM do nothing
)

if %status%==1 goto _getdutinfo
plink.exe -ssh tester@%pcIP% -pw fortinet "ps -e|grep Burn" >%pingout%
FINDSTR /C:"Burn_Gate" %pingout% >nul && (
  set status=1
) || (
REM Do nothing
)
REM ===============================================


:_getdutinfo
REM Start getting DUT information ==================
plink.exe -ssh tester@%pcIP% -pw fortinet "cat /var/spool/bit_pro/dut[1-9].json" >%pingout%
plink.exe -ssh tester@%pcIP% -pw fortinet "cat /var/spool/bit_pro/dut1[0-6].json" >>%pingout%

FINDSTR /I "Model" %pingout% >%plinkout1% 2>NUL

set /p model=<%plinkout1%
set isBlank=-%model%
set isBlank=%isBlank:~0,3%
set model=%model:   "Model" : "=% 
set model=%model:",=%
if "%model%"=="" set model=[..model info temporarily unavailable..]
if "%model%"=="=%" set model=[..model info temporarily unavailable..]

FINDSTR /I \^"SN\^" %pingout% >%plinkout1% 2>NUL
REM FINDSTR /I /M "running" %pingout% >nul && (set /a status=1)
del/Q %pingout% 
echo/
if %status%==0 (
echo  NO test running.&echo/
echo Last known DUT on the rack were
echo %model%:
set is=was
) 
if %status%==1 (
echo Rack is running with %model% :
set is=is
)
echo/

for /F "delims=," %%x in (%plinkout1%) do (
set dutinfo=%%x
set /a dutnum= !dutnum! + 1
set /a dutall= !dutall! + 1
set dutinfo=!dutinfo:""=null!
set dutinfo=!dutinfo:"=!
if "!dutinfo:~-4!"=="null" set /a dutall=!dutall! - 1
if !dutnum! LSS 10 echo DUT-!dutnum!  %is% !dutinfo!
if !dutnum! GEQ 10 echo DUT-!dutnum! %is% !dutinfo!
)

echo/
if %status%==1 echo Total %model% detected is %dutall%

REM ///////////////////////////////////////////////



:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause
endlocal

REM =================================================
REM 2016-04-07 Modified from checkpc.bat to check which DUT is on the Rack
REM 2015-07-15 Add support for two PC per rack
REM 2015-06-09 Add support for racks T,U,V,W,X and Y


