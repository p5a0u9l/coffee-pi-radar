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


buffer_interval = 200 # in milliseconds
fs_kHz = 48
n = fs_kHz*buffer_interval
n_buff_queue =  np.floor(n/N_SAMP_BUFF) # samples in callback buffer

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

def fetch_format(data):
    # fetch format data
    x = (np.fromstring(data, np.int32)).astype(np.float)/2**31
    y = x[SGNL_CHAN::2]
    ref = x[SYNC_CHAN::2]
    return (ref, y)

def pulse_sync(ref, y):
    # sync clock signal
    dref = np.diff(ref)

    # find indices of rising edges
    rdx = np.where(dref > 0.5)[0]

    # find indices of falling edges
    fdx = np.where(dref < -0.5)[0]

    # failure case
    if len(rdx) == 0:
        return []

    # case where early rdx contains full pulse
    print len(rdx), len(fdx)
    rise_first = rdx[0] < fdx[0]
    two_falls = len(fdx) > 1
    two_rises = len(rdx) > 1

    if rise_first:
        pulse[0] = z[rdx[0]:rdx[0] + N_SAMP_PULS]
        if two_rises:
            stitch['late'] = z[rdx[1]:N_SAMP_BUFF]
        else:
            stitch['late'] = []

    elif two_falls:
        pulse[1] = z[rdx[0]:fdx[1]]
        pulse[0] = np.hstack((stitch['late'], z[0:fdx[0]]))
        stitch['late'] = []

    else:
        pulse[0] = np.hstack((stitch['late'], z[0:fdx[0]]))
        stitch['late'] = z[rdx[0]:N_SAMP_BUFF]

    return pulse

def fft_mag_dB(x):
    X = np.fft.fft(x, n=n_fft)
    return 20*np.log10(np.abs(X[:n_fft/2]))

def process_queue(ref, y):
    global t0
    dt = time.time() - t0
    t0 = time.time()
    print 'Process queue... dt is %f' % (dt)


# init
buffdx = 0
ref = np.array([])
y = np.array([])

print 'Entering loop now... %d' % (n_buff_queue)
while True:
    new_data = fetch_format(sock.recv())

    ref = np.hstack((ref, new_data[0]))
    y = np.hstack((y, new_data[1]))

    buffdx += 1
    if buffdx % n_buff_queue  == 0:
        z = process_queue(ref, y)

        # re init
        buffdx = 0
        ref = np.array([])
        y = np.array([])


