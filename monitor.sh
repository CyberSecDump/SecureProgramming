#!/bin/bash

# New slave
echo "[Monitor] Spawing slave."
(cd newroot && exec /sbin/chroot --userspec privsep . bash-static slave.sh) & 

while :
do
	# wait for a username from the slave
	usr=$(cat ./newroot/to-monitor)
	
	# Note that we perform input validation here
	# alphanumerics only please
	usr=${usr//[^a-zA-Z0-9]/}

	echo "[Monitor] Slave wants user $usr"
	
	# nab the "password file" (simulating authentication)
	passwdlines=$(cat /etc/passwd)

	# is the "password" (name) there?
	if [ $(echo -n "$passwdlines" | cut -d ":" -f 1 | grep -cx $usr) -eq 1 ]
	then
		# Yes - the slave may request we spawn bash for it.
		# The slave dies if this happens.
		echo "[Monitor] Slave may use usr $usr"
		echo "OK" > ./newroot/to-slave
		mayspawn=1
	else
		# No - the slave may request we kill nc, but not request that we spawn bash for it.	
		# The slave DOESN'T die if this happens.	
		echo "[Monitor] Slave may NOT use usr $usr"
		echo "X" >> ./newroot/to-slave
		mayspawn=0
	fi

	# wait for next slave directive, which should be either KILL or SPAWN
	# if it's not, the slave is broken... we should probably kill it and restart.
	next=$(cat ./newroot/to-monitor)
	
	# Note that we perform input validation here
	# uppercase alpha only please
	next=${next//[^A-Z]/}
	echo "[Monitor] Slave requests $next"
	
	if [ $next = "KILL" ]
	then
		echo "[Monitor] Killing netcat"
		## kill any processes owned by privsep named exactly "nc"
		kill $(pgrep -u privsep -x nc)
		echo KILLED >./newroot/to-slave

	elif [ $next = "SPAWN" ] && [ $mayspawn -eq 1 ]
	then
		# find $usr's home
		home=$(echo -n "$passwdlines" | grep $usr | cut -d ":" -f 6)
		echo "[Monitor] Spawning bash for $usr in $home"

		(cd $home && exec /sbin/runuser -u $usr bash /path/to/newshell.sh)	## update path

		# it should block - once it's done:
		echo "[Monitor] Shell for $usr has terminated."
		kill $(pgrep -u privsep -x nc)	

		sleep 1

		# New slave
		echo "[Monitor] Spawing slave."
		(cd newroot && exec /sbin/chroot --userspec privsep . bash-static slave.sh) & 

	else
		echo "[Monitor] Slave process is misbehaving."
		# kill the slave process - the command was invalid, and it may be compromised.
		kill $(pgrep -u privsep -x bash-static)
		kill $(pgrep -u privsep -x nc)

		sleep 1

		# New slave
		echo "[Monitor] Spawing slave."
		(cd newroot && exec /sbin/chroot --userspec privsep . bash-static slave.sh) & 
	fi

	echo "[Monitor] Waiting for new request."
	# all done - wait for new requests
done
