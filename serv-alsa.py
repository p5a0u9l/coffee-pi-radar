#!/usr/bin/python2
# -*- coding: utf-8 -*-
# __file__ serv-alsa.py
# __author__ Paul Adams

import socket
import pyaudio
import zmq
import time

N_SAMP_BUFF = 8*1082 # samples in callback buffer
N_CHAN = 2
FS = 48000
pa = pyaudio.PyAudio()

# setup zmq
ctx = zmq.Context()
pub = ctx.socket(zmq.PUB)
tcp = "tcp://%s:5555" % socket.gethostbyname('thebes')
pub.bind(tcp)

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
            time.sleep(0.1)

        # stop stream
        self.stream.stop_stream()
        self.stream.close()
        pa.terminate()

def main():
    a = Alsa()
    a.loop()

if __name__ == '__main__':
    main()
