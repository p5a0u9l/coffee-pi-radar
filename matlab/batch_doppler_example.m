function batch_doppler_example(varargin)
    % config
    keys = varargin(1:2:end);
    vals = varargin(2:2:end);
    opts = containers.Map(keys, vals);

    fname = fullfile('..', 'reference', 'charvat_doppler', 'Off of Newton Exit 17.wav');
    os_factor = 8; % oversample factor
    i_chan = 2; % the channel to process

    Tp = opts('Tp'); %(s) integration period
    do_animation = opts('animate');
    taper_func = opts('window');

    % Process/Plot
    tic;
    [v, x] = fetch_and_format(fname, Tp, i_chan); toc
    X = process_doppler(x, os_factor, taper_func);  toc

    error();
    if do_animation
        animate(X, Tp, length(v), opts);
    else
        plots(v, x, X); toc
    end
end

function [v, x] = fetch_and_format(fname, Tp, i_chan)
    fprintf('Fetch and Format...');
    [Y, fs] = audioread(fname);

    % dependant parameters
    n_samp = round(Tp*fs); %# of samples per pulse
    n_total = size(Y, 1);
    n_chan = size(Y, 2);
    n_total = floor(n_total/n_samp)*n_samp;
    n_dwell = n_total/n_samp;

    v = Y(1:n_total, i_chan); % Truncate to be N*L/N
    x = reshape(v', n_samp, n_dwell).'; % let each row have n_samp samples
end

function X = process_doppler(x, os_factor, taper_func)
    fprintf('Begin Doppler Process... \n');
    [n_dwell, n_samp] = size(x);
    n_filt = os_factor*2^nextpow2(size(x, 2));
    taper = window(taper_func, n_samp).';
    x_w = bsxfun(@times, x, taper);
    X = fft(x_w, n_filt, 2);
    X = X(:, 1:n_filt/2); % keep only first image
end

function plots(v, x, X)
    fprintf('Begin Plots... \n');
    set_clim = @(x) caxis([median(x(:)) + 30, max(x(:)) - 3]);
    volt2dB = @(x) 20*log10(abs(x));
    n_total = length(v);
    [n_dwell, n_samp] = size(x);
    n_filt = size(X, 2);

    % constants
    MPH_CF = 2.23694;
    FC = 2590E6; %(Hz) Center frequency (connected VCO Vtune to +5 for example)
    C_LIGHT = 3e8; %(m/s) speed of light
    fs = 44.1e3;

    df = fs/n_filt;
    doppler = 0:df:fs/2 - df; % doppler spectrum

    df = fs/n_total;
    f = -fs/2:df:fs/2 - df; % sampled spectrum

    dt = 1/fs;
    t = 0:dt:n_total*dt - dt;

    %calculate velocity
    lambda = C_LIGHT/FC;
    v_mph = MPH_CF*doppler*lambda/2;

    %calculate slow time
    Tp = n_samp*dt;
    slow_time = 0:Tp:n_total*dt - dt;

    X_db = volt2dB(X);

    % Time/Freq view
    if 1
        figure(2); clf;
        subplot(211);
        plot(t, v);
        xlabel('time');
        title('Time/Freq view of Doppler Data')
        grid on;

        subplot(212);
        plot(f, volt2dB(fftshift(fft(v))));
        xlabel('frequency Hz')
        xlim([0, 2e3])
        grid on;
    end

    % complete image
    if 0
        figure(3); clf;
        imagesc((1:n_samp)*dt, 1:n_dwell, volt2dB(x));
        colorbar;
        xlabel('time'); ylabel('dwell');
        title(sprintf('Slow Time Image %d %d-sample dwells', n_dwell, n_samp))
    end

    % slow image
    if 1
        figure(4); clf;
        imagesc(X_db);
        colorbar;
        try; set_clim(X_db); catch; end
        title('Full Doppler Image')
    end

    % plot charvat reference image
    if 0
        fname = fullfile('..', 'reference', 'charvat_doppler', 'charvat_results');
        load(fname);
        figure(5); clf
        imagesc(velocity*MPH_CF,time,v-mmax,[-50, 0]);
        colorbar;
        xlim([0 100]); %limit velocity axis
        xlabel('Velocity (mph)');
        ylabel('time (sec)');
        title('Charvat Reference Image')
    end

    % truncated image
    if 1
        figure(10); clf;
        imagesc(v_mph, slow_time, X_db);
        colorbar;
        try; set_clim(X_db); catch; end
        xlim([0, 50])
        xlabel('mph');
        ylabel('time (sec)');
        title(sprintf('Doppler Image to 100 mph - %d dwells at %0.3f sec. dwell time', ...
            n_dwell, n_samp*dt));
    end
end

function animate(X, Tp, n_total, opts)
    MPH_CF = 2.23694;
    FC = 2590E6; %(Hz) Center frequency (connected VCO Vtune to +5 for example)
    C_LIGHT = 3e8; %(m/s) speed of light

    set_clim = @(x) caxis([median(x(:)) + 40, max(x(:)) - 3]);
    volt2dB = @(x) 20*log10(abs(x));
    v = X.';
    v = ifft(v(:));

    [n_dwell, n_filt] = size(X);
    fs = 44100;
    dt = 1/fs;
    df = 0.5*fs/n_filt;
    doppler = 0:df:fs/2 - df; % doppler spectrum

    %calculate velocity
    lambda = C_LIGHT/FC;
    v_mph = MPH_CF*doppler*lambda/2;

    %calculate slow time
    slow_time = 0:Tp:n_total*dt - dt;

    X_db = volt2dB(X);

    f = figure(1); clf;
    if opts('image')
        imagesc(v_mph, slow_time, X_db);
        colorbar; colormap hot;
        try; set_clim(X_db); catch; end
        xlim([0, 45]);
        ylim([0, 5]);
        ax = gca;
        xlabel('mph');
        ylabel('time (sec)');
        title(sprintf('Doppler Image to 100 mph - %d dwells at %0.3f sec. dwell time', ...
            n_dwell, dt));
        for i = 1:n_dwell - 11
            ax.YLim = ax.YLim + Tp;
            pause(0.1);
        end
    else
        idx = 1:5;
        ax(1) = subplot(211);
        plot(v_mph, mean(X_db(idx, :)), '.');
        ax(1).NextPlot = 'add';
        plot(0, 0, 'r*');
        xlim([0, 100]);
        ylim([-50, 30]);
        grid on;
        xlabel('mph');
        ylabel('dB');
        ax(1).Title.String = sprintf('Time: %d sec. Speed: %d mph', ...
                    floor(opts('Tp')), 0);
        ax(1).Title.FontSize = 16;

        ax(2) = subplot(212);
        imagesc(v_mph, (1:5)*opts('Tp'), X_db(idx, :));
        colormap hot;
        caxis([-10, 30]);
        xlim([0, 100]);
        xlabel('mph');
        ylabel('sec');
        ax(2).Title.String = sprintf('Window: %s. Dwell Period: %d ms. Detection Period: %d ms', ...
                char(opts('window')), 1e3*(opts('Tp')), 1e3*5*opts('Tp'));

        if 0
            vid = VideoWriter('doppler_playback.avi');
            vid.FrameRate = round(1/opts('Tp'));
            vid.Quality = 90;
            open(vid);
        end

        for i = 2:n_dwell - 5
            tic;
            ydata = mean(X_db(idx + i, :));
            [v_peak, i_peak] = max(ydata);
            ax(1).Children(2).YData = ydata;
            ax(1).Title.String = sprintf('Time: %d seconds. Speed: %d mph', ...
                floor(i*opts('Tp')), round(v_mph(i_peak)));
            ax(1).Children(1).XData = v_mph(i_peak);
            ax(1).Children(1).YData = v_peak;

            ax(2).Children(1).CData = X_db(idx + i, :);
            ydata = opts('Tp')*(idx + i);
            ax(2).Children(1).YData = ydata;
            ax(2).YLim = ([min(ydata), max(ydata)]);

            if 0
                frame = getframe(f);
                writeVideo(vid, frame);
            end
            pause(opts('Tp') - toc);
        end
        if 0; close(vid); end
    end
end
