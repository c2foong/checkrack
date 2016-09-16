@echo off
REM Output from this batch file is:
REM 1. outputfile is entervalue_dir\entervalue_out.txt
REM 2. log file is   %appdata%\checkrack.log              (logfile)
REM 3. entered value e.g. a                               (enteredvalue)
REM 4. rackname      e.g. USIQC-A-A                       (rackname)
REM 5. host IP       e.g. 172.30.46.1                     (host)
REM 6. host net      e.g. 172.30.46                       (hostnet)
REM 7. host          e.g. 1                               (nodeid)
REM 8. PDU3          e.g. 0 if none, 1 if PDU3 is present (pdu3)
REM 9. switch type   e.g. 1 if it is 1024D or 0 if 248B   (v22)
REM                       3 if only one switch as with switch ID as .25
REM 10.number of PC is default to 1                       (PCcnt)
REM 11.number of switches is default to 4                 (swcount)
REM 12.switch model  e.g. 124D; default to 0              (swtype)

REM tempdir    =temporary folder for runtime files
REM pingout    =temporary file to store PDU ping status
REM plinkcmd   =temporary plink command file
REM results    =temporary file for check status
REM pfile      =temporary plink output file
REM pfile1     =temporary plink output file
REM pfile2     =temporary plink output file
REM swfile     =temporary plink output file
REM swfile1    =temporary plink output file
REM telnetof   =temporary telnet output file
REM vbspgm     =temporary vbs script file

set tempdir=getinput_dir
set of=%tempdir%^\getinput_out.txt
set logfile=%appdata%\checkrack.log
set PCSUFFIX=-A
set nodeid=1
set pdu3=0
set v22=0
set swcount=4
set swtype=0

setlocal EnableDelayedExpansion
goto _starthere
if "%1"=="?" (
echo/
echo Syntax: %0           [default: no options; checks everything]
echo         %0 ?         [displays ^(this^) option list]
echo         %0 -c {Rack#}[checks everything and run cfg2time]
echo         %0 -u {Rack#}[checks everything and run BTCUS update ^& cfg2time]
goto _fin
)

REM Set up log file
:_starthere
REM Check if Rack# is entered in command-line
if "%1"=="" goto _askrack

set host=%1
if "%host%"=="" goto _askrack

goto _israckvalid

:_askrack
echo/
echo Enter Rack# to begin (for RMA racks, prefix with "R"; e.g. RA)
:_startover
echo/
set /p host="Enter Rack#: "
REM set /p host=<racknum.txt

:_israckvalid
set host=%host:~0,2%
if "%host:~1,1%"==" " (
set host=%host:~0,1%
)
echo You selected rack: %host%
REM timeout /t 5 --for debug only
REM check if Rack exists
REM findstr /r /i /c:"^[<space><tab>,;=]*:%1" %0>nul
FINDSTR /R /I /C:"^:%host%" %~n0%~x0>nul
if errorlevel 1 goto _error
goto _cont0

:_error
echo Rack is not defined. Please try another rack (or Ctrl-C to abort).
goto _startover

:_cont0

set PCcnt=1
set enteredvalue=%host%
goto %host%

:AA
set hostnet=10.6.90
set rackname=USIQC-AA
set v22=3
goto _contpc12

:AB
set hostnet=10.6.91
set rackname=USIQC-AB
set v22=1
goto _contpc13

:AC
set hostnet=10.6.92
set rackname=USIQC-AC
set v22=9
goto _contpc12

:AD
set hostnet=10.6.66
set rackname=USIQC-AD
goto _contpc12

:AE
set hostnet=10.6.66
set rackname=USIQC-AE
set v22=3
set nodeid=2
goto _contpc12

:AF
set hostnet=10.6.95
set rackname=USIQC-AF
goto _contpc13

:AG
set hostnet=10.6.96
set rackname=USIQC-AG
set v22=9
goto _contpc13

:1
set hostnet=172.30.39
set rackname=USIQC-1
goto _contpc12

:A
set hostnet=10.6.64
set rackname=USIQC-A
goto _contpc12

:B
set hostnet=10.6.65
set rackname=USIQC-B
goto _contpc12

:C
set hostnet=10.6.66
set rackname=USIQC-C
goto _contpc12

:D
set hostnet=172.30.43
set rackname=USIQC-D
goto _contpc12

:E
set hostnet=10.6.68
set rackname=USIQC-E
goto _contpc12

:F
set hostnet=10.6.69
set rackname=USIQC-F
goto _contpc12

:G
set hostnet=10.6.70
set rackname=USIQC-G
goto _contpc12

:H
set hostnet=10.6.71
set rackname=USIQC-H
goto _contpc12

:J
set hostnet=10.6.73
set rackname=USIQC-J
goto _contpc13

:K
set hostnet=10.6.74
set rackname=USIQC-K
goto _contpc13

:L
set hostnet=10.6.75
set rackname=USIQC-L
goto _contpc13

:M
set hostnet=10.6.76
set rackname=USIQC-M
goto _contpc13

:N
set hostnet=10.6.77
set rackname=USIQC-N
goto _contpc13

:O
set hostnet=10.6.78
set rackname=USIQC-O
goto _contpc13

:P
set hostnet=10.6.79
set rackname=USIQC-P
set v22=1
set swcount=2
goto _contpc13

:Q
set hostnet=10.6.80
set rackname=USIQC-Q
set v22=1
set swcount=2
goto _contpc13

:R
set hostnet=10.6.81
set rackname=USIQC-R
set v22=1
set swcount=2
goto _contpc13

:S
set hostnet=10.6.82
set rackname=USIQC-S
set v22=1
set swcount=2
goto _contpc13

:T
set hostnet=172.30.114
set rackname=USIQC-T
set v22=1
set swcount=2
goto _contpc13

:U
set hostnet=10.6.84
set rackname=USIQC-U
goto _contpc12

:V
set hostnet=10.6.85
set rackname=USIQC-V
REM set v22=3
goto _contpc12

:W
set hostnet=10.6.86
set rackname=USIQC-W
REM set v22=3
goto _contpc12

:X
set hostnet=10.6.87
set rackname=USIQC-X
set v22=9
goto _contpc12

:Y
set hostnet=10.6.88
set rackname=USIQC-Y
REM set v22=3
goto _contpc12

:Z
set hostnet=10.6.89
set rackname=USIQC-Z
set v22=1
set swcount=2
goto _contpc13

:RA
set hostnet=10.6.100
set rackname=USRMA
goto _contpc12

:RB
set hostnet=10.6.101
set rackname=USRMA-B
set v22=1
set swcount=2
set PCSUFFIX=-B
goto _contpc13

:RG
set hostnet=10.6.102
set rackname=USRMA-G
goto _contpc12


:RH
set hostnet=10.6.103
set rackname=USRMA-H
goto _contpc12

:_contpc13
set pdu3=1

:_contpc12
set host=%hostnet%.%nodeid%

REM Add the following to check for second PC
if !PCcnt!==1 goto _cont
echo/
echo %rackname% has more than one PC
set thisPC=A
set /p thisPC="Enter PC# A or B: "
if %thisPC%==A goto _cont
if %thisPC%==a goto _cont
if %thisPC%==B goto _contpc2
if %thisPC%==b goto _contpc2
goto _error
 
:_contpc2
set PCSUFFIX=-B
set host=%hostnet%.2
goto _cont

:_cont

IF EXIST %tempdir%^\NUL del /Q  %tempdir%^\*.txt
IF NOT EXIST %tempdir%^\NUL mkdir %tempdir% 


set rackname=%rackname%%PCSUFFIX%

(echo %of%)>%of%
(echo %logfile%)>>%of%
(echo %enteredvalue%)>>%of%
(echo %rackname%)>>%of%
(echo %host%)>>%of%
(echo %hostnet%)>>%of%
(echo %nodeid%)>>%of%
(echo %pdu3%)>>%of%
(echo %v22%)>>%of%
(echo %PCcnt%)>>%of%
(echo %swcount%)>>%of%
(echo %swtype%)>>%of%

REM echo/
REM echo 1-output parameter file is %of%
REM echo 2-output log file is %logfile%
REM echo 3-entered value is %enteredvalue%
REM echo 4-rackname is %rackname%
REM echo 5-host IP is %host%
REM echo 6-host net is %hostnet%
REM echo 7-host is %nodeid%
REM echo 8-PDU3 exists is %pdu3%
REM echo 9-switch type V22 is %v22%
REM echo 10-number of PC is %PCcnt%
REM echo 11-number of switches is %swcount%
REM echo 12-switch model is %swtype%

:_fin
REM IF EXIST %tempdir%^\NUL rmdir /S /Q %tempdir%
REM pause
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