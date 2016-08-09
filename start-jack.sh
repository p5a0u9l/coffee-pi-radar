#!/bin/bash

jackd -P70 -p16 -t2000 -d alsa -p 128 -n 3 -r 48000 -s &
