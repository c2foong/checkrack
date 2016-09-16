@echo off
REM changed skip to noskip
REM Add offline rack in final report
REM Delayed expand date and time

setlocal EnableDelayedExpansion
set tempdir=alltemp_dir
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir% 
set pduvbs=%tempdir%^\temppgm.php
REM set tlog=allpdutemp.log
set tlog=checkrack.log
set temppdu2=%tempdir%^\temppdu2.log
set pingout=%tempdir%^\pingout.txt
set t_summary=%tempdir%^\t_summary.log
set phpexe=C:\Users\cfoong\Documents\UniServerZ\core\php54\php.exe
REM there must be a blank space after -- in the phppath variable below
set phppath=%phpexe% -f "%pduvbs%" -- 
REM set phppath=C:\Nano_5_7_5\UniServer\usr\local\php\php.exe -f "%pduvbs%" -- 
set tempoutfile="0"
set hostIP=""
set skip=0
set pdu1_list=(A64,B65,C66,E68,F69,G70,H71,J73,K74,L75,M76,N77,O78,P79,Q80,R81,S82,U84,V85,W86,X87,Y88,Z89)
set pdu2_list=(J73,K74,L75,M76,N77,O78,P79,Q80,R81,S82,Z89)
REM for script testing set pdu1_list=(A64,J73)
REM for script testing set pdu2_list=(J73)

IF NOT EXIST %phpexe% echo/ &echo You do not have PHP set up correctly to run this script!!! &goto _fin

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
>>%pduvbs% echo curl_close($ch);
>>%pduvbs% echo $writeout = file_put_contents ( $out_file , $out );
>>%pduvbs% echo if ($writeout == false) {
>>%pduvbs% echo echo("Error: no data written to file for PDU $pdu_ip \n");
>>%pduvbs% echo }
>>%pduvbs% echo ?^>

CLS
REM echo Please DO NOT USE THE PC and do not abort once program has started^^!
REM echo Do not interrupt the popup windows while the program is running^^!
REM echo/
echo This will take some time to complete. Control-C to abort now or
echo program will start shortly.
echo/
echo Gathering rack temperature data. . . please wait.
echo/
set pdulist=%pdu1_list%
set pdunode=31
set thisPDU=PDU1
:_CheckTemp
REM echo node ip=%pdunode%
REM echo nodelist=%pdulist%
REM echo -----------start--------------- 
for %%x in %pdulist% do ( 
set host=%%x
set rackname=!host:~0,1!
set host=!host:~1!
set pduIP=10.6.!host!.%pdunode%
set tempoutfile=%tempdir%^\r!rackname!%pdunode%_temp.txt

REM Check if PDU is reachable ======================
REM Start ping test to PDU
 ping -n 1 !pduIP! > %pingout%
 FINDSTR /C:"bytes=32" %pingout% >nul && (
  del/Q %pingout% &set noskip=1
) || (
 echo !thisPDU! not responding; skipping !thisPDU! on Rack-!rackname!
 echo $A0,1111111111111110,1.08,0.10,-->> !tempoutfile!
REM echo !date! !time:~0,5! --     Rack-!rackname!>> %templog% 
 del/Q %pingout% &set noskip=0
)

if !noskip!==1 (
%phppath%  !pduIP! !tempoutfile!
REM================
REM REM Telnet to PDU
REM start telnet.exe -f !tempoutfile! !pduIP!
REM ping -n 2 localhost >nul
REM cscript %pduvbs% >nul
REM ping -n 3 localhost >nul
REM REM tasklist /FI "IMAGENAME eq wscript.exe" 2>NUL | find /I /N "wscript.exe"2>NUL
REM REM if %ERRORLEVEL%==0 taskkill /f /im "wscript.exe"
REM TASKKILL /F /FI "IMAGENAME eq telnet.exe" /IM "telnet.exe" >nul
)
)

set pdulist=%pdu2_list%
REM echo -----------end ---------------
REM Check Next PDU =========================
if !pdunode!==31 (
  set pdunode=32
  set thisPDU=PDU2
REM echo -----------start part two ---------------
  goto _CheckTemp
)
REM End Check Next PDU =====================

REM echo === %date% %time% ============================= >> %tlog%
echo RACK#  PDU1°C PDU2°C ^(XX = no sensor; -- = no response from PDU^)>%t_summary%

REM set up print-noprint flag for previous PDU1 temp
set prevpdu1=0
set "temp1=  "

For %%a in (%tempdir%\r*3?_temp.txt) do (
set tempvar=NA
for /F %%j in ('FINDSTR /C:"$A0," %%a') do set tempvar=%%j
set tempvar=!tempvar:~-2!
set rackname=%%~na
REM set rackname=!rackname:_temp.txt=!
set pdunum=!rackname:~3,1!
set rackname=!rackname:~1,1!
REM echo|set /p ="Rack-!rackname! temperature is !tempvar! C" &echo/
if !pdunum!==1 (
  if !prevpdu1!==1 (
  echo Rack-!prevrack! !temp1!>>%t_summary%
)
REM save info for printing next time around
set prevpdu1=1
set temp1=!tempvar!
set prevrack=!rackname!
)
if !pdunum!==2 (
set "temp1=!temp1!     !tempvar!"
echo Rack-!rackname! !temp1!>>%t_summary%
set prevpdu1=0
set "temp1=  "
)
)
echo/
REM CLS
echo Gathering rack temperature data. . . Done!
echo/
echo === %date% %time% ============================= >> %tlog%
type  %t_summary%
type  %t_summary%>>%tlog%
del/Q %t_summary%
echo/ >> %tlog%
echo/ &echo A record of this has been saved in %tlog%
:_done

del/Q %pduvbs%
del/Q %tempdir%^\r*_temp.txt

:_fin
IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
pause
endlocal
REM ===================================================
REM 2016-03-02 Modified to check for php.exe before running
REM 2015-10-01 modified to use php script to get pdu temperature