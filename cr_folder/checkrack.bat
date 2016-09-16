@echo off
setlocal EnableDelayedExpansion

set "param="
if NOT "%1"=="" (
   set param=%1
   set param1=!param:~0,1!
)

if NOT "!param1!"=="-" set param=%1
if "!param1!"=="-" set param=%2

REM Get input ======================
call getinput.bat !param!
set /a x=0
for /F "tokens=*" %%i in (getinput_dir\getinput_out.txt) do (
   set /a x=x+1
   set VAR!x!=%%i
)

set logfile=%VAR2%
set enteredvalue=%VAR3%
set rackname=%VAR4%
set host=%VAR5%
set hostnet=%VAR6%
set nodeid=%VAR7%
set pdu3=%VAR8%
set v22=%VAR9%
set PCcnt=%VAR10%

:_cont
set tempdir=checkrack_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir%
set getdut=getdut.bat
set btcusIP=172.30.147.41
set running=0
set pingout=%tempdir%^\pingout.txt
set pfile=%tempdir%^\plinkout.txt
set pfile1=%tempdir%^\plinkout1.txt
set pfile2=%tempdir%^\plinkout2.txt
set pfile3=%tempdir%^\plinkout3.txt
set swfile=%tempdir%^\swout.txt
set swfile1=%tempdir%^\sw1out.txt
set results=%tempdir%^\results.txt
set plinkcmd=%tempdir%^\plinkcmd.txt

cls
echo/
echo  Checking BTCUS Config Version on Rack "%rackname%". Please wait...
echo/
plink.exe -ssh tester@%host% -pw fortinet "hostname|grep '.*'" > %pfile%

for  %%x in (%pfile%) do (
set fsize=%%~zx
set name= %%x
)
cls
echo/
echo  Checking BTCUS Config Version on Rack "%rackname%". Please wait...&echo/
if %fsize%==0 (
echo Connection timeout. Please check if Rack %rackname% is offline.
goto _fin1
)

set /p hostname=<%pfile%
plink.exe -ssh tester@%host% -pw fortinet "cat -s /opt/Burnin-tester/ProjectCode/Config/README|grep CFGSET_VERSION:" > %pfile%

plink.exe -ssh tester@%host% -pw fortinet "cd /opt/Burnin-tester/ProjectCode; ./Cmd/FGT_Tester.pl -v" >%pfile1%
plink.exe -ssh tester@%host% -pw fortinet "cat -s /opt/osprey/sync_logs.ini|grep -i SERVER_IP" > %pfile2%
echo/ >> %pfile2%
plink.exe -ssh tester@%host% -pw fortinet "cat -s /opt/osprey/sync_logs.ini|grep -i TEST_TYPE" >> %pfile2%
REM plink.exe -ssh tester@%host% -pw fortinet "cd /opt/Burnin-tester/ProjectCode/Config/time_cfg/config_4hours/; cat Management.xml|grep -o -i \>product; cat Management.xml|grep -o -i \>qatest" > %pfile3%
plink.exe -ssh tester@%host% -pw fortinet "cat /opt/Burnin-tester/ProjectCode/Config/time_cfg/config_4hours/Management.xml|grep -o -i \>.*\</Runpur|grep -o -i \>.*\<" > %pfile3%

cls
if "%rackname%"=="%hostname%" echo/ &echo Rack requested is "%rackname%"
if NOT "%rackname%"=="%hostname%" echo/ &echo Rack requested is "%rackname%"; Actual host name is:"%hostname%"
set rackname=%hostname%
type %pfile1%

echo === %date% %time% ============================= >> %logfile%
echo Rack "%rackname%" CONFIGURATION >> %logfile%
type %pfile1% >> %logfile%

echo|set /p ="BTCUS Version is "
type %pfile%
echo/ >>%logfile%
echo|set /p ="BTCUS Version is " >> %logfile%
type %pfile% >> %logfile%

echo/

echo|set /p ="OSPREY "
type %pfile2%
echo/ >> %logfile%
echo|set /p ="OSPREY " >> %logfile%
type %pfile2% >> %logfile%

echo|set /p ="Rack Run-Purpose is ....."
type %pfile3%
REM echo/
echo/ >> %logfile%
echo|set /p ="Rack Run-Purpose is ....." >> %logfile%
type %pfile3% >> %logfile%
echo/ >> %logfile%

REM check temperature monitoring ==================
plink.exe -ssh tester@%host% -pw fortinet "cat /opt/Burnin-tester/ProjectCode/Config/time_cfg/config_4hours/Management.xml|grep -A 1 \<Temperat" >%pfile1%
FINDSTR /C:"yes" %pfile1% >nul && (
  echo Temperature monitoring is enabled.
  echo Temperature monitoring is enabled. >> %logfile%
) || (
  echo WARNING^^! - Temperature monitoring has been DISABLED^^!^^!^^!
  echo WARNING^^! - Temperature monitoring has been DISABLED^^!^^!^^! >> %logfile%
)

REM check crontab =================================
set chkcron=0
plink.exe -ssh tester@%host% -pw fortinet "cat /etc/crontab|grep btcus_cfg_update|grep '^#'" >%pfile1%
FINDSTR /C:"btcus_cfg_update" %pfile1% >nul && (
  echo WARNING^^! - BTCUS auto-update in crontab has been DISABLED^^!^^!^^!
  echo WARNING^^! - BTCUS auto-update in crontab has been DISABLED^^!^^!^^! >> %logfile%
) || (
  set chkcron=1
)

if %chkcron%==0 goto _chkrun
plink.exe -ssh tester@%host% -pw fortinet "cat /etc/crontab|grep btcus_cfg_update|grep btcus_cfg_update" >%pfile1%
FINDSTR /C:"btcus_cfg_update" %pfile1% >nul && (
  echo BTCUS auto-update is .... enabled.
  echo BTCUS auto-update is .... enabled. >> %logfile%
) || (
  echo WARNING^^! - BTCUS auto-update in crontab is NOT SET^^!^^!^^!
  echo WARNING^^! - BTCUS auto-update in crontab is NOT SET^^!^^!^^! >> %logfile%
)

:_chkrun
REM Check if test is running on rack ==============
plink.exe -ssh tester@%host% -pw fortinet "ps -e|grep FGT" >%pfile1%
FINDSTR /C:"FGT_Tester" %pfile1% >nul && (
  echo/
  set runstatus=Burn-in test
  echo Skipping connectivity check; !runstatus! is running on %rackname% >> %logfile%
  set running=1
) || (
  REM do nothing
)

if %running%==1 goto _chkoption
plink.exe -ssh tester@%host% -pw fortinet "ps -e|grep Burn" >%pfile1%
FINDSTR /C:"Burn_Gate" %pfile1% >nul && (
  echo/
  set runstatus=Image Burning
  echo Skipping connectivity check; !runstatus! is running on %rackname% >> %logfile%
  set running=1
) || (
  echo Rack %rackname% is idle: No Burn-in test running & echo Rack %rackname% is idle. >> %logfile%
)

:_chkoption
if "%1"=="-u" goto _update
if "%1"=="-c" goto _cfg2time
goto _linkchk

:_update
if %running%==1 ( echo Skipping update since rack is running %runstatus%. & goto _getdut )
echo Updating rack . . . 
echo/
plink.exe -ssh root@%host% -pw fortinet "cd /opt/Burnin-tester/ProjectCode; ./Cmd/FGT_Tester.pl -o update -i %btcusIP%" >%pfile1%
plink.exe -ssh tester@%host% -pw fortinet "cat -s /opt/Burnin-tester/ProjectCode/Config/README|grep CFGSET_VERSION:" > %pfile%
echo/
echo|set /p ="BTCUS Version is now "
type %pfile%
echo/ >>%logfile%
echo|set /p ="BTCUS update done... BTCUS Version is " >> %logfile%
type %pfile% >> %logfile%
echo/ >>%logfile%

:_cfg2time
if %running%==1 ( echo Skipping cfg2time since rack is running %runstatus%. & goto _getdut )
echo Running cfg2time . . .
plink.exe -ssh root@%host% -pw fortinet "cd /opt/Burnin-tester/ProjectCode/Config; ./cfg2time.sh" >%pfile1%
echo Done^^!
echo cfg2time completed^^! >> %logfile%

REM ================================================
:_linkchk
if %running%==1 ( echo Skipping rack components check since rack is running %runstatus%. & goto _getdut )
echo Checking connectivity to rack components . . .
echo/
REM Start ping test to PC ==========================
ping -n 1 %host% > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  echo ping OK - %host%   ^(Rack_PC^) is UP >%results%
) || (
  echo ERROR   - %host%   ^(Rack_PC^) FAILED PING CHECK ^^!^^! >%results%
)

REM Start ping test to Terminal Server =============
ping -n 1 %hostnet%.11 > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  echo ping OK - %hostnet%.11  ^(Term_Svr^)is UP >>%results%
) || (
  echo ERROR   - %hostnet%.11  ^(Term_Svr^)FAILED PING CHECK ^^!^^! >>%results%
)

REM Start ping test to switches ====================
set SW_LIST=(1 2 3 4)
if %v22%==1 set SW_LIST=(1 2)
if %v22%==3 set SW_LIST=(5)
REM XXXXXXXXXXXXXxx special handling for Rack AA-A xxxxxxxxxxxxx
if %rackname%==USIQC-AA-A set SW_LIST=(2)

REM XXXXXXXXXXXXXxx special handling for Rack X-A, AC-A xxxxxxxxxxxxx
REM if %rackname%==USIQC-X-A (
if %v22%==9 (
REM  echo Unknown switch configuration - skipping switch check>>%results%
  goto _pingPDU
)
REM if %rackname%==USIQC-AC-A (
REM  echo Unknown switch configuration - skipping switch check>>%results%
REM   goto _pingPDU
)
REM XXXXXXXXXXXXXxx special handling for Rack AE-A xxxxxxxxxxxxx
if %rackname%==USIQC-AE-A set SW_LIST=(1)

set /a swnum=0

for %%i in %SW_LIST% do (
    set /a "swnum+=1"
    ping -n 1 %hostnet%.2%%i > %pingout%
    FINDSTR /C:"bytes=32" %pingout% >nul && (
REM   echo ping OK - %hostnet%.2%%i  ^(Switch%%i^) is UP >>%results%
      echo ping OK - %hostnet%.2%%i  ^(Switch!swnum!^) is UP >>%results%
) || (
REM   echo ERROR   - %hostnet%.2%%i  ^(Switch%%i^) FAILED PING CHECK ^^!^^! >>%results%
      echo ERROR   - %hostnet%.2%%i  ^(Switch!swnum!^) FAILED PING CHECK ^^!^^! >>%results%
)
)

:_pingPDU
REM Start ping test to pdu1 ========================
ping -n 1 %hostnet%.31 > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  echo ping OK - %hostnet%.31  ^(PDU1^)    is UP >>%results%
) || (
  echo ERROR   - %hostnet%.31  ^(PDU1^)    FAILED PING CHECK ^^!^^! >>%results%
)

REM XXXXXXXXXXXXXxx special handling for Rack RMA-H-A xxxxxxxxxxxxx
if %rackname%==USRMA-H-A goto _checkpdu3

REM Start ping test to pdu2 ========================
ping -n 1 %hostnet%.32 > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  echo ping OK - %hostnet%.32  ^(PDU2^)    is UP >>%results%
) || (
  echo ERROR   - %hostnet%.32  ^(PDU2^)    FAILED PING CHECK ^^!^^! >>%results%
)

:_checkpdu3
REM Start ping test to pdu3 ========================
if %pdu3%==1 (
ping -n 1 %hostnet%.33 > %pingout%
   FINDSTR /C:"bytes=32" %pingout% >nul && (
     echo ping OK - %hostnet%.33  ^(PDU3^)    is UP >>%results%
) || (
     echo ERROR   - %hostnet%.33  ^(PDU3^)    FAILED PING CHECK ^^!^^! >>%results%
)
)

REM Start ping test to router ======================
ping -n 1 %hostnet%.254 > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  echo ping OK - %hostnet%.254 ^(Router^)  is UP >>%results%
) || (
  echo ERROR   - %hostnet%.254 ^(Router^)  FAILED PING CHECK ^^!^^! >>%results%
)

REM Start Link-Status Check ========================
set sw1=%hostnet%.21
set sw2=%hostnet%.22
set sw3=%hostnet%.23
set sw4=%hostnet%.24
set sw1name=Switch1
set sw2name=Switch2
set sw3name=Switch3
set sw4name=Switch4
if %v22%==3 set sw1=%hostnet%.25
REM XXXXXXXXXXXXXxx special handling for Rack AA-A xxxxxxxxxxxxx
if %rackname%==USIQC-AA-A set sw1=%hostnet%.22

REM XXXXXXXXXXXXXxx special handling for Rack X-A AC-A and AE-A xxxxxxxxxxxxx
REM if %rackname%==USIQC-X-A (
if %v22%==9 (
  echo Non-standard switch configuration - skipped switch ping test ^& link check>%swfile%
  type %swfile% >>%results%
  goto _donelinkchk
)
REM if %rackname%==USIQC-AC-A (
REM   echo Non-standard switch configuration - skipped switch ping test ^& link check>%swfile%
REM   type %swfile% >>%results%
REM   goto _donelinkchk
)
if %rackname%==USIQC-AE-A set sw1=%hostnet%.21

set interface=0/50
if %v22%==3 set interface=0/49

if %v22%==1 goto _vtwo2

REM Check switch interface 0/50 status is UP or DOWN =====================
REM but first create command file
REM set plinkcmd=%tempdir%^\plinkcmd.txt -- this is redundant
echo admin>%plinkcmd%
echo/>>%plinkcmd%
echo show int status %interface%>>%plinkcmd%
echo logout>>%plinkcmd%
echo n>>%plinkcmd%

plink.exe -telnet %sw1%  < %plinkcmd% > %swfile1%
FINDSTR /C:"Link Status" %swfile1% > %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo Link Status....................... Unknown ^^!^^! > %swfile%
echo|set /p ="Eth1 to %sw1name% interface %interface%   " >>%results%
type %swfile% >>%results%

REM Stop if there is only one switch
if %v22%==3 goto _donelinkchk

plink.exe -telnet %sw4%  < %plinkcmd% > %swfile1%
FINDSTR /C:"Link Status" %swfile1% > %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo Link Status....................... Unknown ^^!^^! > %swfile%
echo|set /p ="Eth2 to %sw4name% interface %interface%   " >>%results%
type %swfile% >>%results%

del/Q %swfile1%
del/Q %plinkcmd%

REM Check switch interface 0/51 status is UP or DOWN =====================
REM but first create command file
REM set plinkcmd=%tempdir%^\plinkcmd.txt -- this is redundant
echo admin>%plinkcmd%
echo/>>%plinkcmd%
echo show int status 0/51>>%plinkcmd%
echo logout>>%plinkcmd%
echo n>>%plinkcmd%

plink.exe -telnet %sw2%  < %plinkcmd% > %swfile1%
FINDSTR /C:"Link Status" %swfile1% > %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo Link Status....................... Unknown ^^!^^! > %swfile%
echo|set /p ="%sw1name%/Port52 to %sw2name%/Port51 " >>%results%
type %swfile% >>%results%

plink.exe -telnet %sw3%  < %plinkcmd% > %swfile1%
FINDSTR /C:"Link Status" %swfile1% > %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo Link Status....................... Unknown ^^!^^! > %swfile%
echo|set /p ="%sw2name%/Port52 to %sw3name%/Port51 " >>%results%
type %swfile% >>%results%

del/Q %swfile1%
del/Q %plinkcmd%

REM Check switch interface 0/52 status is UP or DOWN =====================
REM but first create command file
REM set plinkcmd=plinkcmd.txt -- this is redundant
echo admin>%plinkcmd%
echo/>>%plinkcmd%
echo show int status 0/52>>%plinkcmd%
echo logout>>%plinkcmd%
echo n>>%plinkcmd%

plink.exe -telnet %sw3%  < %plinkcmd% > %swfile1%
FINDSTR /C:"Link Status" %swfile1% > %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo Link Status....................... Unknown ^^!^^! > %swfile%
echo|set /p ="%sw3name%/Port52 to %sw4name%/Port51 " >>%results%
type %swfile% >>%results%

del/Q %swfile1%
del/Q %plinkcmd%
goto _donelinkchk

REM for v22 racks only =============================
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

:: Open a Telnet window to SW1 ================
   start telnet.exe %sw1% -f %telnetof%
:: Put in some delay
   ping -n 1 localhost >nul
:: Run the script 
   cscript %vbspgm% >nul
:: Put in some more delay
   ping -n 3 localhost >nul
:: Check if wscript.exe process is still running in task manager and kill it
REM   tasklist /FI "IMAGENAME eq wscript.exe" 2>NUL | find /I /N "wscript.exe">NUL
REM   if %ERRORLEVEL%==0 taskkill /f /im "wscript.exe" 2>nul
:: Check if Telnet window is still open, then kill it 
   taskkill /f /FI "WINDOWTITLE eq Telnet 172.30.*" >nul
   FINDSTR /C:"port45" %telnetof% > %swfile%
   COPY /Y %telnetof% %swfile1% >nul
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port45   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="Eth1 to %sw1name% " >>%results%
   type %swfile% >>%results%

:: Open a Telnet window to SW2 ================
   start telnet.exe %sw2% -f %telnetof%
:: Put in some delay
   ping -n 1 localhost >nul
:: Run the script 
   cscript %vbspgm% >nul
:: Put in some more delay
   ping -n 3 localhost >nul
:: Check if wscript.exe process is still running in task manager and kill it
REM   tasklist /FI "IMAGENAME eq wscript.exe" 2>NUL | find /I /N "wscript.exe">NUL
REM   if %ERRORLEVEL%==0 taskkill /f /im "wscript.exe" 2>nul
:: Check if Telnet window is still open, then kill it 
   taskkill /f /FI "WINDOWTITLE eq Telnet 172.30.*" >nul
   FINDSTR /C:"port46" %telnetof% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port46   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="Eth2 to %sw2name% " >>%results%
   type %swfile% >>%results%

REM XXXXXXXXXXXXXxx special handling for Rack AB-A xxxxxxxxxxxxx
if %rackname%==USIQC-AB-A (
   FINDSTR /C:"port49" %telnetof% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port49   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="S1/port50 to S2/" >>%results%
   type %swfile% >>%results%
   FINDSTR /C:"port51" %telnetof% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port51   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="S1/port52 to S2/" >>%results%
   type %swfile% >>%results%

REM Check connection to ADC-4000D xxxxxxxxxxxxxxxxxxxxxxxxxxx
   FINDSTR /C:"port49" %swfile1% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port49   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="ADC4000-D to S1/" >>%results%
   type %swfile% >>%results%
   FINDSTR /C:"port51" %swfile1% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port51   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="ADC4000-D to S1/" >>%results%
   type %swfile% >>%results%
del/Q %swfile1%

   FINDSTR /C:"port50" %telnetof% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port50   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="ADC4000-D to S2/" >>%results%
   type %swfile% >>%results%
   FINDSTR /C:"port52" %telnetof% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port52   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="ADC4000-D to S2/" >>%results%
   type %swfile% >>%results%

goto _skips1s2
)

   FINDSTR /C:"port47" %telnetof% >  %swfile%
set fsize=0
for  %%x in (%swfile%) do (
set fsize=%%~zx
)
if %fsize%==0 echo port47   Unknown Status ^^!^^! > %swfile%
   echo|set /p ="S1/port48 to S2/" >>%results%
   type %swfile% >>%results%



:_skips1s2

:: Clean up
   del/Q %vbspgm%
   del/Q %telnetof%
REM End for v22 racks only =========================

:_donelinkchk
del/Q %swfile%

type %results%
type %results% >> %logfile%
del/Q %pingout%
del/Q %results%
REM echo/ &echo A record of this has been saved in %logfile%; purge it if it is too large.

REM Start checking DUTs on rack ===================v
goto _done
:_getdut
echo/

echo List of DUT on the rack:
echo List of DUT on the rack: >> %logfile%
call %getdut% %host% %pfile1%
type %pfile1%
type %pfile1% >> %logfile%
REM End checking DUTs on rack =====================^

:_done
del/Q %pfile1%
del/Q %pfile2%
del/Q %pfile3%

REM Start checking PC status ===================v
echo/
REM xxxplink.exe -ssh tester@%host% -pw fortinet "status --version|grep 'Copyright'" >%pfile1%
plink.exe -ssh tester@%host% -pw fortinet "mount|grep '/etc/mtab is not writable'" >%pfile1%
FINDSTR /C:"not writable" %pfile1% >nul && (
REM  echo|set /p ="WARNING! - PC may be hung or not running properly!"
  del/Q %pfile1%
  echo WARNING^^! - Rack PC may be hung or not running properly^^!^^!^^!
  echo WARNING^^! - Rack PC may be hung or not running properly^^!^^!^^! >> %logfile%
  goto _fin2
) || (
REM do nothing
  del/Q %pfile1%
)

REM xxxplink.exe -ssh tester@%host% -pw fortinet "man --help|grep 'version'" >%pfile1%
plink.exe -ssh tester@%host% -pw fortinet "ls /home/tester/Desktop/|grep 'Input/output error'" >%pfile1%
FINDSTR /C:"output error" %pfile1% >nul && (
  del/Q %pfile1%
  echo WARNING^^! - Rack PC may be hung or not running properly^^!^^!^^!
  echo WARNING^^! - Rack PC may be hung or not running properly^^!^^!^^! >> %logfile%
  goto _fin2
) || (
REM do nothing
  del/Q %pfile1%
)

plink.exe -ssh tester@%host% -pw fortinet "whereis whereis|grep 'Input/output error'" >%pfile1%
FINDSTR /C:"output error" %pfile1% >nul && (
  del/Q %pfile1%
  echo WARNING^^! - Rack PC may be hung or not running properly^^!^^!^^!
  echo WARNING^^! - Rack PC may be hung or not running properly^^!^^!^^! >> %logfile%
) || (
REM do nothing
  del/Q %pfile1%
)



REM End checking PC status ======================^

:_fin2
echo/ &echo A record of this has been saved in %logfile%; purge it if it is too large.


:_fin1
del/Q %pfile%
echo/ >> %logfile%

:_fin
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause
endlocal
REM ------------------------------------------------
REM Last updated: 2016-05-03; Added check for dut SN when rack is running
REM Last updated: 2016-04-14; Added check for PC hostname
REM Last updated: 2016-04-07; Added check for whether Rack PC is hung
REM Last updated: 2015-01-04; Removed check for runwaway process wscript.exe and kills it
REM Last updated: 2015-11-06; Add support for new cart USIQC-AA-A
REM Last updated: 2015-08-19; Add support for RMA racks; use temporary directory for processing
REM Last updated: 2015-07-15; Add support for two PCs per rack
REM Last updated: 2015-06-09; Add support for racks T,U,V,W,X and Y
REM Last updated: 2015-05-01; updated to include link status between SW1-SW2-SW3-SW4
REM Last updated: 2015-04-17; updated Failed Ping Check message
REM Last updated: 2015-04-10; included check for Burn image process to flag rack as busy 
REM Last updated: 2014-11-05; replaced -a option with default
REM Last updated: 2014-10-01; modified default option to version checking only and added -a option
REM Last updated: 2014-09-22; add check if Burn-in test is running
REM Last updated: 2014-09-11; add racks Q, R, S
REM Last updated: 2014-09-02
REM Eliminate the need for plink command file
REM Add option -u for BTCUS update and -c for running cfg2time
REM Add checking for runwaway process wscript.exe and kills it
REM Add link status check for V2.2 switch
REM Add output to log file
REM Add checking switch ports for V22 racks
REM Add option -v to only check version
REM Add support for V2.2 racks