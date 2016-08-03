function fmcw_playback()
    % init config
    fc = FmcwConfig('dev_type', 'zmq');
    dbv = @(x, n) 20*log10(abs(x(1:n/2)));

    % fetch data
    x = audioread(fc.fname);

    % sync pulses
    [pulse_idx, n_samp_pulse] = pulse_sync(x, fc.SYNC_CHAN);
    n_pulse = length(pulse_idx) - 1;
    n_frame = 100;
    fc.get_params(n_samp_pulse);
    r = linspace(0, fc.unambig_range, fc.n_fft);
    wf = zeros(n_frame, fc.n_fft/2);

    % init figures
    f2 = figure(2);
    f2.WindowStyle = 'docked';
    im = imagr(wf, 'x', 1:length(r), 'y', (0:n_frame-1),...
        'fignum', 101, 'colormap', 'hot');
    ylabel('time [s]'); xlabel('range [m]');
    title('Range Time Indicator - 3-pulse canceller');

    dontstopcantstopwontstop = true;
    i = n_frame - 1;
    while dontstopcantstopwontstop
        i = i + 1;
        y = x((1:n_samp_pulse) + pulse_idx(i), fc.SGNL_CHAN)';
        dy = x((1:n_samp_pulse) + pulse_idx(i - 1), fc.SGNL_CHAN)';
        dyy = x((1:n_samp_pulse) + pulse_idx(i - 2), fc.SGNL_CHAN)';
        z3 = y - 2*dy + dyy; % 3-pulse canceller

        % Taper, FFT, Power
        Z3 = dbv(fft(z3, fc.n_fft, 2), fc.n_fft);

        if i > n_frame
            wf = circshift(wf, [-1, 0]);
            idx = 1
        else
            idx = i;
        end
        wf(idx, :) = Z3;
        im.CData = wf;
        caxis([5, 30] + median(wf(:)));
        pause(0.1);
        dontstopcantstopwontstop = i < n_pulse;
    end
end

function [pulse_idx, n_samp_pulse] = pulse_sync(x, sync_chan)
    % perform pulse sync
    a = x(:, sync_chan) > 0; % square wave
    b = diff([0; a]) > 0.5; % true on rising edges
    c = diff([0; a]) < - 0.5; % true on falling edges

    rise_idx = find(b);
    fall_idx = find(c);
    n = min(length(rise_idx), length(fall_idx));
    ramp_idx = fall_idx(1:n) - rise_idx(1:n);

    % guaranteed shortest ramp time so we don't accidentally integrate over boundaries
    n_samp_pulse = min(ramp_idx);
    pulse_idx = rise_idx;
end

