#!/bin/sh

user=`whoami`

if [ $user == deploy ]
	then
		echo "Hello,my name is $user"
	else
		echo "Sorry,my name is $user"
fi

ip addr

cat /etc/system-release

free -m

df -h

py_cmd=`which python`

$py_cmd --version