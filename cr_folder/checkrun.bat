@echo off
REM tempdir     =temporary folder for runtime files
REM tlog        =temporary log file
REM rlog        =output log file to store results
REM pingout     =temporary file to store ping status
REM plinkout    =temporary file to store plink output
REM plinkout1   =temporary file to store plink output
REM host_list203=list of racks in room A
REM host_list204=list of racks in room C

if "%1"=="?" (
echo/
echo Syntax: %0           [no option required]
echo         %0 ?         [displays ^(this^) help list]
echo This program displays a list of racks and their running status
goto _fin
)

REM Create temporary folder
set tempdir=checkrun_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir% 

setlocal EnableDelayedExpansion

set tlog=%tempdir%^\templog.log
set pingout=%tempdir%^\pingout.txt
set plinkout=%tempdir%^\plinkout.txt
set plinkout1=%tempdir%^\plinkout1.txt
-------------------

REM ---set tlog=templog.log
REM set rlog=checkrun.log
set rlog=checkrack.log
set noskip=0
REM rack notation is: Rack_nodeip_racksequence e.g. USIQC-A-B is 00A641
REM rack notation for RMA racks : not supported
set host_list203=(00A641,00B651,00C661,00E681,00F691,00G701,00H711)
set host_list204=(00J731,00K741,00L751,00M761,00N771,00O781,00P791,00Q801,00R811,00S821)
set host_cart=(00U841,00V851,00W861,00X871,00Y881,00Z891,0AA901,0AB911,0AC921,0AF951,0AG961)
set checkroom=203
set rmup=0
set rm203up=0
set rm204up=0
set cartup=0

CLS 
REM echo/ > %tlog%
echo === %date% %time% ============================= > %tlog%
echo Checking Rack Running State; this will take a few minutes . . . 

REM --- First, check BTCUS server ---------
set btcusserver=172.30.147.41
 ping -n 1 !btcusserver! > %pingout%
 ping -n 1 !btcusserver! > %pingout%
 FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout% &set noskip=1
) || (
 echo -- W A R N I N G -- BITCUS SERVER is OFFLINE ^^!^^!>> %tlog%
 del/Q %pingout% &set noskip=0
)
REM --- Finished checking BTCUS server ---------

set host_list=%host_list203%
:_starthere

for %%x in %host_list% do ( 
set host=%%x
set rackname=!host:~1,1!
if NOT !rackname!==0 set rackname=!host:~1,2!&set suffix=2
if !rackname!==0 set rackname=!host:~2,1!&set suffix=1
set hostaddr=!host:~-1!
set host=!host:~3,-1!
set PCIP=10.6.!host!.!hostaddr!
if "!hostaddr!"=="1" set rackname=!rackname!-A
if "!hostaddr!"=="2" set rackname=!rackname!-B
if "!suffix!"=="1" set rackname=!rackname! 
if "!suffix!"=="2" set rackname=!rackname!


REM Check if PC is reachable ======================
REM Start ping test to host PC
 ping -n 1 !PCIP! > %pingout%
 FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout% &set noskip=1
  set rmup=1
) || (
 echo Rack PC not available; skipping check on Rack-!rackname!
 echo -------------------- Rack-!rackname! is offline >> %tlog%
 del/Q %pingout% &set noskip=0
)

if !noskip!==1 (
REM Check if test is running on rack ===============
set running=0
REM --- check if FGT_Tester.pl is running ---
plink.exe -ssh tester@!PCIP! -pw fortinet "ps -e|grep FGT" >%plinkout1%
FINDSTR /C:"FGT_Tester" %plinkout1% >nul && (
  echo|set /p ="Rack-!rackname! is running -------------------> BTCUS_VERSION">> %tlog%
  set running=1
  del/Q %plinkout1%
) || (
REM do nothing if FGT_Tester.pl is not running; need to check further
)

REM --- check if Burn_Gate.pl is running ---
  if !running!==0 (
  plink.exe -ssh tester@!PCIP! -pw fortinet "ps -e|grep Burn" >%plinkout1%
  FINDSTR /C:"Burn_Gate" %plinkout1% >nul && (
    echo|set /p ="Rack-!rackname! is running -------------------> BTCUS_VERSION">> %tlog%
    del/Q %plinkout1%
) || (
    echo|set /p ="-------------------- Rack-!rackname! is idle -> BTCUS_VERSION">> %tlog%
    del/Q %plinkout1%
)
)

  plink.exe -ssh tester@!PCIP! -pw fortinet "cat -s /opt/Burnin-tester/ProjectCode/Config/README|grep BIT_CFGSET_VERSION:|tr -d 'BIT_CFGSET_VERSION'|tr -d '\n'" > %plinkout%
  type %plinkout% >> %tlog%
  echo/ >> %tlog%"
  del/Q %plinkout%
)
)
:@echo on
if %checkroom%==cart goto _finish 
if %checkroom%==204 (
set checkroom=cart
set "host_list=%host_cart%"
set rm204up=%rmup%
)
if %checkroom%==203 (
set checkroom=204
set "host_list=%host_list204%"
set rm203up=%rmup%
)

set rmup=0
goto _starthere

:_finish
set cartup=%rmup%
if %rm203up%==0 echo Room A network may be DOWN^^!^^!^^! >>%tlog%
if %rm204up%==0 echo Room C network may be DOWN^^!^^!^^! >>%tlog%
if %cartup%==0 echo IQC network may be DOWN^^!^^!^^! >>%tlog%

echo/
type %tlog%
type %tlog% >>%rlog%
echo/ >> %rlog%
echo A record of this has been saved in %rlog%
del/Q %tlog%

:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause
endlocal

REM =================================================
REM 2015-08-31 Add checks for BITCUS server 
REM 2015-08-10 Add checks for PC-B
REM 2015-06-09 Add checks for racks T,U,V,W,X and Y