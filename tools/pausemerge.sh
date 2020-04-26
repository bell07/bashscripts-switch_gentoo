#!/bin/sh
for pid in $(pidof qemu-aarch64); do
	HLP=($(cat /proc/"$pid"/status | grep 'State'))
	STATE=${arr[1]}

	if [ "$1" == "resume" ]; then
		echo "Resume $pid in state $STATE"
		kill -CONT $pid
	else
		echo "Suspend $pid in state $STATE"
		kill -STOP $pid
	fi
done

