#!/usr/bin/python2
# -*- coding: utf-8 -*-

# imports
import numpy as np
from scipy.signal import lfilter, butter
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
        self.sub.connect(tcp)
        print 'Listening on %s' % tcp

        self.pub = self.ctx.socket(zmq.PUB)
        tcp = "tcp://%s:%s" % (self.ip, PUB_PORT)
        self.pub.bind(tcp)
        print 'Publishing on %s' % tcp

class Queue():
    def __init__(self):
        self.buff_idx = 0
        self.ref = []
        self.sig = []
        self.raw = []
        self.n_buff =  1
        self.time = []

    def re_init(self):
        self.buff_idx = 0
        self.ref = []
        self.sig = []

    def fetch_format(self):
        # fetch format data
        data = z.sub.recv()
        idx = data[0:100].find(';;;')
        header = data[0:idx]
        self.time = float(header[header.find(':')+1:header.find(';;;')])
        #import pdb; pdb.set_trace()
        x = (np.fromstring(data[idx+3::], np.int32)).astype(np.float)/2**31
        self.sig = x[SGNL_CHAN::2]
        self.ref = x[SYNC_CHAN::2]
        debug_hook(self.ref, 'clock')
        debug_hook(self.sig, 'signal')

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
            if not self.have_period:
                print 'pulse period acquired --> %d samples' % (self.period)
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
                if self.period.__class__ is list:
                    pass
                else:
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
        self.cfar_filt = [1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1]
        self.alpha = 0.6 # cfar scalar
        self.detects = []
        self.range_rez = C_LIGHT/(2*BW)
        self.n_samp = 0
        self.report_dict = {}
        self.range_lu = np.zeros((1, 1))
        self.ranges = []
        self.lpf_b, self.lpf_a = butter(6, 15e3, 'low', analog=True)
        self.prior = 0

    def lowpass(self):
        self.x = lfilter(self.lpf_b, self.lpf_a, self.x, axis=0)

    def reshape(self, pulses):
        self.n_samp = min([len(p) for p in pulses])
        self.x = np.zeros((len(pulses), self.n_samp))
        for i in range(len(pulses)):
            self.x[i, :] = pulses[i][0:self.n_samp]

        debug_hook(self.x, 'raw')

    def averager(self):
        self.x = np.mean(self.x, axis=0)
        debug_hook(self.x, 'avg')

    def canceller(self):
        if not self.prior.__class__ is int:
            nsamp = min([len(self.prior), self.x.shape[1]])
        else:
            nsamp = self.x.shape[1]
            self.prior = np.zeros((1, nsamp))

        for i in range(self.x.shape[0] - 1):
            self.x[i, 0:nsamp] = self.x[i+1, 0:nsamp] - self.prior[0:nsamp]
            self.prior = self.x[i+1, 0:nsamp]

        self.x = self.x[0:self.x.shape[0] - 1, :]

    def filter(self):
        self.x = np.abs(np.fft.ifft(self.x, n=self.n_fft)[:, 0:self.n_fft/2])**2
        debug_hook(self.x, 'filt')

    def detect(self):
        #cfar = signal.lfilter(self.cfar_filt, 1, self.x)
        self.detects = [np.argmax(self.x)]

    def transform(self):
        self.ranges = []
        if not self.range_lu.any():
            max_range = self.range_rez*self.n_samp/2
            self.range_lu = np.linspace(0, max_range, self.n_fft/2)

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

    def process_pulses(self, pulses):
        self.reshape(pulses)
        #self.lowpass()
        self.canceller()
        self.filter()
        self.averager()
        self.detect()
        self.transform()
        self.report()

# init objects
q = Queue()
s = Sync()
p = Processor()
z = Zmq()

def debug_hook(data, topic):
    n_row = data.shape[0]
    z.pub.send('%s n_row: %s;;;%s' % (topic, str(n_row), data.tostring()))

def print_debug():
    global t0
    dt = q.time - t0
    t0 = q.time
    print 'time: %.3f --> dt: %.3f ms --> pulses: %d --> samp: %d --> detect: %d m' % (t0, dt*1e3, len(s.pulses), s.period, p.ranges[0])

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
                p.process_pulses(s.pulses)
                z.pub.send('%s %s' % ('report', p.report_str))
                print_debug()
                s.pulses = [] # reset pulses
            else:
                pass

            q.re_init()


if __name__ == '__main__':
    main()
