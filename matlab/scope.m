function scope()
    device_id = 3;
    fs = 44100;
    chan = 1;
    n_bit = 16;
    T = 100/1000;
    dB_lim = [-40, 60];
    n_samp_frame = T*fs;

    w = window(@rectwin, n_samp_frame);
    dt = T/n_samp_frame;
    t = 0:dt:T - dt;
    n_fft = 2^nextpow2(n_samp_frame);
    df = fs/n_fft;
    f = 0:df:fs/2 - df;
    wav = audiorecorder(fs, n_bit, chan, device_id);
    wav.record(T);

    % waterfall
    v2db = @(x) 20*log10(abs(x));
    n_frame = 500;
    i_frame = 0;
    t_slow = 0:T:n_frame*T - T;
    wf = zeros(n_frame, n_fft/2);

    % init figures
    f_ = figure(1);
    f_.WindowStyle = 'docked';
    subplot(211); l1 = plot(t*1e3, zeros(n_samp_frame, 1), '.-'); xlabel('time [ms]'); ylabel('dB'); title('time view');
    ylim([-1.1, 1.1]); grid on;
    subplot(212); l2 = plot(f/1e3, zeros(n_fft/2, 1), '.-'); xlabel('freq [kHz]'); ylabel('dB'); title('frequency view');
    ylim(dB_lim); grid on;

    f_ = figure(2);
    f_.WindowStyle = 'docked';
    img = imagesc(f/1e3, t_slow, wf);
    colorbar; caxis(dB_lim);
    ylabel('time [s]'); xlabel('freq [kHz]');

    while true
        while wav.get('TotalSamples') < n_samp_frame; end
        v = wav.getaudiodata();
        wav.record(T);
        % compute
        i_frame = i_frame + 1;
        if i_frame <=  n_frame
            idx = i_frame;
        else
            idx = n_frame;
            %img.YData = t_slow + (i_frame - n_frame)*T;
            wf = circshift(wf, [-1, 0]);
        end

        x = v.*w;
        %sound(x);
        V = fft(x, n_fft);
        V = v2db(V(1:n_fft/2));
        wf(idx, :) = V.';

        %update plot
        l1.YData = x;
        l2.YData = V;
        img.CData = wf;
        drawnow;
    end
end
