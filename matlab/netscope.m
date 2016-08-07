function netscope(varargin)
    % playback params
    fs = 48000;
    n_bit = 32;
    n_frame_wf_buffer = 100;

    % parse input args
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    socket_ip = get_arg(args, 'socket_ip', '192.168.0.118');
    sub_topic = get_arg(args, 'sub_topic', 'raw');
    v2db = @(x) 20*log10(abs(x));
    dev = init_data_device(socket_ip, sub_topic)

    % main loop
    while true
        % update data
        v = cell2mat(cell(py.list(py.numpy.fromstring(dev.recv()))));
        if size(v, 1) > 1
            v = mean(v, 1);
        end

        [wf, pl, img] = init_figures(v)

        % update waterfall
        i_frame = i_frame + 1;
        n_frame = size(wf, 1);
        if i_frame <=  n_frame
            idx = i_frame;
        else
            idx = n_frame;
            wf = circshift(wf, [-1, 0]);
        end
        wf(idx, :) = v;

        %update plots
        % caxis([3, 30] + median(wf(:)));
        img.CData = wf;
        pl.YData = v;
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

function dev = init_data_device(socket_ip, sub_topic)
    tcp = sprintf('tcp://%s:5556', socket_ip);
    ctx = py.zmq.Context();
    dev = ctx.socket(py.zmq.SUB);
    dev.connect(tcp);
    dev.setsockopt(py.zmq.SUBSCRIBE, sub_topic);
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

function [wf, pl, img] = init_figures(v)
    n_frame = 100;

    % init figures
    f1 = figure(1);
    f1.WindowStyle = 'docked';
    t = (0:length(v) - 1)/48000;
    pl = plot(t, v, '.-');

    f2 = figure(2);
    f2.WindowStyle = 'docked';
    wf = zeros(n_frame, length(v));
    wf(1, :) = v;
    img = imagesc(wf);

end
