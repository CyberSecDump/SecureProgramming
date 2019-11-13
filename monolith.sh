#!/bin/bash

while :
do

	# read from pipe to-client and output to pipe from-client
	# cat helps prevent blocking issues which would prevent nc from opening the port
	cat to-client | nc -lk -p 6502 | cat > from-client &

	echo "[Monolith] Waiting for connection."	
	# do nothing until we get USER command from client
	inpipe=$(grep "USER" -m 1 < from-client)

	# THIS CODE IS POORLY WRITTEN AND IS VULNERABLE TO CODE INJECTION
	log="echo $inpipe >> users.log"
	eval $log

	# grab the username
	usr=$(echo -n "$inpipe" | cut -d " " -f 2)

	echo "[Monolith] Checking for user $usr"
	
	# nab the "password file" (simulating authentication)
	passwdlines=$(cat /etc/passwd)
	
	# is the "password" (name) there?
	if [ $(echo -n "$passwdlines" | cut -d ":" -f 1 | grep -cx $usr) -eq 1 ]
	then
		# Authentication OK
		echo "[Monolith] Authentication with $usr ok"
		
		# find $usr's home
		home=$(echo -n "$passwdlines" | grep $usr | cut -d ":" -f 6) 
		echo "[Monolith] Spawning bash for $usr in $home"

		(cd $home && exec /sbin/runuser -u $usr bash /path/to/newshell.sh)	 # update path

		# it should block - once it's done:
		echo "[Monolith] Shell for $usr has terminated."

	else
		# Authentication NOT ok	
		echo "[Monolith] Authentication with $usr FAILED"
	fi

	sleep 1
	kill $(pgrep -u root -x nc)

	echo "[Monolith] Waiting for new request."
	# all done - wait for new requests
done
