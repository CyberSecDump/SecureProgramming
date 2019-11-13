#!/bin/bash

# read from pipe to-client and output to pipe from-client
# cat helps prevent blocking issues which would prevent nc from opening the port
cat to-client | nc -lk -p 6502 | cat > from-client &

while :
do
	echo "[Slave] Waiting for connection."	
	# do nothing until we get USER command from client
	inpipe=$(grep "USER" -m 1 < from-client)

	# grab the username
	usr=$(echo -n "$inpipe" | cut -d " " -f 2)

	# THIS CODE IS POORLY WRITTEN AND VULNERABLE TO CODE INJECTION
	# (and really logging users would be in the domain of the monitor)
	log="echo $inpipe >> users.log"
	eval $log

	echo "[Slave] Asking monitor to validate $usr"	
	# ask monitor via appropriate pipe
	# note that we perform no input validation here!
	echo -n $usr > to-monitor

	v=$(grep -c "OK" < to-slave)

	if [ $v -eq 1 ]
	then
		echo "[Slave] Monitor permits $usr. Dying..."	
		echo "SPAWN" > to-monitor
		
		# our usefulness has come to an end	
		exit 0
	fi
	
	echo "[Slave] Monitor says we can't log on as $usr"
	# if we got here then the user was invalid - disconnect and try again.
	echo "User $usr is not valid." > to-client
	sleep 2

	echo "KILL" > to-monitor

	# wait until netcat dead
	v=$(grep -c "KILLED" < to-slave)

	if [ $v -eq 1 ]
	then
		echo "[Slave] Requesting nc kill."
		sleep 2
		cat to-client | nc -lk -p 6502 | cat > from-client &
		echo "[Slave] New netcat."
	else
		echo "[Slave] Communication error with monitor. Terminating..."
		exit 0
	fi
done
	