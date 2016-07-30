fname = '../reference/ranging_files/running_outside_20ms.wav';
[x, fs] = audioread(fname);
dbv = @(x) 20*log10(abs(x));
a = x(:, 1) > 0; % square wave
b = diff([0; a]) > 0.5; % true on rising edges
c = diff([0; a]) < -0.5; % true on falling edges
rise_idx = find(b);
fall_idx = find(c);
ramp_idx = fall_idx - rise_idx;
win_func = @rectwin;
n_dwell = 2;

N = size(x, 1);
t = (0:N - 1)/fs;
t_rise = t(rise_idx);
n_samp_pulse = min(ramp_idx); % guaranteed shortest ramp time
n_pulse = length(rise_idx); % one chirp
n_frame = floor(n_pulse/n_dwell); % one integration period
n_samp_frame = n_frame*n_samp_pulse;
n_fft = 2^nextpow2(n_samp_pulse)*8;

f = (0:n_fft/2-1)*fs/n_fft;
y = zeros(n_pulse, n_samp_pulse);
for i = 1:n_pulse
    % add buffer sample for phasing
    y(i, :) = x((1:n_samp_pulse) + rise_idx(i), 2)';
end
%y = y - repmat(mean(y, 1), n_pulse, 1);
taper = repmat(window(win_func, n_samp_pulse)', n_pulse, 1);
Y = ifft(y.*taper, n_fft, 2);
%Y = ifft(y, n_fft, 2);
Y = dbv(Y(:, 1:n_fft/2));

imagr(Y, 'fignum', 100, 'colormap', 'hot')
xlabel('range bin [m]');
ylabel('time [sec]');

% 2 pulse cancelor RTI plot
y2 = diff(y, 2);
Y2 = ifft(y2.*taper(1:end-4, :), n_fft, 2);
%Y = ifft(y, n_fft, 2);
Y2= dbv(Y2(:, 1:n_fft/2));
imagr(Y2, 'fignum', 101, 'colormap', 'hot');
xlabel('range bin [m]');
ylabel('time [sec]');

%histogram(diff(t_rise));
