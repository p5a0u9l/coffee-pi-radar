#!/bin/bash
# file: wifi_rebooter.sh

# The IP for the server you wish to ping (8.8.8.8 is a public Google DNS server)
SERVER=8.8.8.8

# Only send two pings, sending output to /dev/null
ping -c2 ${SERVER} > /dev/null

# If the return code from ping ($?) is not 0 (meaning there was an error)
if [ $? != 0 ]; then
    # Restart the wireless interface
    echo "WIFI_REBOOT: `date` --> sensed link loss, rebooting..." >> /tmp/wifi_rebooter.log
    ip link set wlan0 down
    ip link set wlan0 up
    sleep 3  #settle
    ping -c2 ${SERVER} > /dev/null
    if [ $? == 0 ]; then
        echo "success!..." >> /tmp/wifi_rebooter.log
    else
        echo "failure :-(..." >> /tmp/wifi_rebooter.log
    fi
else
    echo "WIFI_REBOOT: `date` --> successful ping..." >> /tmp/wifi_rebooter.log
fi
