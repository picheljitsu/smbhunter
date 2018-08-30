# smbhunter
Overview
SMB Hunter is a blue team tool that can be used to detect SMB lateral movement.  My future plans are to open this up to more than just SMB monitoring, but for now, the main goal is to detect command line and network connections made using tools like psexec.  Thus far, testing has only been done through psexec.

SMB Hunter injects a DLL into a suspended svchost process and any time an SMB connection is initiated via command line, a log entry is sent in Comma Seperated Value format to a Powershell log controller.  CSV format allows the controller to easily translate the data into other formats.  

Technicals
The DLL in c++ to be lightweight.  The suspended process is created using FuzzySec's Invoke-CreateProcess cmdlet. Injection is performed via PowerSploit's Invoke-ReflectivePEInjection cmdlet. Both are obfuscated to bypass AV.

![alt text](https://github.com/picheljitsu/smbhunter/blob/master/smbhunter_controller.png)
