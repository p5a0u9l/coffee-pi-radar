#!/usr/bin/python2
# -*- coding: utf-8 -*-
# __file__ sdr_main.py
# __author__ Paul Adams

import sys

MODE = sys.argv[1]

def main():
    if MODE == 'fmcw':
        import fmcw_serv
        fmcw_serv.main()
    elif MODE == 'dopp':
        import dopp_serv
        dopp_serv.main()

if __name__ == '__main__':
    main()
