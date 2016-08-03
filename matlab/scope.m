function scope(varargin)
    % playback params
    fs = 48000;
    n_chan = 2;
    n_bit = 16;

    % parse input args
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    oversample = get_arg(args, 'oversample', 2);
    socket_ip = get_arg(args, 'socket_ip', '192.168.0.122');
    display_on = get_arg(args, 'display_on', true);
    record_on = get_arg(args, 'record_on', false);
    dwell_ms = get_arg(args, 'dwell_ms', 100);
    window_func = get_arg(args, 'window_func', @rectwin);
    source = get_arg(args, 'source', 'zmq');
    record_duration = get_arg(args, 'record_duration', 10);

    T = dwell_ms/1000;
    dB_lim = [-0, 60];
    i_samp = 0;
    n_period = 1024;
    n_samp_frame = T*fs;
    % update playback params
    nframe = floor(n_samp_frame/n_period);
    n_samp_frame = nframe*n_period;
    T = n_samp_frame/fs;
    dontstopcantstopwontstop = true;

    % init source
    device = init_data_device(source, args, fs, n_bit, n_chan, T);

    w = repmat(window(window_func, n_samp_frame), 1, n_chan);

    % init figures
    if display_on
        v2db = @(x) 20*log10(abs(x));
        dt = T/n_samp_frame;
        t = 0:dt:T - dt;
        n_fft = oversample*2^nextpow2(n_samp_frame);
        df = fs/n_fft;
        f = 0:df:fs/2 - df;
        n_frame_wf_buffer = 500;
        i_frame = 0;
        t_slow = 0:T:n_frame_wf_buffer*T - T;
        wf = zeros(n_frame_wf_buffer, n_fft/2);
        f_ = figure(1);
        f_.WindowStyle = 'docked';
        f_.UserData.i_chan = 1;
        uicontrol('Style', 'pushbutton', 'string',...
            'channel toggle', 'position', [10, 10, 80, 30], 'callback', @cb_chan);
        subplot(211); l1 = plot(t*1e3, zeros(n_samp_frame, n_chan), '.-');
        xlabel('time [ms]'); ylabel('dB'); title('time view');
        ylim([-1.1, 1.1]);
        grid on;
        subplot(212); l2 = plot(f/1e3, zeros(n_fft/2, n_chan), '.-');
        xlabel('freq [kHz]'); ylabel('dB'); title('frequency view');
        ylim(dB_lim);
        grid on;

        f2 = figure(2);
        f2.WindowStyle = 'docked';
        img = imagesc(f/1e3, t_slow, wf);
        colorbar;
        caxis(dB_lim);
        ylabel('time [s]'); xlabel('freq [kHz]');
    end

    % main loop
    while dontstopcantstopwontstop
        % update data
        if strcmp(source, 'audio_card')
            if record_on
                device.recordblocking(record_duration);
                dontstopcantstopwontstop = false;
                fprintf('writing data to file...\n');
                fname = sprintf('%d_%s', round(now*10000), 'radar_data_cache.wav');
                audiowrite(fname, device.getaudiodata(), fs);
            else
                device.record(T);
                while device.get('TotalSamples') < n_samp_frame; end
                v = device.getaudiodata();
            end

        elseif strcmp(source, 'wav_file')
            v = device((1:n_samp_frame) + i_samp, :);
            end_samp = size(device, 1);
            i_samp = i_samp + n_samp_frame;
            if i_samp >= end_samp - n_samp_frame
                dontstopcantstopwontstop = false;
            end

        elseif strcmp(source, 'zmq')
            v = cell2mat(cell(py.numpy.fromstring(device.recv())));
            dvv = dv;
            dv = v;
            v = double([v(1:2:end); v(2:2:end)])';
            v = v./2^(n_bit - 1); %normalize
        end

        if display_on
            % update spectrum
            x = v.*w;
            %x(:, 1) = x(:, 1)/max(x(:, 1));
            %x(:, 2) = x(:, 2)/max(x(:, 2));
            %sound(v(:, 1));
            V = fft(x, n_fft);
            V = v2db(V(1:n_fft/2, :));

            % update waterfall
            i_frame = i_frame + 1;
            if i_frame <=  n_frame_wf_buffer
                idx = i_frame;
            else
                idx = n_frame_wf_buffer;
                wf = circshift(wf, [-1, 0]);
            end

            wf(idx, :) = V(:, f_.UserData.i_chan).';

            %update plots
            for i = 1:size(x, 2); l1(i).YData = x(:, i);    end
            for i = 1:size(V, 2); l2(i).YData = V(:, i);    end
            img.CData = wf;
            drawnow;
        end
    end
    if record_on
    end
end

function cb_chan(src, data)
    fig = src.Parent;
    if fig.UserData.i_chan == 1
        fig.UserData.i_chan = 2;
    else
        fig.UserData.i_chan = 1;
    end
end

function val = get_arg(args, key, default)
    if isKey(args, key)
        val = args(key);
    else
        val = default;
    end
end

function dev = init_data_device(source, args, fs, n_bit, n_chan, T)
    if strcmp(source, 'audio_card')
        device_id = 2;
        dev = audiorecorder(fs, n_bit, n_chan, device_id);
    elseif strcmp(source, 'wav_file')
        dev = audioread('radar_data_cache.wav');
    elseif strcmp(source, 'zmq')
        % set up connection
        tcp = sprintf('tcp://%s:5555', args('socket_ip'));
        ctx = py.zmq.Context();
        dev = ctx.socket(py.zmq.SUB);
        dev.connect(tcp);
        dev.setsockopt(py.zmq.SUBSCRIBE, '');
    else
        error('Unrecognized audio source')
    end
end

function pulse_idx = pulse_sync(x, sync_chan)
    % perform pulse sync
    a = x(:, sync_chan) > 0; % square wave
    b = diff([0; a]) > 0.5; % true on rising edges
    c = diff([0; a]) < - 0.5; % true on falling edges

    rise_idx = find(b);
    fall_idx = find(c);
    n = min(length(rise_idx), length(fall_idx));
    ramp_idx = fall_idx(1:n) - rise_idx(1:n);

    % guaranteed shortest ramp time so we don't accidentally integrate over boundaries
    pulse_idx = rise_idx;
end

