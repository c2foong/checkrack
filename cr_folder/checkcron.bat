@echo off
echo/&echo/&echo/
echo ^>^>^>^> Auto Bitcus Update Check ^<^<^<^<

REM Get input ======================
call getinput.bat %1
set /a x=0
setlocal EnableDelayedExpansion
for /F "tokens=*" %%i in (getinput_dir\getinput_out.txt) do (
   set /a x=x+1
   set VAR!x!=%%i
)
endlocal & (
set      logfile=%VAR2%
set enteredvalue=%VAR3%
set     rackname=%VAR4%
set         pcIP=%VAR5%
set      hostnet=%VAR6%
set       nodeid=%VAR7%
set         pdu3=%VAR8%
set          v22=%VAR9%
set        PCcnt=%VAR10%
)

:_cont

set tempdir=cron_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir%
set pingout=%tempdir%^\pingout.txt
set plinkout1=%tempdir%^\plinkout1.txt

REM Check if PC is reachable ======================
REM Start ping test to PC
ping -n 1 %pcIP% > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout%
) || (
  echo PC is not available; skipping CRONTAB check !!
  del/Q %pingout%
  goto _fin
)

REM Start checking CRONTAB file ===================
set chkcron=0
echo/
plink.exe -ssh tester@%pcIP% -pw fortinet "cat /etc/crontab|grep btcus_cfg_update|grep '^#'" >%plinkout1%
FINDSTR /C:"btcus_cfg_update" %plinkout1% >nul && (
  echo|set /p ="WARNING! - BTCUS auto-update in crontab has been DISABLED!"
  del/Q %plinkout1%
) || (
  set chkcron=1
)

if %chkcron%==0 goto _done
plink.exe -ssh tester@%pcIP% -pw fortinet "cat /etc/crontab|grep btcus_cfg_update|grep btcus_cfg_update" >%plinkout1%
FINDSTR /C:"btcus_cfg_update" %plinkout1% >nul && (
  echo|set /p ="OK - BTCUS auto-update is enabled."
  echo/ &echo/
  echo|set /p ="Rack-%rackname% BTCUS_VERSION is"
  plink.exe -ssh tester@%pcIP% -pw fortinet "cat -s /opt/Burnin-tester/ProjectCode/Config/README|grep BIT_CFGSET_VERSION:|tr -d 'BIT_CFGSET_VERSION'|tr -d '\n'" > %plinkout1%
  type %plinkout1%
  del/Q %plinkout1%
) || (
  echo|set /p ="WARNING! - BTCUS auto-update in crontab is NOT SET!"
  del/Q %plinkout1%
)

:_done
echo/

:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause

REM =================================================
REM 2015-07-15 Add support for two PC per rack
REM 2015-06-09 Add support for racks T,U,V,W,X and Y