#!/bin/bash
# file: kill-all.sh
# author: Paul Adams

pgrep python2 | xargs kill -9
pgrep jackd | xargs kill -9

