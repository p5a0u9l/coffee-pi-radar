function im = imagr(z, varargin)

    if nargin > 1
        args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    else
        args = containers.Map(1,1);
    end
    cm = get_arg(args, 'colormap', 'hot');
    fignum = get_arg(args, 'fignum', 101);
    xdata = get_arg(args, 'x', 1:size(z, 2));
    ydata = get_arg(args, 'y', 1:size(z, 1));

    figure(fignum); clf;
    im = imagesc(xdata, ydata, z);
    cb = colorbar();
    colormap(cm);
    caxis([5, 30] + median(z(:)));

    x0 = cb.Position(1);
    dx = cb.Position(3);
    y0 = cb.Position(2);
    dy = cb.Position(4);

    if 0
        uicontrol('Style', 'slider', 'string', 'NF', ...
            'units', 'normalized',...
            'position', [x0 + 2*dx, y0 + dx, dx, 0.4*dy], ...
            'Min',0,'Max',50, 'Value', 5,...
            'SliderStep', [0.01, 0.05],...
            'callback', @cb_clim, 'tag', 'nf');

        uicontrol('Style', 'slider', 'string', 'NF', ...
            'units', 'normalized',...
            'position', [x0 + 2*dx, y0 + 0.5*dy, dx, 0.4*dy], ...
            'Min',1,'Max',10, 'Value', 1,...
            'SliderStep', [0.01, 0.1],...
            'callback', @cb_clim, 'tag', 'dr');
    end
    if 1
        uicontrol('Style', 'text', 'string', 'NF', ...
            'units', 'normalized',...
            'position', [x0 + 1.4*dx, y0, dx, dx], ...
            'Fontweight', 'bold', 'fontsize', 14);

        uicontrol('Style', 'pushbutton', 'string', 'cal',...
            'units', 'normalized',...
            'position', [x0 + 1.2*dx, y0 + 5*dx, dx, dx], ...
            'callback', @cb_clim, 'tag', 'cal');

        uicontrol('Style', 'pushbutton', 'string', 'Canceller',...
            'units', 'normalized',...
            'position', [x0 + 1.2*dx, y0 + 3*dx, dx, dx], ...
            'callback', @cb_canc, 'tag', 'Canc');

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
end

function val = get_arg(args, key, default)
    if isKey(args, key)
        val = args(key);
    else
        val = default;
    end
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

function cb_canc(src, ~)
    src.Parent.Children(end).Children.UserData.Canc = ~src.Parent.Children(end).Children.UserData.Canc;
end
