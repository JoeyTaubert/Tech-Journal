#! /bin/bash
# Description of the program
# Description of how to call it, and how to use it


: '
This is a multiline comment



'

var=$(ip addr | grep "inet" | grep "brd")

var2=$(echo "${var}" | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}')

echo "${var2}"
