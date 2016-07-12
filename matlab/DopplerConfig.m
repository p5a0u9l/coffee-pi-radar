classdef DopplerConfig < handle
    properties
        state
        wav
        n_total
        n_samp
        Tp
        fs
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

        % Thresholds
        pass_thresh = 0.5; % instantaneous noise level indicating vehicle crossing
        actv_thresh = 28; % peak must be X dB above noise est
        v_max_mph = 4000;% suppress speeds above 50 mph
    end

    methods
        function me = DopplerConfig(args)
            me.i_samp = 0;
            me.i_dwell = 0;
            me.wav = args('wav_file');
            I = audioinfo(me.wav);
            me.noise_est = [];
            me.n_total = I.TotalSamples;
            me.fs = I.SampleRate;
            me.oversample = args('oversample_factor');
            me.Tp = args('dwell_period_ms')/1000;
            me.n_samp = round(me.Tp*me.fs);
            me.Tp = me.n_samp/me.fs;
            me.n_dwell_detect = args('n_detection_dwell');
            me.i_chan = args('channel_vector');
            me.n_filt = me.oversample*2^nextpow2(me.n_samp);
            taper_func = eval(sprintf('@%swin', args('windowing_function')));
            me.taper = window(taper_func, me.n_samp).';
            me.debug_level = args('debug_level');

            % State
            me.state.real_time = args('real_time');
            me.state.Active = false; % indicates there is moving object in frame,
            % assuming peak value is x dB above noise
            me.state.Passing = false; % indicates an object is passing the radar,
            % assumes instantaneous noise level is x dB above historical value
            me.state.VehicleCount = 0;

            % calculate velocity
            lambda = me.C_LIGHT/me.FC;
            df = me.fs/me.n_filt;
            doppler = 0:df:me.fs/2 - df; % doppler spectrum
            me.funcs.dop2mph = @(dop) me.MPH_CF*dop*lambda/2;
            me.funcs.mph2dop = @(mph) 2*mph/(me.MPH_CF*lambda);
            me.v_mph = me.MPH_CF*doppler*lambda/2;
            max_doppler = 2*me.v_max_mph/(me.MPH_CF*lambda);
            [~, me.max_filt] = min(abs(doppler - max_doppler));

            % iir filter coeffs
            % noise filter
            me.alpha_n = 0.90; % historical value weighting
            me.beta_n = 1 - me.alpha_n; % current measurement weighting
        end
    end
end
