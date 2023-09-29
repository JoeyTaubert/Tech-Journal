#! /bin/bash
# string operations

mystring="Hello Bash World"
echo "My String: ${mystring}"

echo "My Length: ${#mystring}"

echo 8-"${mystring}"

echo $((8-"${#mystring}"))

echo "______"

echo "Loops"

touch myfile.txt

for (( i-1; i<=${#mystring}; i++ ));
do
	echo "${mystring:0:$i}" >> myfile.txt
done

for i in 1 2 3 5 6;
do
	printf '%2d\n' "${i}"
done

echo "______"

for i in $(seq 1 4 20)
do
	echo "${i}"
done

while read -r line
do 
	echo "W- ${line}"
done < myfile.txt
