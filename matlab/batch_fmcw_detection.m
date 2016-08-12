% filename: batch_fmcw_detection.m
% author: Paul Adams
%
function x = batch_fmcw_detection(varargin)
    % init and params
    dbv = @(x) 20*log10(abs(x));
    fname = dir('*radar_data*');
    [~, idx] = max([fname.datenum]);
    fname = fname(idx).name;

    % parse input args
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    oversample = get_arg(args, 'oversample', 5);
    window_func = get_arg(args, 'window_func', @rectwin);
    fname = get_arg(args, 'fname', fname);
    detrend_flag = get_arg(args, 'detrend_flag', false);

    sync_chan = 1;
    signal_chan = 2;

    % fetch data
    [x, fs] = audioread(fname);

    % sync pulses
    [pulse_idx, n_samp_pulse] = pulse_sync(x, sync_chan);

    % derived params
    n_pulse = length(pulse_idx) - 1;
    N = size(x, 1);
    t = (0:N - 1)/fs;
    n_fft = 2^nextpow2(n_samp_pulse)*8;
    f = (0:n_fft/2-1)*fs/n_fft;
    taper = repmat(window(window_func, n_samp_pulse)', n_pulse, 1);
    pulse_proto = 1 - abs(linspace(-1, 1, n_samp_pulse));

    %radar parameters
    c = 3E8; %(m/s) speed of light
    fstart = 2260E6; %(Hz) LFM start frequency for example
    fstop = 2590E6; %(Hz) LFM stop frequency for example
    BW = fstop-fstart; %(Hz) transmti bandwidth

    %range resolution
    rr = c/(2*BW);
    max_range = rr*n_samp_pulse/2;
    r = linspace(0, max_range, n_fft);

    % perform pulse compression
    % x(:, signal_chan) = filter(pulse_proto-0.5, 1, x(:, signal_chan));

    % form pulse matrix (optionally detrend)
    y = zeros(n_pulse, n_samp_pulse);
    for i = 1:n_pulse
        pulse = x((1:n_samp_pulse) + pulse_idx(i), signal_chan)';
        y(i, :) = pulse - detrend_flag*mean(pulse);
    end

    % clutter suppression
    dy = [zeros(1, n_samp_pulse); y(1:n_pulse - 1, :)];
    dyy = [zeros(2, n_samp_pulse); y(1:n_pulse - 2, :)];

    z2 = y - dy; % 2-pulse canceller
    z3 = y - 2*dy + dyy; % 3-pulse canceller

    if 1
        % Taper, FFT, Power
        Z1 = fft(y.*taper, n_fft, 2);
        Z1= dbv(Z1(:, 1:n_fft/2));

        im = imagr(Z1, 'x', r, 'y', t, 'fignum', 101, 'colormap', 'hot');
        xlabel('range bin');
        ylabel('time');
        %%xlim([0, 50]);
        title('Range Time Indicator - No clutter suppresion');

        % Taper, FFT, Power
        Z2 = fft(z2.*taper, n_fft, 2);
        Z2= dbv(Z2(:, 1:n_fft/2));

        im = imagr(Z2, 'x', r, 'y', t, 'fignum', 102, 'colormap', 'hot');
        xlabel('range bin');
        ylabel('time');
        %xlim([0, 50]);
        title('Range Time Indicator - 2-Pulse Canceller');
    end

    % Taper, FFT, Power
    Z3 = fft(z3.*taper, n_fft, 2);
    Z3= dbv(Z3(:, 1:n_fft/2));
    %Z3 = dbv(Z3);

    im = imagr(Z3, 'x', r, 'y', t, 'fignum', 103, 'colormap', 'hot');
    xlabel('range bin');
    ylabel('time');
    %xlim([0, 50]);
    title('Range Time Indicator - 3-Pulse Canceller');

    [~, range_gates] = max(Z3, [], 2);
    figure(3)
    plot(r(range_gates), t(pulse_idx(1:end-1)), 'o')
    xlabel('range [m]'); ylabel('time')
    %xlim([0, 50]);
    grid on;
    ax = gca;
    ax.YAxis.Direction = 'reverse';
    title(fname);
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

function val = get_arg(args, key, default)
    if isKey(args, key)
        val = args(key);
    else
        val = default;
    end
end

