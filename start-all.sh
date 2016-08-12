#!/bin/bash
# file: start-all.sh
# author: Paul Adams

/usr/bin/jackd -P70 -p16 -t2000 -d alsa -d hw:0 -p 128 -n 3 -r 48000 -s&
echo 'started jackd...'
sleep 1
/usr/bin/python2 /home/paul/ee542/serv-alsa.py&
echo 'started serv-alsa.py...'
sleep 1
/usr/bin/python2 /home/paul/ee542/serv-fmcw.py

