#! /bin/bash

hostfile=$1
portfile=$2
echo "host     :port"
for host in $(cat $hostfile); do
	regex="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
	if [[ $host =~ $regex ]]; then
	for port in $(cat $portfile); do
		timeout .1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && echo "$host:$port"
	done
	else 
		echo $host "is not a valid IP!"
	fi

done

