#!/bin/bash

pgrep python2 | xargs kill -9
pgrep jackd | xargs kill -9

