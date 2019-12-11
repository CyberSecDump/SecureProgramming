# SecureProgramming
Uploads for the Secure Programming Project

# Exploring the effectiveness of privilege separation in Bash - Results 

We deliberately introduced a vulnerability into both the monolithic and slave scripts: 

log="echo $inpipe >> users.log" 
eval $log 

This vulnerability stems from the unnecessary use of the eval built-in of Bash. 
In this instance, eval is used to execute the code 
stored in log after the contents of the variable inpipe are substituted in. inpipe contains unsanitised input from the user; 
if an attacker includes code in their input, there is a potential failure in separation of data and code. 
The intended use of the service is to provide a user access to their own shell on the remote system, as per telnet. However, using this vulnerability, an attacker can gain the privileges of the user running the service. 

# Monolithic implementation 

The monolithic implementation, by necessity, runs as root. As our vulnerability allows the attacker to execute arbitrary code, 
those root privileges are immediately exposed. Naturally, the severity of a vulnerability that immediately grants root privilege is extremely high. (Figure AI.1).

![alt text] (https://raw.githubusercontent.com/CyberSecDump/SecureProgramming/master/A1.1.png)

# Monitor-slave implementation

The same vulnerability also exists in the slave script in the monitor-slave implementation of the service, but the attacker is only able to gain the privileges of the slave and the limited environment it exists within. For example, some tools are not available (Figure AI.2), and while files within the chroot are accessible, files outside are not (Figure AI.3). While privilege separation has not prevented the vulnerability in the slave from being exploited, it has severely reduced the potential damage that an attacker can cause. The effectiveness of the technique depends heavily on the care taken in selecting the privileges available to the slave; the fewer privileges, the lower the risk. Likewise, ensuring the slave environment contains only the absolute minimum set of tools required for the slave’s operation is critical. 

# Appendix II – Exploiting Linux SUID executable tools that run as a root (nmap version 3.81 and earlier) 

In this scenario, the machine has a vulnerable nmap version; the SUID bit is set so the tool can run as root for efficient network scanning. A normal user can run nmap with the interactive option, then switch from the nmap prompt to a root Bourneb shell by using “!”. As shown in Figure AI.4 below, the effective UID is set to 0 (root) and the UID is still robot. This is an undesirable action.  

# Appendix III – Exploiting sudoers file to run linux commands as a root (sudo version earlier 1.8.28) 

Here, sudo with the -u option passes the user id as a username (or as #uid) to setresuid() and setreuid(). Thus, if a normal user runs [sudo -u root bash] or [sudo -u#0 bash], it will fail and show error message. This is desirable behaviour defined by the security policy configuration in the sudoers file; see Figures AI.5 and Figure AI.6. 

Interestingly, on the other hand, a normal user is able to escalate their privileges to root by running the sudo command and changing their UID to 0 (root), as shown in Figure AI.8. To illustrate, if a normal user passes a uid -1 or its equivalent value 4294967295, it will return -1. This results in unwanted behaviour in which sudo is running with uid = 0(root), and the -1 will keep the privilege remained (Miller, 2019).   
