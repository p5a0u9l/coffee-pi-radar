% filename: netscope.m
% author: Paul Adams

function netscope(varargin)
    % parse input args
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    %socket_ip =char(py.socket.gethostbyname('thebes')));
    socket_ip = get_arg(args, 'socket_ip', 'thebes');
    sub_topic = get_arg(args, 'sub_topic', 'raw');
    v2db = @(x) 10*log10(x);
    dev = init_data_device(socket_ip, sub_topic);
    not_init = true;
    figure(1); clf; figure(2); clf;
    i_frame = 0;

    % main loop
    while true
        % update data
        data = dev.recv();
        idx = strfind(char(data), ';;;');
        header = data(1:idx);
        data = data(idx+3:end); % remove header
        shape = regexp(char(header), '.*n_row: (\d+).*', 'tokens');
        n_row = str2double(shape{1});
        if n_row > 10
            n_row = 1;
        end
        v = cell2mat(cell(py.list(py.numpy.fromstring(data))));
        v = reshape(v, length(v)/n_row, n_row).';

        if strcmp(sub_topic, 'filt') || strcmp(sub_topic, 'avg')
            v = v2db(v);
        end

        if not_init
            not_init = false;
            [x, wf, pl, img] = init_figures(v);
            n_frame = size(wf, 1);
        end

        % update waterfall
        i_frame = i_frame + n_row;
        if i_frame <=  n_frame
            idx = i_frame;
        else
            idx = n_frame;
            wf = circshift(wf, [-n_row, 0]);
        end
        wf((0:n_row - 1) + idx, 1:length(v)) = v;
        x(1:n_row, 1:length(v)) = v;

        %update plots
        %caxis([6, 30] + median(wf(:)));
        img.CData = wf;
        if length(pl(1).YData) < length(x)
            [x, wf, pl, img] = init_figures(v);
        end
        for i = 1:n_row
            try
                pl(i).YData = x(i, :);
            catch
            end
        end
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
    dev.setsockopt(py.zmq.SUBSCRIBE, py.str(sub_topic));
end

function [x, wf, pl, img] = init_figures(v)
    n_frame = 500;

    % init figures
    f1 = figure(1);
    f1.WindowStyle = 'docked';
    t = (0:length(v) - 1)/48000;
    x = zeros(length(t), size(v, 1))';
    pl = plot(t*1000, v, '.-');
    grid on;
    xlabel('time [ms]')

    f2 = figure(2);
    f2.WindowStyle = 'docked';
    wf = zeros(n_frame, length(v));

    wf((0:size(v, 1) - 1) + 1, :) = v;
    %img = imagr(wf, 'fignum', 5);
    img = imagesc(wf);
    colorbar; colormap hot
    xlabel('sample')
    ylabel('time')
    %caxis([-20, 20])
    ui_init();
end

function cb_clim(src, evnt)
    obj = src.Parent.Children(end - 1);
    cur_value = obj.Limits;
    dval = 1;
    if strcmp(src.Tag, 'nf_up')
        new_val = cur_value + dval;
    elseif strcmp(src.Tag, 'nf_dn')
        new_val = cur_value - dval;
    elseif strcmp(src.Tag, 'cal')
        new_val = [3, 30] + median(src.Parent.Children(end).Children(1).CData(:));
    elseif strcmp(src.Tag, 'dr_up')
        new_val(1) = cur_value(1) - dval;
        new_val(2) = cur_value(2) + dval;
    elseif strcmp(src.Tag, 'dr_dn')
        new_val(1) = cur_value(1) + dval;
        new_val(2) = cur_value(2) - dval;
    elseif strcmp(src.Tag, 'dr')
        new_val = cur_value*src.Value;
    elseif strcmp(src.Tag, 'nf')
        new_val = cur_value + src.Value;
    end
    obj.Limits = new_val;
    caxis(new_val);
end

function ui_init()
    cb = colorbar();

    x0 = cb.Position(1);
    dx = cb.Position(3);
    y0 = cb.Position(2);
    dy = cb.Position(4);

    uicontrol('Style', 'text', 'string', 'NF', ...
        'units', 'normalized',...
        'position', [x0 + 1.4*dx, y0, dx, dx], ...
        'Fontweight', 'bold', 'fontsize', 14);

    uicontrol('Style', 'pushbutton', 'string', 'cal',...
        'units', 'normalized',...
        'position', [x0 + 1.2*dx, y0 + 5*dx, dx, dx], ...
        'callback', @cb_clim, 'tag', 'cal');

    uicontrol('Style', 'pushbutton', 'string', '+', ...
        'units', 'normalized',...
        'position', [x0 + 1.2*dx, y0 + dx, dx, dx], ...
        'callback', @cb_clim, 'tag', 'nf_up');

    uicontrol('Style', 'pushbutton', 'string', '-', ...
        'units', 'normalized',...
        'position', [x0 + 2.4*dx, y0 + dx, dx, dx], ...
        'callback', @cb_clim, 'tag', 'nf_dn');

    uicontrol('Style', 'text', 'string', 'DR', ...
        'units', 'normalized',...
        'position', [x0 + 1.4*dx, y0 + dy - dx, dx, dx], ...
        'Fontweight', 'bold', 'fontsize', 14);

    uicontrol('Style', 'pushbutton', 'string', '+', ...
        'units', 'normalized',...
        'position', [x0 + 1.2*dx, y0 + dy - 2*dx, dx, dx], ...
        'callback', @cb_clim, 'tag', 'dr_up');

    uicontrol('Style', 'pushbutton', 'string', '-',...
        'units', 'normalized',...
        'position', [x0 + 2.4*dx, y0 + dy - 2*dx, dx, dx], ...
        'callback', @cb_clim, 'tag', 'dr_dn');
end
