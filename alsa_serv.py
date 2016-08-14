#!/usr/bin/python2
# -*- coding: utf-8 -*-
# __file__ serv-alsa.py
# __author__ Paul Adams

# third-party imports
import socket
import pyaudio
import zmq
import time
import sys

# local imports
N_SAMP = int(sys.argv[1])
N_SAMP_BUFF = 10*N_SAMP
N_CHAN = 2
FS = 48000
PUB_PORT = 5555
pa = pyaudio.PyAudio()

# setup zmq
ctx = zmq.Context()
pub = ctx.socket(zmq.PUB)
tcp = "tcp://%s:%s" % (socket.gethostbyname('thebes'), PUB_PORT)
pub.bind(tcp)
print 'ALSA: Publishing on %s' % tcp

def alsa_callback(data, frames, time, status):
    pub.send('%s %s;;;%s' % ('pcm_raw', 'time:%f' % (time['current_time']), data))
    return (data, pyaudio.paContinue)

class Alsa():
    def __init__(self):
        self.stream = pa.open(format=pyaudio.paInt32,
                rate=FS, input=True, channels=N_CHAN,
                frames_per_buffer=N_SAMP_BUFF,
                stream_callback=alsa_callback)

    def loop(self):
        while self.stream.is_active():
            time.sleep(0.01)

        # stop stream
        self.stream.stop_stream()
        self.stream.close()
        pa.terminate()

def main():
    a = Alsa()
    a.loop()

if __name__ == '__main__':
    main()
