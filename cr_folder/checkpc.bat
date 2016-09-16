@echo off
echo/&echo/&echo/
echo ^>^>^>^> Rack PC Health Check ^<^<^<^<

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

set tempdir=checkpc_dir
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

REM Start checking PC status ===================
set chkpc=0
echo/
plink.exe -ssh tester@%pcIP% -pw fortinet "status --version|grep 'Copyright'" >%plinkout1%
FINDSTR /C:"Copyright" %plinkout1% >nul && (
  del/Q %plinkout1%
) || (
  echo|set /p ="WARNING! - PC may be hung or not running properly!"
  del/Q %plinkout1%
  goto _done
)

plink.exe -ssh tester@%pcIP% -pw fortinet "man --help|grep 'version'" >%plinkout1%
FINDSTR /C:"version" %plinkout1% >nul && (
  echo|set /p ="OK - PC is functioning normally."
  del/Q %plinkout1%
) || (
  echo|set /p ="WARNING! - PC may be hung or not running properly!"
  del/Q %plinkout1%
)


:_done
echo/

:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause

REM =================================================
REM 2016-04-07 Modified from checkcron.bat to check PC status
REM 2015-07-15 Add support for two PC per rack
REM 2015-06-09 Add support for racks T,U,V,W,X and Y