function batch_doppler_example()
    %read the raw data .wave file here
    tic;
    fname = 'Off of Newton Exit 17.wav';
    [Y, fs] = audioread(fname);
    fprintf('Load audio data: %s...', fname); toc;

    % params/flags
    Tp = 0.1; %(s) integration period
    os_factor = 4; % oversample factor
    i_chan = 2; % the channel to process

    % dependant parameters
    n_samp = round(Tp*fs); %# of samples per pulse
    n_total = size(Y, 1);
    n_chan = size(Y, 2);
    n_total = floor(n_total/n_samp)*n_samp;
    n_dwell = n_total/n_samp;
    n_filt = os_factor*2^nextpow2(n_samp);

    x = +Y(1:n_total, i_chan); % Truncate to be N*L/N
    xif = reshape(x', n_samp, n_dwell).'; % let each row have n_samp samples
    X_db = process_doppler(xif, n_filt); % spectrogram
    plots(x, xif, X_db);
end

function X_db = process_doppler(x, n_filt)
    fprintf('Begin Doppler Process... \n');
    X = fft(x, n_filt, 2);
    X = X(:, 1:n_filt/2); % keep only first image
    X_db = 20*log10(abs(X));
end

function plots(x, xif, X_db)
    fprintf('Begin Plots... \n');
    set_clim = @(x) caxis([median(x(:)) + 30, max(x(:)) - 3]);
    n_total = length(x);
    [n_dwell, n_samp] = size(xif);
    n_filt = size(X_db, 2);

    % constants
    MPH_CF = 2.23694;
    FC = 2590E6; %(Hz) Center frequency (connected VCO Vtune to +5 for example)
    C_LIGHT = 3e8; %(m/s) speed of light
    FS = 44.1e3;

    df = FS/n_filt;
    f = 0:df:fs/2 - df; % spectrum

    dt = 1/FS;
    t = 0:dt:n_total*dt - dt;

    %calculate velocity
    lambda = C_LIGHT/FC;
    v_mph = MPH_CF*f*lambda/2;

    %calculate slow time
    Tp = n_samp*dt;
    slow_time = 0:Tp:n_total*dt - dt;

    % Time/Freq view
    figure(2); clf;
    subplot(211);
    plot(t, x);
    xlabel('time');
    title('Time/Freq view of Doppler Data')
    grid on;

    subplot(212);
    plot(f, 20*log10*abs(fftshift(fft(x))));
    xlabel('frequency Hz')
    xlim([0, 2e3])
    grid on;

    % complete image
    figure(3); clf;
    imagesc((1:n_samp)*dt, 1:n_dwell, volt2dB(xif));
    colorbar;
    xlabel('time'); ylabel('dwell');
    title(sprintf('Slow Time Image %d %d-sample dwells', n_dwell, n_samp))

    % complete image
    figure(4); clf;
    imagesc(X_db);
    colorbar;
    try; set_clim(X_db); catch; end
    title('Full Doppler Image')

    % plot charvat reference image
    load charvat;
    figure(5); clf
    imagesc(velocity*MPH_CF,time,v-mmax,[-50, 0]);
    colorbar;
    xlim([0 100]); %limit velocity axis
    xlabel('Velocity (mph)');
    ylabel('time (sec)');
    title('Charvat Reference Image')

    % truncated image
    figure(6); clf;
    imagesc(v_mph, slow_time, X_db);
    colorbar;
    try; set_clim(X_db); catch; end
    xlim([0, 100])
    xlabel('mph');
    ylabel('time (sec)');
    title(sprintf('Doppler Image to 100 mph - %d dwells at %0.3f sec. dwell time', ...
        n_dwell, n_samp*dt));
end
