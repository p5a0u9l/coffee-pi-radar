#!/usr/bin/python2
import socket
import pyaudio
import zmq
import time

N_SAMP_BUFF = 4*2048 # samples in callback buffer
pa = pyaudio.PyAudio()

# setup zmq
ctx = zmq.Context()
sock = ctx.socket(zmq.PUB)
tcp = "tcp://%s:5555" % socket.gethostbyname('thebes')
sock.bind(tcp)

def callback(data, frames, time, status):
    pack = '%s %s' % ('pcm_raw', data)
    sock.send(pack)

    return (data, pyaudio.paContinue)

stream = pa.open(format=pyaudio.paInt32,
        rate=48000, input=True, channels=2,
        frames_per_buffer=N_SAMP_BUFF,
        stream_callback=callback)

while stream.is_active():
    time.sleep(0.1)

# stop stream
stream.stop_stream()
stream.close()

# close pyaudio/zmq
pa.terminate()
