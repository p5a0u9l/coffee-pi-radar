#!/usr/bin/python2
# -*- coding: utf-8 -*-
# __file__ dopp-serv.py
# __author__ Paul Adams

# third-party imports
import numpy as np
from scipy.signal import hanning
import time
import json

# local imports
import sdr

# constants
M2FT = 3.28084
C_LIGHT = 3e8
BW = 300e6
N_FFT = 4096
FS = 48000

class Processor():
    def __init__(self):
        self.x = 0
        self.detects = []
        self.n_samp = 0
        self.report_dict = {}
        self.string = ''
        self.taper = np.zeros(1)
        self.t0 = 0

    def format(self):
        if not self.taper.any():
            self.taper = hanning(q.sig.shape[0])
        self.x = np.multiply(q.sig, self.taper)
        sdr.debug_hook(self.x, 'raw')

    def detect(self):
        self.detects = [np.argmax(self.x[50:-1]) + 50]

    def print_debug(self, doit):
        dt = q.time - self.t0
        self.t0 = q.time
        self.string += 'time: %.3f -> dt: %.3f ms -> detect: %d m\n' % (self.t0, dt*1e3, self.detects[0])
        if doit:
            print self.string,
            self.string = ''

    def process_pulses(self):
        self.format()
        self.x = sdr.lowpass(self.x)
        self.x = sdr.fft_filter(self.x, N_FFT)
        self.detect()

# init objects
q = sdr.Queue()
p = Processor()

def main():
    print 'RUN_DOPP: Queue initzd... Entering loop now... '

    while True:
        q.update_buff()

        if q.is_full():
            p.process_pulses()
            p.print_debug(True)
            q.re_init()

if __name__ == '__main__':
    main()
