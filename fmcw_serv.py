#!/usr/bin/python2
# -*- coding: utf-8 -*-
# __file__ serv-fmcw.py
# __author__ Paul Adams

# third-party imports
import numpy as np
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
MAX_PERIOD_DELTA = 50


class Sync():
    def __init__(self):
        self.have_period = False
        self.period = []
        self.edges = {}
        self.T = []
        self.pulses ={}
        self.tail = {}
        self.tail['ref'] = np.zeros(2)
        self.head = {}
        self.stable_period_count = 0

    def get_edges(self, q):
        dref = np.diff((q.ref > 0).astype(np.float))
        # find indices of rising edges
        self.edges['rise'] = np.where(dref == -1)[0]

        # find indices of falling edges
        self.edges['fall'] = np.where(dref == +1)[0]

    def align_edges(self, q):
        # make sure fall follows rise, save head
        head_idx = np.argmax(self.edges['fall'] > self.edges['rise'][0])
        self.edges['fall'] = self.edges['fall'][head_idx::]
        head_idx = self.edges['rise'][0]

        # make sure each vector is equi-length
        if len(self.edges['rise']) > len(self.edges['fall']):
            self.edges['rise'] = self.edges['rise'][0:len(self.edges['fall'])]
        else:
            self.edges['fall'] = self.edges['fall'][0:len(self.edges['rise'])]

        # try stitch previous tail to current head
        self.head['ref'] = q.ref[0:head_idx]
        self.head['sig'] = q.sig[0:head_idx]
        self.stitch()
        self.tail['ref'] = q.ref[self.edges['fall'][-1]::]
        self.tail['sig'] = q.sig[self.edges['fall'][-1]::]

    def check_period(self):
        if self.period:
            prev_period = self.period
        else:
            prev_period = 0

        self.period = np.floor(np.mean(self.edges['fall'] - self.edges['rise'])).astype(np.int16)
        rez = np.abs(self.period - prev_period)

        if rez < MAX_PERIOD_DELTA:
            self.stable_period_count += 1
            if not self.have_period:
                print 'pulse period acquired --> %d samples' % (self.period)
                self.have_period = True
                self.T = self.period*FS

        elif self.have_period:
            self.stable_period_count = 0
            self.have_period = False
            self.period = []
            print 'pulse period lost. residual --> %d samples' % (rez)

    def stitch(self):
        if self.tail['ref'].any():
            x = np.hstack((self.tail['ref'], self.head['ref']))
            y = np.hstack((self.tail['sig'], self.head['sig']))

            # sync clock signal
            dx = np.diff((x > 0).astype(np.float))

            # find indices of rising edges
            rise = np.where(dx == -1)[0].tolist()

            while rise:
                r = rise.pop(0)
                if self.period.__class__ is list:
                    pass
                else:
                    # import pdb; pdb.set_trace()
                    ts = float(r)/self.period*(q.time - 1)
                    self.pulses[ts] = y[r:r+self.period]

    # given a buffer of audio frames, find the pulses within the clock signal and extract received chirp
    def extract_pulses(self, sig):
        rises = self.edges['rise'].tolist()
        while rises:
            idx = rises.pop(0)
            ts = float(idx)/self.period*q.time
            # import pdb; pdb.set_trace()
            self.pulses[ts] = sig[idx:idx + self.period]

class Processor():
    def __init__(self):
        self.x = 0
        self.detects = []
        self.range_rez = C_LIGHT/(2*BW)
        self.n_samp = 0
        self.report_dict = {}
        self.range_lu = np.zeros((1, 1))
        self.ranges = []
        self.prior = []
        self.string = ''
        self.t0 = 0

    def format(self, pulses):
        self.n_samp = min([len(p) for p in pulses.values()])
        self.x = np.zeros((len(pulses) , self.n_samp))
        k = pulses.keys()
        k.sort()
        for i, j in enumerate(k):
            self.x[i, :] = pulses[j][0:self.n_samp]

        sdr.debug_hook(self.x, 'raw')

    def canceller(self):
        (nrow, nsamp) = self.x.shape
        try:
            if len(self.prior) > 0:
                if len(self.prior) != nsamp:
                    nsamp = min([len(self.prior), self.x.shape[1]])
                    self.x = self.x[:, 0:nsamp]
                    self.prior = self.prior[0:nsamp]
            else:
                self.prior = np.zeros(nsamp)
        except:
            import pdb; pdb.set_trace()

        y = self.x.copy()
        dy = np.vstack((self.prior, y[0:nrow-1, :]))
        self.x = y - dy
        self.prior = y[nrow-1, :]

    def detect(self):
        #cfar = signal.lfilter(self.cfar_filt, 1, self.x)
        self.detects = [np.argmax(self.x[50:-1]) + 50]

    def transform(self):
        self.ranges = []
        if not self.range_lu.any():
            max_range = self.range_rez*self.n_samp/2
            self.range_lu = np.linspace(0, max_range, N_FFT/2)

        if len(self.detects) > 0:
            for d in self.detects:
                self.ranges.append(self.range_lu[d])

    def report(self):
        self.report_dict = {}
        for i in range(len(self.detects)):
            ts = time.time()
            self.report_dict[ts] = {}
            self.report_dict[ts]['gate'] = self.detects[i]
            self.report_dict[ts]['range'] = self.ranges[i]

        self.report_str = json.dumps(self.report_dict)

    def print_debug(self, doit):
        dt = q.time - self.t0
        self.t0 = q.time
        self.string += 'time: %.3f -> dt: %.3f ms -> pulses: %d -> samp: %d stable -> %d -> detect: %d m\n' % (self.t0, dt*1e3, len(s.pulses), s.period, s.stable_period_count, p.ranges[0])
        if doit:
            print self.string,
            self.string = ''

    def process_pulses(self, pulses):
        self.format(pulses)
        self.x = sdr.lowpass(self.x)
        self.canceller()
        self.x = sdr.fft_filter(self.x, N_FFT)
        self.x = sdr.averager(self.x)
        self.detect()
        self.transform()
        self.report()

# init objects
q = sdr.Queue()
s = Sync()
p = Processor()

def main():
    print 'RUN_FMCW: Queue and Sync initzd... Entering loop now... '

    while True:
        q.update_buff()

        if q.is_full():
            s.get_edges(q)
            s.align_edges(q)
            s.check_period()

            if s.have_period:
                s.extract_pulses(q.sig)
                p.process_pulses(s.pulses)
                p.print_debug(True)
                s.pulses = {} # reset pulses
            else:
                pass

            q.re_init()

if __name__ == '__main__':
    main()
