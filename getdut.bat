@echo off
setlocal EnableDelayedExpansion

set tempdir=getdut_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir%
set pingout=%tempdir%^\pingout.txt
set plinkout1=%tempdir%^\plinkout1.txt
set pcIP=%1
set dutoutfile=%2
if EXIST %dutoutfile% del/Q %dutoutfile% 2>NUL

REM ////////////////////////////////////////////////
set /a dutnum=0
set /a dutall=0
set /a status=0

REM Start getting DUT information ==================
plink.exe -ssh tester@%pcIP% -pw fortinet "cat /var/spool/bit_pro/dut[1-9].json" >%pingout%
plink.exe -ssh tester@%pcIP% -pw fortinet "cat /var/spool/bit_pro/dut1[0-6].json" >>%pingout%

FINDSTR /I "Model" %pingout% >%plinkout1% 2>NUL
set /p model=<%plinkout1%
set model=%model:   "Model" : "=%
set model=%model:",=%
if "%model%"=="" set model=- model info not yet available -

FINDSTR /I \^"SN\^" %pingout% >%plinkout1% 2>NUL
FINDSTR /I /M "running" %pingout% >nul && (set /a status=1)
del/Q %pingout% 
REM echo/
if %status%==0 (
REM echo  NO test running.
REM echo Last known %model% on the rack were:
goto _fin
) 
if %status%==1 (
echo Model  is         %model%>%dutoutfile%
)
REM echo/

for /F "delims=," %%x in (%plinkout1%) do (
set dutinfo=%%x
set /a dutnum= !dutnum! + 1
set /a dutall= !dutall! + 1
set dutinfo=!dutinfo:""=null!
set dutinfo=!dutinfo:"=!
if "!dutinfo:~-4!"=="null" set /a dutall=!dutall! - 1
if !dutnum! LSS 10 echo DUT-!dutnum!  is !dutinfo!>>%dutoutfile%
if !dutnum! GEQ 10 echo DUT-!dutnum! is !dutinfo!>>%dutoutfile%
)

REM echo/
REM if %status%==1 echo Total %model% detected is %dutall%

REM ///////////////////////////////////////////////



:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
REM pause
endlocal