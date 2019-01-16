#!/bin/sh

echo "Current deploy enviromment is $deploy_env"
echo "The build is $version"
echo "The password is $pass"

if $bool
then
	echo "Request is OK"
else
	echo "Request is deny"
fi