@echo off
REM tempdir    =temporary folder for runtime files
REM pduvbs     =temporary vbs program to query PDU temperature
REM pingout    =temporary file to store PDU ping status
REM tlog       =output log file to store results
REM tfile      =temporary file for XP compatibility
REM pfile      =temporary plink output file

echo/&echo/&echo/
echo ^>^>^>^> Temperature Check ^<^<^<^<

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

:_cont
:========================
set pdu1IP=31
set pdu2IP=32
set pdu1=1
set pdu2=0
if "%pdu3%"=="1" set pdu2=1
set pdu1IP=%hostnet%.%pdu1IP%
set pdu2IP=%hostnet%.%pdu2IP%
set hostIP=%host%


set tempdir=checktemp_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir% 
set pingout=%tempdir%^\pingout.txt
set pduvbs=%tempdir%^\pdupgm.php
set tlog=%logfile%
set tfile=%tempdir%^\tempoutfile.txt& REM added this for XP compatibility
set pfile=%tempdir%^\plinkout.txt
REM there must be a blank space after -- in the phppath variable below
set phpexe=%homedrive%%homepath%\Documents\UniServerZ\core\php54\php.exe
set phppath=%phpexe% -f "%pduvbs%" -- 
REM set phppath=C:\Nano_5_7_5\UniServer\usr\local\php\php.exe -f "%pduvbs%" -- 
set hasphp=1
REM IF NOT EXIST %phpexe% echo/ &echo You do not have PHP set up correctly to run this script!!! &goto _fin
IF NOT EXIST %phpexe% set hasphp=0

::set pdu1ID=%1
::set pduvbs=pdupgm.vbs
::set tlog=checkrack.log
::set tfile=tempoutfile.txt& REM added this for XP compatibility
::set pfile=plinkout.txt
set tempvar=0
set pduout=""
::set pdu1IP=""

if %pdu1%==0 echo/ &echo Rack has no sensor &echo/ &goto _fin

REM Check if PDU1 is reachable =====================
REM Start ping test to pdu1
ping -n 1 %pdu1IP% > %pingout%
FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout%
) || (
  echo PDU not available; skipping temperature check !!
  del/Q %pingout%
  goto _fin
)

REM Create php file ================================
>%pduvbs% echo ^<?php
>>%pduvbs% echo $pdu_ip = $argv[1];
>>%pduvbs% echo $out_file = $argv[2];
>>%pduvbs% echo $uri = 'http://'.$pdu_ip.'/cmd.cgi?$A5';
>>%pduvbs% echo $ch = curl_init($uri);
>>%pduvbs% echo curl_setopt_array(
>>%pduvbs% echo $ch, array(
>>%pduvbs% echo CURLOPT_USERPWD =^> "admin:admin",
>>%pduvbs% echo CURLOPT_RETURNTRANSFER =^> true
>>%pduvbs% echo ));
>>%pduvbs% echo $out = curl_exec($ch);
REM >>%pduvbs% echo echo $out;
>>%pduvbs% echo curl_close($ch);
>>%pduvbs% echo $writeout = file_put_contents ( $out_file , $out );
>>%pduvbs% echo if ($writeout == false) {
>>%pduvbs% echo echo('Error: no data written to file');
>>%pduvbs% echo }
>>%pduvbs% echo ?^>

set pduout=Rack-%host%-temp.txt
set pduIP=%pdu1IP%
set sensor=PDU1

REM start checking PDU sensor reading ==============
echo === %date% %time% ============================= >> %tlog%
plink.exe -ssh tester@%hostIP% -pw fortinet "cd /opt/Burnin-tester/ProjectCode/Config/time_cfg/config_4hours/; cat Management.xml|grep -A 1 \<Temperat" > %pfile%
FINDSTR /C:"yes" %pfile% >nul && (
  echo Rack %rackname% temperature monitoring is enabled. > %tfile%& REM added tfile for XP compatibility
  echo Rack %rackname% temperature monitoring is enabled. >> %tlog%
) || (
  echo WARNING! - Rack %rackname% temperature monitoring has been DISABLED!!! > %tfile%& REM added tfile for XP compatibility
  echo WARNING! - Rack %rackname% temperature monitoring has been DISABLED!!! >> %tlog%
)
del/Q %pfile%

:_startPDUcheck
if "%hasphp%"=="0" goto _nophp
%phppath% %pduIP% %pduout%
goto _contcheck

:_nophp
REM Create vbs file ================================
del/Q %pduvbs%
set pduvbs=%pduvbs%.vbs
>%pduvbs% echo set OBJECT=WScript.CreateObject("WScript.Shell")
>>%pduvbs% echo WScript.sleep 50
>>%pduvbs% echo OBJECT.SendKeys "$A5{ENTER}"
>>%pduvbs% echo WScript.sleep 250
>>%pduvbs% echo OBJECT.SendKeys "{ENTER}"
>>%pduvbs% echo OBJECT.SendKeys "$A2{ENTER}"
>>%pduvbs% echo WScript.sleep 250
>>%pduvbs% echo OBJECT.SendKeys "{ENTER}"
>>%pduvbs% echo Wscript.Quit
REM :: Open a Telnet window to PDU
start telnet.exe -f %pduout% %pduIP%
ping -n 2 localhost >nul
REM :: Run the script 
cscript %pduvbs% >nul
REM :: Put in some more delay
ping -n 3 localhost >nul


:_contcheck
for /F %%j in ('FINDSTR /C:"$A0," %pduout%') do (
set tempvar="%%j"
)
if %tempvar%==0 goto _done

set tempvar=%tempvar:~-3,2%

if %tempvar%==XX echo/ &echo Rack has no sensor &echo/ &goto _fin2

REM echo/
REM echo ^>^>^> Temperature Reading from %rackname% (PDU-IP %pdu1IP%) ^<^<^<
echo/ >> %tfile%& REM added this for XP compatibility
REM echo|set /p ="Rack %rackname% %sensor% temperature is %tempvar%C" == removed this for XP compatibility
echo Rack %rackname% %sensor% temperature is %tempvar% deg C>> %tfile%& REM added this for XP compatibility
REM echo %date% %time% Rack %rackname% %sensor% %tempvar% deg C>> %tlog%
echo Rack %rackname% %sensor% temperature is %tempvar% deg C>> %tlog%
set tempvar=0

:_done
if %pdu2%==0 goto _fin1
if %pduIP%==%pdu2IP% goto _fin1
set pduIP=%pdu2IP%
set sensor=PDU2
goto _startPDUcheck

:_fin1
type %tfile%& REM added this for XP compatibility
del/Q %tfile%& REM added this for XP compatibility
echo/ >> %tlog%& REM added this for XP compatibility
echo/ &echo/ &echo A record of this has been saved in %tlog%
:_fin2
del/Q %pduout%
del/Q %pduvbs%

:_fin
echo/
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause

REM =================================================
REM 2016-03-02 Modified to check for php.exe before running
REM 2015-10-01 Modified to use php script to get temperature reading
REM 2015-06-09 Add checks for racks T,U,V,W,X and Y