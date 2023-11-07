#! /bin/bash

echo "host     :port"
for ip in $(seq 1 254); do
	for port in $2; do
		timeout .1 bash -c "echo >/dev/tcp/$1.$ip/$port" 2>/dev/null && echo "$1.$ip:$port"
	done
done

