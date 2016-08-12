#!/bin/bash
carrier_state=$(</sys/class/net/eth0/carrier)
not_up=1

while [ "$not_up" -eq 1 ]; do
    if [ "$carrier_state" -eq 1 ]; then
        ip addr add 192.168.2.108/255.255.255.0 dev eth0
        ip link set eth0 up
        not_up=0
        echo "success"
    else
        echo "ethernet not connected foo"
        sleep 10
    fi
done

echo "exit program"
