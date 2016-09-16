@echo off
echo/&echo/&echo/
echo ^>^>^>^> Switch Port Link-Status Check ^<^<^<^<

REM Get input ======================
call getinput.bat
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
set         host=%VAR5%
set      hostnet=%VAR6%
set       nodeid=%VAR7%
set         pdu3=%VAR8%
set          v22=%VAR9%
set        PCcnt=%VAR10%
set      swcount=%VAR11%
set       swtype=%VAR12%
)

:_cont

set tempdir=checkport_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir%
set plinkout=%tempdir%^\plinkout.txt
set plinkcmd=%tempdir%^\plinkcmd.txt
set results=%tempdir%^\results.txt
set logfilcp=%logfile%
set sw1out=%tempdir%^\sw1out.txt
set swout=%tempdir%^\swout.txt

echo/
set /p swnum="Enter Switch#: "
if %swnum% gtr %swcount% ( echo Invalid entry. & goto _cont )
:_contpnum
set /p portnum="  Enter Port#: "
if %portnum% gtr 52 ( echo Invalid entry. & echo/ & goto _contpnum )
echo/
echo  Checking switch port link-status on %rackname%. Please wait...
echo/
plink.exe -ssh tester@%host% -pw fortinet "cat -s /opt/Burnin-tester/ProjectCode/Config/README|grep CFGSET_VERSION:" > %plinkout%

for  %%x in (%plinkout%) do (
set fsize=%%~zx
set name= %%~nx
)
echo/

if %fsize%==0 (
echo Connection timeout. Please check if Rack %rackname% is offline.
REM xxxxxxxxxxxxxxxxgoto _fin1
)

goto _linkcheck


:_linkcheck
REM Start Link-Status Check ========================
set sw=%hostnet%.2%swnum%
set swname=Switch%swnum%

if %swcount%==2 goto _vtwo2

if %swtype%==124D set sw=%hostnet%.25

REM Check switch interface status is UP or DOWN
REM but first create command file
echo admin>%plinkcmd%
echo/>>%plinkcmd%
echo show int status 0/%portnum%>>%plinkcmd%
echo logout>>%plinkcmd%
echo n>>%plinkcmd%

plink.exe -telnet %sw%  < %plinkcmd% > %sw1out%
FINDSTR /C:"Admin Mode" %sw1out% > %swout%
FINDSTR /C:"Physical Mode" %sw1out% >> %swout%
FINDSTR /C:"Physical Status" %sw1out% >> %swout%
FINDSTR /C:"Link Status" %sw1out% >> %swout%
REM echo|set /p ="%swname% interface 0/%portnum% " >>%results%
echo %swname% interface 0/%portnum%: >%results%
type %swout% >>%results%
del/Q %sw1out%
del/Q %plinkcmd%
goto _donelinkchk

REM for swcount racks only =============================
:_vtwo2
set vbspgm=%tempdir%^\telnetmp.vbs
set telnetof=%tempdir%^\telnetout.txt

:: Create vbs script
echo set OBJECT=WScript.CreateObject("WScript.Shell") >%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys "{ENTER}" >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys "admin{ENTER}" >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys "{ENTER}" >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys "show switch physical-port ?" >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys " " >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys " " >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys " " >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys " " >>%vbspgm%
echo WScript.sleep 500 >>%vbspgm%
echo OBJECT.SendKeys "quit{ENTER}" >>%vbspgm%
echo WScript.sleep 50 >>%vbspgm%
echo OBJECT.SendKeys "quit{ENTER}" >>%vbspgm%
echo WScript.sleep 150 >>%vbspgm%
echo OBJECT.SendKeys "exit{ENTER}" >>%vbspgm%
echo WScript.sleep 10 >>%vbspgm%
echo WScript.Quit >>%vbspgm%

:: Open a Telnet window to Switch
   start telnet.exe %sw% -f %telnetof%
:: Put in some delay
   ping -n 1 localhost >nul
:: Run the script 
   cscript %vbspgm% >nul
:: Put in some more delay
   ping -n 6 localhost >nul
:: Check if wscript.exe process is still running in task manager and kill it
REM   tasklist /FI "IMAGENAME eq wscript.exe" 2>NUL | find /I /N "wscript.exe">NUL
REM   if %ERRORLEVEL%==0 taskkill /f /im "wscript.exe"
:: Check if Telnet window is still open, then kill it
   taskkill /f /FI "WINDOWTITLE	 eq Telnet 172.30.*" >NUL
   FINDSTR /C:"port%portnum% " %telnetof% >  %swout%
   echo|set /p ="%swname% " >>%results%
   type %swout% >>%results%
:: Clean up
   del/Q %vbspgm%
   del/Q %telnetof%
REM End for swcount racks only =========================

:_donelinkchk
del/Q %swout%

type %results%
REM Write to file
echo === %date% %time% ============================= >> %logfilcp%
echo Rack "%rackname%" switch port link-status check result >> %logfilcp%
type %results% >> %logfilcp%
echo/ >> %logfilcp%
del/Q %results%
echo/ &echo A record of this has been saved in %logfilcp%
:_done

:_fin1
del/Q %plinkout%

:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause

REM ------------------------------------------------
REM 2016-05-02 Expanded to check RMA racks and multiple PC racks
REM 2015-06-22 Initialized swtype variable
REM 2015-06-09 Add support for racks X and Y
REM 2014-09-17 Initial release
