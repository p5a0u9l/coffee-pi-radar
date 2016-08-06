#!/usr/bin/python2
import numpy as np
import socket
import pyaudio
import zmq
import time

SYNC_CHAN = 0
SGNL_CHAN = 1
N_SAMP_PULS = 960 # nominal number of samples in 20 ms at 48k
N_SAMP_BUFF = 2048 # samples in callback buffer
FS = 48000
T_BUFFER_MS = 200

n_fft = 2048
pa = pyaudio.PyAudio()

# setup zmq
ctx = zmq.Context()
sock = ctx.socket(zmq.SUB)
sock.setsockopt(zmq.SUBSCRIBE, 'pcm_raw')
tcp = "tcp://%s:5555" % socket.gethostbyname('thebes')
sock.connect(tcp)
print 'Listening on %s' % tcp
t0 = time.time()


class Sync():
    def __init__(self):
        self.have_period = False
        self.period = []
        self.edges = {}
        self.T = []
        self.pulses = []
        self.tail = []
        self.head = []

    def get_edges(self, q):
        dref = np.diff(q.ref > 0)

        # find indices of rising edges
        self.edges['rise'] = np.where(dref > 0.5)[0]

        # find indices of falling edges
        self.edges['fall'] = np.where(dref < -0.5)[0]

    def stitch(self, q):
        if self.tail:
            x = np.hstack((self.tail, self.head))

            # sync clock signal
            dx = np.diff(x > 0)

            # find indices of rising edges
            rise = np.where(dx > 0.5)[0].tolist()

            while rise:
                r = rise.pop()
                self.pulses.append(q.sig[r:r+self.period])

    def align_edges(self, q):
        # make sure fall follows rise, save head
        head_idx = np.argmax(self.edges['fall'] > self.edges['rise'][0])
        self.edges['fall'] = self.edges['fall'][head_idx::]

        # make sure each vector is equi-length
        n = min([len(self.edges['rise']), len(self.edges['fall'])])
        self.edges['fall'] = self.edges['fall'][::n]
        self.edges['rise'] = self.edges['rise'][::n]

        # try stitch previous tail to current head
        self.head = q.ref[::head_idx]
        self.stitch()
        self.tail = q.ref[self.edges['fall'][-1] + 1::]

    def check_period(self):
        if self.period:
            prev_period = self.period
        else:
            prev_period = 0

        self.period = np.floor(np.mean(self.edges['fall'] - self.edges['rise']/2))
        rez = np.abs(self.period - prev_period)

        if rez < 5:
            if not self.have_period:
                print 'pulse period acquired --> %d samples' % (period)
                self.have_period = True
                self.T = self.period*FS

        elif self.have_period:
            self.have_period = False
            self.period = []
            print 'pulse period lost. residual --> %d samples' % (rez)

    # given a buffer of audio frames, find the pulses within the clock signal and extract received chirp
    def extract_pulses(self, sig):
        rises = self.edges['rise'].tolist()
        while rises:
            idx = rises.pop()
            self.pulses.append(sig[idx:idx+self.period])


def fft_mag_dB(x):
    X = np.fft.fft(x, n=n_fft)
    return 20*np.log10(np.abs(X[:n_fft/2]))

def process_queue():
    global t0
    dt = time.time() - t0
    t0 = time.time()
    print 'Process queue... dt is %f --> pulse count is %d' % (dt, len(s.pulses))

class Queue():
    def __init__(self):
        self.buff_idx = 0
        self.ref = []
        self.sig = []
        self.raw = []
        n = FS*T_BUFFER_MS/1000
        self.n_buff =  np.floor(n/N_SAMP_BUFF) # samples in callback buffer

    def re_init(self):
        self.buff_idx = 0
        self.ref = []
        self.sig = []

    def fetch_format(self):
        # fetch format data
        x = (np.fromstring(sock.recv(), np.int32)).astype(np.float)/2**31
        self.sig = np.hstack((self.sig, x[SGNL_CHAN::2]))
        self.ref = np.hstack((self.ref, x[SYNC_CHAN::2]))

    def update_buff(self, new_data):
        self.buff_idx += 1
        self.fetch_format()

    def is_full(self):
        return self.buff_idx == self.n_buff


# init
q = Queue()
s = Sync()

print 'Queue and Sync init''zd... Entering loop now... '
while True:
    q.update_buff()

    if q.is_full():
        s.get_edges(q)
        s.align_edges(q)
        s.check_period()
        if s.have_period():
            s.extract_pulses(q.sig)
            z = process_queue(s)
        else:
            pass

        q.re_init()



