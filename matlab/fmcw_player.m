function fmcw_player(varargin)
    % playback params
    fs = 48000;
    n_bit = 32;

    % parse input args
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    socket_ip = get_arg(args, 'socket_ip', '192.168.0.118');
    source = get_arg(args, 'source', 'zmq');
    n_pulse_samp = get_arg(args, 'n_pulse_samp', 1000);
    v2db = @(x) 20*log10(abs(x));
    dv = zeros(1, n_pulse_samp);

    T = 200/1000;
    n_period = 1024;
    n_samp_frame = T*fs;
    % update playback params
    nframe = floor(n_samp_frame/n_period);
    n_samp_frame = nframe*n_period;
    T = n_samp_frame/fs;

    % init source
    device = init_data_device(args);

    % init figures
    v2db = @(x) 20*log10(abs(x));
    dt = T/n_samp_frame;
    t = 0:dt:T - dt;
    n_fft = 2^nextpow2(n_samp_frame);
    %radar parameters
    c = 3E8; %(m/s) speed of light
    N = 900; %# of samples per pulse
    fstart = 2260E6; %(Hz) LFM start frequency for example
    fstop = 2590E6; %(Hz) LFM stop frequency for example
    BW = fstop-fstart; %(Hz) transmti bandwidth
    %range resolution
    rr = c/(2*BW);
    max_range = rr*N;
    R = 3.28084*linspace(0,max_range,n_fft/2);
    df = fs/n_fft;
    f = 0:df:fs/2 - df;
    n_frame_wf_buffer = 50;
    i_frame = 0;
    t_slow = 0:T:n_frame_wf_buffer*T - T;
    wf = zeros(n_frame_wf_buffer, n_fft/2);
    f2 = figure(2);
    f2.WindowStyle = 'docked';
    i_frame = 0;
    wf = zeros(n_frame_wf_buffer, n_fft/2);
    % img = imagesc(wf); colorbar; colormap hot;
    img = imagr(wf, 'x', R); colorbar; colormap hot;
    img.UserData.Canc = true;
    % xlim([0, 100]);
    ylabel('time [s]'); xlabel('range bin]');
    device.record(T);
    dv = 0;

    % main loop
    while true
        % update data
        if 1
            while device.get('TotalSamples') < n_samp_frame; end
            v = device.getaudiodata();
            device.record(T);
            [pulse_idx, n_samp_pulse] = pulse_sync(v, 1);
            valid_idx = abs(diff(pulse_idx)/2 - 940) < 50;
            pulse_idx = pulse_idx(valid_idx);
            a = [];
            for i = 1:length(pulse_idx)
                a = [a, v((1:940) + pulse_idx(1), 2)];
            end
            v = mean((a)');
        else
            v = cell2mat(cell(py.list(py.numpy.fromstring(device.recv()))));
        end

        % V = fft(v.*hanning(length(v))', n_fft, 2);
        if img.UserData.Canc
            x = v - dv;
        else
            x = v;
        end

        V = fft(x, n_fft, 2);
        V = v2db(V(1:n_fft/2));

        % update waterfall
        i_frame = i_frame + size(V, 1);
        n = size(V, 1);
        if i_frame <=  n_frame_wf_buffer
            idx = (0:n - 1) + i_frame;
        else
            idx = (-n + 1:0) + n_frame_wf_buffer;
            wf = circshift(wf, [-n, 0]);
        end
        wf(idx, :) = V;

        %update plots
        % caxis([3, 30] + median(wf(:)));
        img.CData = wf;
        [~, a] = max(V);
        title(sprintf('Distance: %d ft', round(R(a))))
        dv = v;
        drawnow;
    end
end

function val = get_arg(args, key, default)
    if isKey(args, key)
        val = args(key);
    else
        val = default;
    end
end

function dev = init_data_device(args)
    % set up connection
    if strcmp(args('source'), 'audio_card')
        device_id = 2;
        dev = audiorecorder(48000, 16, 2, device_id);
    elseif strcmp(args('source'), 'audio_card')
        tcp = sprintf('tcp://%s:5555', args('socket_ip'));
        ctx = py.zmq.Context();
        dev = ctx.socket(py.zmq.SUB);
        dev.connect(tcp);
        dev.setsockopt(py.zmq.SUBSCRIBE, '');
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

