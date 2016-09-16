@echo off
echo/&echo/&echo/
echo ^>^>^>^> HQIP Version Support Check ^<^<^<^<

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

set tempdir=checkhqip_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir%
set pingout=%tempdir%^\pingout.txt
set plinkout1=%tempdir%^\plinkout1.txt
set xmlout=%tempdir%^\xmlout.txt

echo/
echo What is the Product type?
echo 1=Fortigate 2=FortiWifi 3=FortigateRugged
echo/
set /p product="Enter Product Type (1, 2 or 3): "
if %product%==1 ( set product=Fortigate-& goto _checkPC )
if %product%==2 ( set product=FortiWiFi-& goto _checkPC )
if %product%==3 ( set product=FortigateRugged-& goto _checkPC )
echo/
echo Invalid Device type.
echo Please try again or control-C to terminate.
goto _cont

:_checkPC
REM Check if PC is reachable ======================
REM Start ping test to PC
ping -n 1 %pcIP% > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout%
) || (
  echo PC is not available; skipping check ^!^!
  del/Q %pingout%
  goto _fin
)

REM Get Product Model =============================
echo What is the model (Model# is case sensitive; e.g., use 90D and not 90d)
set /p model="  Enter Model#: "
set device=%product%%model%



REM plink.exe -ssh tester@%pcIP% -pw fortinet "cd /opt/Burnin-tester/ProjectCode/Config/config/Product/FortiGate/image/%device%;pwd" >%plinkout1%
plink.exe -ssh tester@%pcIP% -pw fortinet "ls -d /opt/Burnin-tester/ProjectCode/Config/config/Product/FortiGate/image/*/|grep '%device%'" >%plinkout1%

FINDSTR /C:"%device%" %plinkout1% >nul && (
  plink.exe -ssh tester@%pcIP% -pw fortinet "ls -w 1 /opt/Burnin-tester/ProjectCode/Config/config/Product/FortiGate/image/%device%/HQIPCfg" > %plinkout1%
) || (
  echo|set /p ="%device% is not defined on Rack-%rackname%"
  del/Q %plinkout1%
  goto _fin
)

:_checkXML
set "search=.xml"
set "replace="
echo/ >%xmlout%
for /F "delims=" %%a in (%plinkout1%) DO (
   set line=%%~na
   setlocal EnableDelayedExpansion
   >> %xmlout% echo !line:%search%=%replace%!
   endlocal
)

echo/&echo/
echo %device% HQIP Versions supported on %rackname% :
type %xmlout%
del/Q %xmlout%
del/Q %plinkout1%

:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause

REM ------------------------------------------------
REM 2015-09-11 Modified for checking HQIP supported versions
REM 2015-07-15 Add support for two PCs per rack
REM 2015-06-09 Add support for racks T,U,V,W,X and Y

REM 2015-02-06 Initial release
