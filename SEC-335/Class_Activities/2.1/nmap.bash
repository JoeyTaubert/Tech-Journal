for ip in $(seq 2 50); do sudo nmap -n -vv -sn "10.0.5.${ip}"| grep "Nmap scan report for" | grep -v "down" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" >> sweep3.txt; done

