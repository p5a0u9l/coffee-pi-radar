function record_sample(T)
    device_id = 2;
    fs = 44100;
    chan = 1;
    n_bit = 16;
    a = audiorecorder(fs, n_bit, chan, device_id);
    fprintf('recording %.2f seconds starting now ...\n', T);
    a.recordblocking(T);
    x = a.getaudiodata();
    fprintf('writing to file...\n');
    audiowrite('track.wav', x, fs);
end
