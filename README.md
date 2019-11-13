# SecureProgramming
Uploads for the Secure Programming Project

Exploring the effectiveness of privilege separation in Bash - Results 
We deliberately introduced a vulnerability into both the monolithic and slave scripts: 

# THIS CODE IS POORLY WRITTEN AND IS VULNERABLE TO CODE INJECTION 
log="echo $inpipe >> users.log" 
eval $log 


This vulnerability stems from the unnecessary use of the eval built-in of Bash. 
In this instance, eval is used to execute the code 
stored in log after the contents of the variable inpipe are substituted in. inpipe contains unsanitised input from the user; 
if an attacker includes code in their input, there is a potential failure in separation of data and code. 

The intended use of the service is to provide a user access to their own shell on the remote system, as per telnet. However, using this vulnerability, an attacker can gain the privileges of the user running the service. 

Monolithic implementation 
The monolithic implementation, by necessity, runs as root. As our vulnerability allows the attacker to execute arbitrary code, 
those root privileges are immediately exposed. Naturally, the severity of a vulnerability that immediately grants root privilege is 
extremely high. (Figure AI.1). 

Monitor-slave implementation

The same vulnerability also exists in the slave script in the monitor-slave implementation of the service, but the attacker is only able to gain the privileges of the slave and the limited environment it exists within. For example, some tools are not available (Figure AI.2), and while files within the chroot are accessible, files outside are not (Figure AI.3). While privilege separation has not prevented the vulnerability in the slave from being exploited, it has severely reduced the potential damage that an attacker can cause. The effectiveness of the technique depends heavily on the care taken in selecting the privileges available to the slave; the fewer privileges, the lower the risk. Likewise, ensuring the slave environment contains only the absolute minimum set of tools required for the slave’s operation is critical. 
