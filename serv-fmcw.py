#!/usr/bin/python2
# -*- coding: utf-8 -*-

# imports
import numpy as np
import scipy
import socket
import pyaudio
import zmq
import time
import json

# constants
M2FT = 3.28084
C_LIGHT = 3e8
BW = 300e6
SYNC_CHAN = 0
SGNL_CHAN = 1
N_CHAN = 2
N_SAMP_BUFF_APPROX = 1000 # samples in callback buffer
N_FFT = 2048
FS = 48000
T_BUFFER_MS = 200
SUB_PORT = 5555
PUB_PORT = 5556

pa = pyaudio.PyAudio()

t0 = time.time()

class Zmq():
    def __init__(self):
        # setup zmq
        self.ctx = zmq.Context()
        self.sub = self.ctx.socket(zmq.SUB)
        self.sub.setsockopt(zmq.SUBSCRIBE, 'pcm_raw')
        self.ip = socket.gethostbyname('thebes')
        tcp = "tcp://%s:%s" % (self.ip, SUB_PORT)
        sub.connect(tcp)

        self.pub = self.ctx.socket(zmq.PUB)
        tcp = "tcp://%s:%s" % (self.ip, SUB_PORT)
        self.pub.bind(tcp)
        print 'Listening on %s' % tcp

class Queue():
    def __init__(self):
        self.buff_idx = 0
        self.ref = []
        self.sig = []
        self.raw = []
        self.n_buff =  1

    def re_init(self):
        self.buff_idx = 0
        self.ref = []
        self.sig = []

    def fetch_format(self):
        # fetch format data
        x = (np.fromstring(sub.recv(), np.int32)).astype(np.float)/2**31
        self.sig = np.hstack((self.sig, x[SGNL_CHAN::2]))
        self.ref = np.hstack((self.ref, x[SYNC_CHAN::2]))

    def update_buff(self):
        self.buff_idx += 1
        self.fetch_format()

    def is_full(self):
        return self.buff_idx == self.n_buff

class Sync():
    def __init__(self):
        self.have_period = False
        self.period = []
        self.edges = {}
        self.T = []
        self.pulses = []
        self.tail = np.array([0])
        self.head = []

    def get_edges(self, q):
        dref = np.diff((q.ref > 0).astype(np.float))
        # find indices of rising edges
        self.edges['rise'] = np.where(dref == 1)[0]

        # find indices of falling edges
        self.edges['fall'] = np.where(dref == -1)[0]

    def align_edges(self, q):
        # make sure fall follows rise, save head
        head_idx = np.argmax(self.edges['fall'] > self.edges['rise'][0])
        self.edges['fall'] = self.edges['fall'][head_idx:-1]
        head_idx = self.edges['rise'][0] - 1

        # make sure each vector is equi-length
        if len(self.edges['rise']) > len(self.edges['fall']):
            self.edges['rise'] = self.edges['rise'][0:len(self.edges['fall'])]
        else:
            self.edges['fall'] = self.edges['fall'][0:len(self.edges['rise'])]

        # try stitch previous tail to current head
        self.head = q.ref[0:head_idx]
        self.stitch(q)
        self.tail = q.ref[self.edges['fall'][-1] + 1:-1]

    def check_period(self):
        if self.period:
            prev_period = self.period
        else:
            prev_period = 0

        self.period = np.floor(np.mean(self.edges['fall'] - self.edges['rise']))
        rez = np.abs(self.period - prev_period)

        if rez < 5:
            print 'pulse period acquired --> %d samples' % (self.period)
            if not self.have_period:
                self.have_period = True
                self.T = self.period*FS

        elif self.have_period:
            self.have_period = False
            self.period = []
            print 'pulse period lost. residual --> %d samples' % (rez)

    def stitch(self, q):
        if self.tail.any():
            x = np.hstack((self.tail, self.head))

            # sync clock signal
            dx = np.diff((x > 0).astype(np.float))

            # find indices of rising edges
            rise = np.where(dx == 1)[0].tolist()

            while rise:
                r = rise.pop()
                self.pulses.append(q.sig[r:r+self.period])

    # given a buffer of audio frames, find the pulses within the clock signal and extract received chirp
    def extract_pulses(self, sig):
        rises = self.edges['rise'].tolist()
        while rises:
            idx = rises.pop()
            self.pulses.append(sig[idx:idx+self.period])

class Processor():
    def __init__(self):
        self.do_cancel = True
        self.n_fft = N_FFT
        self.x = 0
        self.cfar_filt = [1, 1, 1, 0, 0, 0, 1, 1, 1]
        self.alpha = 9 # cfar scalar
        self.detects = []
        self.range_rez = C_LIGHT/(2*BW)
        self.n_samp = 0
        self.drange = 1.0/self.n_fft/2
        self.report = {}

    def format(self, pulses):
        self.n_samp = min([len(p) for p in pulses])
        self.x = np.zeros(len(pulses), self.n_samp)
        for i in range(len(p)):
            self.x[i, :] = pulses[i]

    def averager(self):
        self.x = np.mean(self.x)

    def canceller(self):
        self.x = np.diff(self.x)

    def filter(self):
        self.x = 20*np.log10(np.abs(np.fft.fft(self.x, n=self.n_fft)[0:self.n_fft/2]))

    def detect(self):
        cfar = scipy.signal.lfilter(self.cfar_filt, 1, self.x)
        self.detects = np.where(self.x > self.alpha*cfar)

    def transform(self):
        if self.detects.any():
            self.ranges = self.detects*self.range_rez*self.drange

    def report(self):
        for i in self.detects:
            ts = time.time()
            self.report[ts] = {}
            self.report[ts]['gate'] = self.detects[i]
            self.report[ts]['range'] = self.ranges[i]

        self.report = json.dumps(self.report)

    def process_pulses(self, pulses):
        self.format(pulses)
        self.canceller()
        self.filter()
        self.averager()
        self.detect()
        self.transform()
        self.report()
        z.pub.send('%s %s' % ('report', self.report))

        global t0
        dt = time.time() - t0
        t0 = time.time()
        print 'Process queue... dt is %f --> pulse count is %d' % (dt, len(s.pulses))


# init objects
q = Queue()
s = Sync()
p = Processor()
z = Zmq()

def main():
    print 'Queue and Sync initzd... Entering loop now... '
    while True:
        q.update_buff()

        if q.is_full():
            s.get_edges(q)
            s.align_edges(q)
            s.check_period()

            if s.have_period:
                s.extract_pulses(q.sig)
                p.process_queue(s.pulses)
            else:
                pass

            q.re_init()


if __name__ == '__main__':
    main()
