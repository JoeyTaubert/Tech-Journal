#! /bin/bash
#
# Command format: ./dns-resolver.sh (FIRST_3_OCTET) (DNS_IP)
# 		  ./dns-resolver.sh 10.0.5 10.0.5.22

ip=$1
dns=$2

echo "DNS Resolution for $ip.0/24"

for i in $(seq 1 254); do
	nslookup "$ip.$i" "$dns" | grep "name"
done
