#!/bin/bash
# file: start-all.sh
# author: Paul Adams

/usr/bin/jackd -P70 -p16 -t2000 -d alsa -d hw:0 -p 128 -n 3 -r 48000 -s 2>/dev/null&
echo 'started jackd...'
sleep 1
/usr/bin/python2 /home/paul/ee542/alsa_serv.py $1 2>/dev/null&
# /usr/bin/python2 /home/paul/ee542/alsa_serv.py $1 &
echo "started serv-alsa.py N_SAMP=$1"
sleep 1
/usr/bin/python2 /home/paul/ee542/sdr_main.py $2

