#!/usr/bin/python2
# -*- coding: utf-8 -*-
# __file__ sdr.py
# __author__ Paul Adams

# third-party imports
import numpy as np
import socket
from scipy.signal import lfilter
import zmq
import time

SYNC_CHAN = 0
SGNL_CHAN = 1
N_CHAN = 2
SUB_PORT = 5555
PUB_PORT = 5556
lpf_b = np.fromfile('/home/paul/ee542/lpf.npy')

class Zmq():
    def __init__(self):
        # setup zmq
        self.ctx = zmq.Context()
        self.sub = self.ctx.socket(zmq.SUB)
        self.sub.setsockopt(zmq.SUBSCRIBE, 'pcm_raw')
        self.ip = socket.gethostbyname('thebes')
        tcp = "tcp://%s:%s" % (self.ip, SUB_PORT)
        self.sub.connect(tcp)
        print 'SDR: Listening on %s' % tcp

        self.pub = self.ctx.socket(zmq.PUB)
        tcp = "tcp://%s:%s" % (self.ip, PUB_PORT)
        self.pub.bind(tcp)
        print 'SDR: Publishing on %s' % tcp

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

def debug_hook(data, topic):
    n_row = data.shape[0]
    z.pub.send('%s n_row: %s;;;%s' % (topic, str(n_row), data.tostring()))

def lowpass(x):
    if len(x.shape) == 1:
        axis = 0
    else:
        axis = 1

    return lfilter(lpf_b, 1, x, axis=axis)

def fft_filter(x, n_fft):
    if len(x.shape) == 1:
        x = np.abs(np.fft.fft(x, n=n_fft)[0:n_fft/2])**2
    else:
        x = np.abs(np.fft.fft(x, n=n_fft)[:, 0:n_fft/2])**2

    debug_hook(x, 'filt')
    return x

def averager(x):
    x = np.mean(x, axis=0)
    debug_hook(x, 'avg')
    return x

z = Zmq()
