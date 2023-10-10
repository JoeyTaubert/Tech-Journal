# /bin/bash
# Simple loop practice
#


# seq 1 4 20
# list of numbers 1-20 by 4's
for i in $(seq 1 2 10)
do
	echo "L - ${i}"
	# double quotes makes it a string for echo 
	# Curly brackets are needed when calling a variable
done

mystring="Hello World"
echo "${#mystring}"
# Specify a "#" to get the length of the variable
echo "${mystring:0:4}"
# Echo characters 0-4 of mystring

for (( i=1; i<=${#mystring}; i++ ));
do
	echo "${mystring:1:$i}" >> mytxt.txt
done

while read -r line
do
	echo "$line"
done < mytxt.txt

# cat access.log | cut -d' ' -f1,4,6,7 | tr -d '[]"' | sort | uniq -c
# Grab certain fields based on space delimiter and remove special characters, then sort and count
