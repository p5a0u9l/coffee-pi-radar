% filename: DopplerConfig.m
% author: Paul Adams

classdef DopplerConfig < handle
    properties
        ax
        state
        wav
        is_file
        n_total
        n_samp
        Tp
        oversample
        n_dwell_detect
        taper
        i_samp
        i_chan
        i_dwell
        n_filt
        v_mph
        funcs
        max_filt
        debug_level
        noise_est
        alpha_n
        beta_n
    end

    properties(Constant)
        MPH_CF = 2.23694;
        FC = 2590E6; %(Hz) Center frequency (connected VCO Vtune to +5 for example)
        C_LIGHT = 3e8; %(m/s) speed of light
        AUDIO_DEVICE_ID = 2;
        FS = 44100;
        % Thresholds
        pass_thresh = 0.5; % instantaneous noise level indicating vehicle crossing
        actv_thresh = 28; % peak must be X dB above noise est
        v_max_mph = 4000;% suppress speeds above 50 mph
    end

    methods
        function me = DopplerConfig(args)
            taper_func = eval(sprintf('@%swin', args('windowing_function')));
            me.debug_level = args('debug_level');

            me.Tp = args('dwell_period_ms')/1000;
            me.oversample = args('oversample_factor');
            me.n_dwell_detect = args('n_detection_dwell');
            me.i_samp = 0;
            me.i_dwell = 0;
            me.wav = args('wav_file');
            me.i_chan = args('channel_vector');
            if ~isempty(me.wav)
                I = audioinfo(me.wav);
                me.n_total = I.TotalSamples;
                me.FS = I.SampleRate;
                me.is_file = true;
            else
                me.n_total = inf;
                me.is_file = false;
                me.wav = audiorecorder(me.FS, 16, (me.i_chan), me.AUDIO_DEVICE_ID);
                me.wav.record(2*me.Tp);
            end
            me.noise_est = [];
            me.n_samp = round(me.Tp*me.FS);
            me.Tp = me.n_samp/me.FS;
            me.taper = window(taper_func, me.n_samp).';
            me.n_filt = me.oversample*2^nextpow2(me.n_samp);

            % State
            me.state.real_time = args('real_time');
            me.state.Active = false; % indicates there is moving object in frame,
            % assuming peak value is x dB above noise
            me.state.Passing = false; % indicates an object is passing the radar,
            % assumes instantaneous noise level is x dB above historical value
            me.state.VehicleCount = 0;

            % calculate velocity
            lambda = me.C_LIGHT/me.FC;
            df = me.FS/me.n_filt;
            doppler = 0:df:me.FS/2 - df; % doppler spectrum
            me.funcs.dop2mph = @(dop) me.MPH_CF*dop*lambda/2;
            me.funcs.mph2dop = @(mph) 2*mph/(me.MPH_CF*lambda);
            me.v_mph = me.MPH_CF*doppler*lambda/2;
            max_doppler = 2*me.v_max_mph/(me.MPH_CF*lambda);
            [~, me.max_filt] = min(abs(doppler - max_doppler));

            % iir filter coeffs
            % noise filter
            me.alpha_n = 0.90; % historical value weighting
            me.beta_n = 1 - me.alpha_n; % current measurement weighting

            plot(me.v_mph, me.v_mph, '.-'); hold on;
            plot(me.v_mph(1), 1, 'r*'); hold off;
            xlim([0, 200])
            ylim([-50, 50])
            xlabel('velocity [mph]'); ylabel('dB'); title('Audio Spectrum');
            me.ax = gca;
            grid on;
        end
    end
end
