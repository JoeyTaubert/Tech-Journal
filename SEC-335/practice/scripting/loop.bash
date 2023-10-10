# /bin/bash
#

text="/var/log/apache2/acccess.log"
#cat "${text}"

#while read -r line (replace cat with echo)
#do 

sortedcounter=$(cat "${text}" | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort | uniq -c)

count=$(echo "${sortedcounted}" | awk -F' ' '{print $7,$8}')

if [[ count -g 3]]
then
	"it is bigger"
fi


#done < "${text}"

#for i in $(cat mytxt.txt)
	# ^ Execute whatever is inside and return the result
#do
#	echo "${i}"
#done


