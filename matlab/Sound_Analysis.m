%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Sound Analysis with MATLAB Implementation    %
%                                                %
% Author: M.Sc. Eng. Hristo Zhivomirov  04/01/14 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get a section of the sound file
[x, fs] = audioread('track.wav'); % read the file
x = x(:, 1);                    % get the first channel
N = length(x);                  % signal length
t = (0:N-1)/fs;                 % time vector

% plot the signal waveform
f_ = figure(1); f_.WindowStyle = 'docked';
plot(t, x, 'r')
xlim([0 max(t)])
ylim([-1.1*max(abs(x)) 1.1*max(abs(x))])
grid on
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Time, s')
ylabel('Signal amplitude')
title('The signal in the time domain')

% plot the signal spectrogram
f_ = figure(2); f_.WindowStyle = 'docked';
spectrogram(x, 1024, 3/4*1024, [], fs, 'yaxis')
grid on
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Time, s')
ylabel('Frequency, Hz')
title('Spectrogram of the signal')

h = colorbar;
set(h, 'FontName', 'Times New Roman', 'FontSize', 14)
ylabel(h, 'Magnitude, dB')

% spectral analysis
win = hanning(N);           % window
K = sum(win)/N;             % coherent amplification of the window
X = abs(fft(x.*win))/N;     % FFT of the windowed signal
NUP = ceil((N+1)/2);        % calculate the number of unique points
X = X(1:NUP);               % FFT is symmetric, throw away second half
if rem(N, 2)                % odd nfft excludes Nyquist point
  X(2:end) = X(2:end)*2;
else                        % even nfft includes Nyquist point
  X(2:end-1) = X(2:end-1)*2;
end
f = (0:NUP-1)*fs/N;         % frequency vector
X = 20*log10(X);            % spectrum magnitude

% plot the signal spectrum
f_ = figure(3); f_.WindowStyle = 'docked';
semilogx(f, X, 'r')
xlim([0 max(f)])
grid on
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
title('Amplitude spectrum of the signal')
xlabel('Frequency, Hz')
ylabel('Magnitude, dB')

% plot the signal histogram
f_ = figure(4); f_.WindowStyle = 'docked';
histogram(x)
xlim([-1.1*max(abs(x)) 1.1*max(abs(x))])
grid on
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Signal amplitude')
ylabel('Number of samples')
title('Probability distribution of the signal')
legend('probability distribution of the signal',...
       'standard normal distribution')

% autocorrelation function estimation
[Rx, lags] = xcorr(x, 'coeff');
d = lags/fs;

% plot the signal autocorrelation function
f_ = figure(5); f_.WindowStyle = 'docked';
plot(d, Rx, 'r')
grid on
xlim([-max(d) max(d)])
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Delay, s')
ylabel('Autocorrelation coefficient')
title('Autocorrelation of the signal')
line([-max(abs(d)) max(abs(d))], [0.05 0.05],...
     'Color', 'k', 'LineWidth', 2, 'LineStyle', '--')

% compute and display the minimum and maximum values
maxval = max(x);
minval = min(x);
disp(['Max value = ' num2str(maxval)])
disp(['Min value = ' num2str(minval)])

% compute and display the the DC and RMS values
u = mean(x);
s = std(x);
disp(['Mean value = ' num2str(u)])
disp(['RMS value = ' num2str(s)])

% compute and display the dynamic range
D = 20*log10(maxval/min(abs(nonzeros(x))));
disp(['Dynamic range D = ' num2str(D) ' dB'])

% compute and display the crest factor
Q = 20*log10(maxval/s);
disp(['Crest factor Q = ' num2str(Q) ' dB'])

% compute and display the autocorrelation time
ind = find(Rx>0.05, 1, 'last');
RT = (ind-N)/fs;
disp(['Autocorrelation time = ' num2str(RT) ' s'])

commandwindow
