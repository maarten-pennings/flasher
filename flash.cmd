@ECHO off
REM v3  2020 Jul 05  Maarten Pennings  Fixed bug in file absent test
REM v2  2017 Sep 09  Maarten Pennings  Fixed bug in flash successful test
REM v1  2017 Aug 26  Maarten Pennings  Created for mRPM distribution


SETLOCAL EnableExtensions EnableDelayedExpansion
REM 'EnableDelayedExpansion' enables !xx! next to %xx%.
REM The !xx! is executed for each occurrence, %xx% is executed per block.
REM A block is either everything between ( and ), or otherwise a line.


REM This script uses a trick to do the Unix assignment cccc=`CCCC`:
REM   FOR /F "tokens=* USEBACKQ" %%F IN (`CCCC`) DO SET cccc=%%F


CALL :mk_vbs


REM === Logging =============================================================


SET LOGFILE=%cd%\flash.log
copy /y NUL  %LOGFILE% > NUL
FOR /F "tokens=* USEBACKQ" %%F IN (`DATE /T`) DO SET log_date=%%F
FOR /F "tokens=* USEBACKQ" %%F IN (`TIME /T`) DO SET log_time=%%F
SET log_dir=%cd%
CALL :log "flash.cmd by Maarten Pennings"
CALL :log "  %log_date%; %log_time%; %log_dir%"
CALL :log ""


REM === Find the flash tool =================================================


SET tool_base=%cd%\
SET tool_full=!tool_base!esptool.exe
IF EXIST !tool_full! (
  CALL :log "Flash tool found - with this script"
  CALL :log "  !tool_full!"
  CALL :log ""
  GOTO :tool_done
)

SET tool_base=%appdata%\..\Local\Arduino15\packages\esp8266\tools\esptool\
IF EXIST !tool_base! (
  FOR /F "tokens=* USEBACKQ" %%F IN (`dir /b !tool_base!`) DO SET tool_sub=%%F\
  SET tool_full=!tool_base!!tool_sub!esptool.exe
  IF EXIST !tool_full! (
    CALL :log "Flash tool found - with Arduino IDE"
    CALL :log "  !tool_full!"
    CALL :log ""
    GOTO :tool_done
  ) ELSE (
    CALL :log "Flash tool not found"
    CALL :log "  This PC has Arduino with ESP8266 installed, but not !tool_full!"
    SET fail_msg=Download ESPTOOL.EXE from https://github.com/igrr/esptool-ck/releases and copy next to this script
    GOTO :abort
  )
) ELSE (
  CALL :log "Flash tool not found"
  CALL :log "  Failed to find ESPTOOL.EXE in: !cd!"
  SET fail_msg=Download ESPTOOL.EXE from https://github.com/igrr/esptool-ck/releases and copy next to this script
  GOTO :abort
)

:tool_done


REM === Find the firmware ===================================================


SET firm_base=%cd%\
SET firm_file=:
FOR /F "tokens=* USEBACKQ" %%F IN (`dir /b !firm_base!*.bin 2^> NUL`) DO SET firm_file=%%F
SET firm_full=!firm_base!!firm_file!
IF EXIST !firm_full! (
  CALL :log "Firmware found - with this script"
  CALL :log "  !firm_full!"
  CALL :log ""
  GOTO :firm_done
)

SET firm_base=%appdata%\..\Local\Temp\
FOR /F "tokens=* USEBACKQ" %%F IN (`dir /b /od !firm_base!arduino_build_* 2^> NUL`) DO SET firm_sub=%%F\
SET firm_base=!firm_base!!firm_sub!
FOR /F "tokens=* USEBACKQ" %%F IN (`dir /b /od !firm_base!*.bin 2^> NUL`) DO SET firm_file=%%F
SET firm_full=!firm_base!!firm_file!
IF EXIST !firm_full! (
  CALL :log "Firmware found - with Arduino IDE"
  CALL :log "  !firm_full!"
  CALL :log ""
) ELSE (
  CALL :log "Firmware not found"
  CALL :log "  Failed to find firmware: !cd!\*.bin"
  SET fail_msg=Download some *.bin file and copy next to this script
  GOTO :abort
)


:firm_done


REM === Get the COM ports ===================================================


SET com_all=
SET com_last=none
SET com_count=0
FOR /F "tokens=* USEBACKQ" %%F IN (`mode ^| find "COM"`) DO (
  SET com_line=%%F
  IF "Q!com_line:Status for device COM=!" == "Q!com_line!" (
    REM Line does not have form 'Status for device COMxx' - ignore
  ) ELSE (
    SET com_port=!com_line:~18,-1!
    SET com_last=!com_port!
    SET com_all=!com_all! !com_port! &REM with trainling space
    SET /a com_count=!com_count!+1
  )
)

CALL :log "COM ports found:%com_all%"

IF %com_count% EQU 0 (
  SET fail_msg=No COM ports found; please connect ESP8266/NodeMCU via USB to PC
  GOTO :abort
)

IF %com_count% EQU 1 (
  SET com_sel=!com_last!
  CALL :log "  Auto selected: !com_sel!"
  GOTO :selected
) ELSE (
  REM Next blocks should be in else, but the () break the %% in !com_all:%com_sel%=!
)

CALL :inputbox "Enter COM port for ESP8266/NodeMCU\n\nAvailable ports: %com_all%" "Enter COM port" "%com_last%"
SET com_sel=!input!
IF "Q%com_sel%" == "Q" (
  SET fail_msg=Aborted by user
  GOTO :abort
)

CALL :log "  User selected: !com_sel!"
IF "Q!com_all: %com_sel% =!" == "Q!com_all!" (
  SET fail_msg=Selected COM port '%com_sel%' not in list '%com_all%'
  GOTO :abort
)

:selected
CALL :log ""


REM === Execute flashing ===================================================


SET cmd=%tool_full%  -cd nodemcu  -cb 512000  -cp %com_sel%  -cf %firm_full%
CALL :log "Command"
CALL :log "  %cmd%"
CALL :msgbox "Confirm flashing of '%firm_file%' to '%com_sel%'.\n\nNote: flashing will take up to 30 seconds."  1  "Confirm"
SET cmd_ack=%input%
IF %cmd_ack% NEQ 1 (
  SET fail_msg=Aborted by user
  GOTO :abort
)

CALL :log ""
CALL :log "========================================================================================="
%cmd%  |  cscript //nologo %tee% %LOGFILE%
CALL :log "========================================================================================="
IF %ERRORLEVEL% GTR 0 (
  SET fail_msg=Flashing failed
  GOTO :abort
) 
SET cmd_result=NotFound
FOR /f "tokens=* delims=" %%g in ('findstr "100" %LOGFILE%') DO SET cmd_result=%%g
IF "Q!cmd_result:100=!" == "Q!cmd_result!" (
  SET fail_msg=Image was not flashed - try running script again
  GOTO :abort
)


REM === Terminate ===========================================================


:success
CALL :log ""
CALL :log "Completed successfully"
CALL :log "  See %LOGFILE% for a copy of this output"
CALL :msgbox "Success\n\nSee %LOGFILE% for log."  0  "Information"
CALL :rm_vbs
EXIT /B 0


REM === Subroutines =========================================================


:abort
CALL :log ""
CALL :log "Aborted"
CALL :log "  !fail_msg!"
CALL :log "  See %LOGFILE% for a copy of this output"
CALL :msgbox "%fail_msg%"  0  "Critical Error"
CALL :rm_vbs
EXIT /B 1


:log
REM Add entry to log file and console; call as   CALL :log "entry"
ECHO.%~1
ECHO.%~1 >> %LOGFILE%
EXIT /B


:mk_vbs
REM msgbox
SET msgbox="%temp%\flash.msgbox.vbs"
ECHO.WScript.Echo MsgBox(Replace(WScript.Arguments(0),^"\n^",vbNewline),WScript.Arguments(1),WScript.Arguments(2)) > %msgbox%
REM inputbox
SET inputbox="%temp%\flash.inputbox.vbs"
ECHO.WScript.Echo "A"^&InputBox(Replace(WScript.Arguments(0),^"\n^",vbNewline),WScript.Arguments(1),WScript.Arguments(2)) > %inputbox%
REM tee
SET tee="%temp%\flash.tee.vbs"
ECHO.Set file = CreateObject("Scripting.FileSystemObject").OpenTextFile(WScript.Arguments(i),8,True) > %tee%
ECHO.Do Until Wscript.StdIn.AtEndOfStream: line=Wscript.StdIn.ReadLine: Wscript.StdOut.WriteLine(line): file.WriteLine(line): Loop >> %tee%
EXIT /B


:rm_vbs
DEL %msgbox%
DEL %inputbox%
DEL %tee%
EXIT /B


:msgbox
REM Show a message with buttons; call as   CALL :msgbox "message" "buttons" "title"   reply comes in   %input%
FOR /f "tokens=* delims=" %%g in ('cscript //Nologo %msgbox% "%~1" "%~2" "flash.cmd - %~3"') DO SET input=%%g
EXIT /B


:inputbox
REM Prompt for input; call as   CALL :inputbox "prompt" "title" "default"  reply comes in   %input% (empty on cancel)
SET input=
FOR /f "tokens=* delims=" %%g in ('cscript //Nologo %inputbox% "%~1" "flash.cmd - %~2" "%~3"') DO SET input=%%g
SET input=%input:~1%
EXIT /B

