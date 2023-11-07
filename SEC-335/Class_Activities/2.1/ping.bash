for ip in $(seq 2 50); do ping -c 1 -w 1 "10.0.5.${ip}" | grep "icmp_seq=1"| grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" >> sweep.txt; done
