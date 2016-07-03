% load/scale data
fname = fullfile('..', 'reference', 'charvat_doppler', 'Off of Newton Exit 17.wav');
[x, fs] = audioread(fname);
x = x(:, 2); % not the sync chan
scale = @(x) x/max(x)*0.8;
x_sc = scale(x);

% design params
N = length(x_sc);
MPH_CF = 2.23694;
FC = 2590E6; %(Hz) Center frequency (connected VCO Vtune to +5 for example)
C_LIGHT = 3e8; %(m/s) speed of light
lambda = C_LIGHT/FC;
v_max_mph = 50; % suppress speeds above 50 mph
% v_mph = MPH_CF*doppler*lambda/2;
doppler_max = 2*v_max_mph/(MPH_CF*lambda);
f_shift = 300;
df = fs/N;
f = 0:df:fs - df;

% Shift signal up f_shift Hz so can be more easily heard
rotation = exp(+1j*2*pi*f_shift/fs*(1:N)).';
y = real(x_sc.*rotation);
y_sc = scale(y);

% after shift spectrum
Y = fft(y_sc);

% design band-pass to suppress highs above doppler corresponding to 50 mph and
% suppress lows of negative freq image shifted up
if 1
    bpf = designfilt('bandpassfir', ...
        'FilterOrder', 300, ...
        'CutoffFrequency1',  1.5*f_shift, ...
        'CutoffFrequency2', f_shift + doppler_max, ...
        'SampleRate', fs, ...
        'Window', 'hamming');
    save bpf bpf
else
    load bpf
end

% Apply Filter, scale, and spectrum
z = filter(bpf.Coefficients, 1, y_sc);
z_sc = scale(z);
Z = fft(z_sc);

% write to disk
audiowrite('doppler_playback.wav', z_sc, fs);

%% Plots
figure(5);clf;
plot(f, 20*log10(abs(X)), '.'); hold on;
plot(f, 20*log10(abs(Y)), '.');
plot(f, 20*log10(abs(Z)), '.'); hold off;
xlim([0, 5000])

