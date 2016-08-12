% filename: event_doppler.m
% author: Paul Adams
%
function dc = event_doppler(varargin)
    % config
    args = containers.Map(varargin(1:2:end), varargin(2:2:end));
    dc = DopplerConfig(args);
    dc.wav.record(dc.n_dwell_detect*dc.Tp);

    % Loop until EOF
    eof = false;
    while ~eof
        tic;
        x = fetch_and_format(dc);
        [v, i, n0] = reduce_doppler(x, dc);
        update_state(v, i, n0, dc);

        % Check for EOF and enforce real-time
        eof = dc.i_samp >= dc.n_total - dc.n_dwell_detect*dc.n_samp; % within one dwell of eof

        show_state(dc, v, n0);

        margin = dc.Tp*dc.n_dwell_detect - toc;
        if args('real_time')
            pause(margin);
        else
            drawnow
        end
    end
end

function x = fetch_and_format(dc)
    if dc.is_file
        start_samp = dc.i_samp + 1;
        dc.i_samp = start_samp + dc.n_samp*dc.n_dwell_detect - 1;
        if dc.debug_level >= 2; fprintf('Fetch and Format... samples: %d to %d...', start_samp, dc.i_samp); end
        [v, ~] = audioread(dc.wav, [start_samp, dc.i_samp]);
    else
        while dc.wav.get('TotalSamples') < dc.n_samp*dc.n_dwell_detect; end
        v = dc.wav.getaudiodata();
        dc.wav.record(dc.n_dwell_detect*dc.Tp);
    end
    x = reshape(v(:, dc.i_chan)', dc.n_samp, dc.n_dwell_detect).'; % let each row have n_samp samples
end

function [v, i, n0] = reduce_doppler(x, dc)
    if dc.debug_level >= 2; fprintf('Doppler Process... \n'); end
    x_w = bsxfun(@times, x, dc.taper); % apply taper to each row
    X = fft(x_w, dc.n_filt, 2); % fft along rows
    %X = 20*log10(abs(X(:, 1:dc.max_filt)));
    X = 20*log10(abs(X(:, 1:dc.n_filt/2)));
    n0 = mean(X(:));
    [v, i] = max(mean(X, 1)); % take mean over rows, then select the max filter bin
    dc.ax.Children(2).YData = mean(X, 1);
    dc.ax.Children(1).XData = dc.v_mph(i);
    dc.ax.Children(1).YData = v;
end

function update_state(v, i, n0, dc)
    if isempty(dc.noise_est)
        dc.noise_est = n0; % initial value
    else
        % current noise est. is weight last est. + weighted current measurement
        dc.noise_est = dc.alpha_n*dc.noise_est + dc.beta_n*n0;
    end

    dc.state.SpeedEst = nan;
    if n0 > dc.noise_est + dc.pass_thresh
        if ~dc.state.Passing % if changing state, inc. counter
            dc.state.VehicleCount = dc.state.VehicleCount + 1;
        end
        dc.state.Passing = true;
    elseif v > dc.noise_est + dc.actv_thresh
        dc.state.Passing = false; % turn off Passing
        dc.state.Active = true;
        dc.state.SpeedEst = dc.v_mph(i);
    end
    if v <= dc.noise_est + dc.actv_thresh; dc.state.Active = false; end

    % update debug variables
    if dc.debug_level >= 1
        dc.i_dwell = dc.i_dwell + 1;
        dc.state.n_i(dc.i_dwell) = n0;
        dc.state.n_a(dc.i_dwell) = dc.noise_est;
        dc.state.v_mph(dc.i_dwell) = dc.state.SpeedEst;
    end
end

function show_state(dc, v, n0)
    fprintf('Time: %.2f\tnoise: %.2f\tpower: %.2f\tPeak: %.2f\tPassing: %d\tActive: %d\tSpeed: %0.1f\tVehicle Count: %d\n',...
        dc.i_samp/dc.FS, dc.noise_est, n0, v, dc.state.Passing, dc.state.Active, round(dc.state.SpeedEst), dc.state.VehicleCount);
end
