function scope(varargin)
    % playback params
    fs = 48000;
    n_bit = 32;

    % parse input args
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    socket_ip = get_arg(args, 'socket_ip', '192.168.0.118');
    n_pulse_samp = get_arg(args, 'n_pulse_samp', 1000);
    v2db = @(x) 20*log10(abs(x));
    dv = zeros(1, n_pulse_samp);

    % init source
    device = init_data_device(args);

    % init figures
    f2 = figure(2);
    f2.WindowStyle = 'docked';
    n_frame_wf_buffer = 500;
    i_frame = 0;
    wf = zeros(n_frame_wf_buffer, 1024);
    img = imagesc(wf); colorbar; colormap hot;
    ylabel('time [s]'); xlabel('range bin]');

    % main loop
    while true
        % update data
        v = cell2mat(cell(py.list(py.numpy.fromstring(device.recv()))));
        disp(length(v))
        if length(v) > n_pulse_samp
           v = v(1:n_pulse_samp);
        end

        v = v - dv(1:length(v));
        V = fft(v, 2048);
        V = v2db(V(1:1024));

        % update waterfall
        i_frame = i_frame + 1;
        if i_frame <=  n_frame_wf_buffer
            idx = i_frame;
        else
            idx = n_frame_wf_buffer;
            wf = circshift(wf, [-1, 0]);
        end
        wf(idx, :) = V;

        %update plots
        img.CData = wf;
        caxis([5, 30] + median(wf(:)));
        drawnow;
        dv = [v, zeros(1, n_pulse_samp - length(v))];
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
    tcp = sprintf('tcp://%s:5555', args('socket_ip'));
    ctx = py.zmq.Context();
    dev = ctx.socket(py.zmq.SUB);
    dev.connect(tcp);
    dev.setsockopt(py.zmq.SUBSCRIBE, '');
end


