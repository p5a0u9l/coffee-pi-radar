classdef FmcwConfig < handle
    properties
        dev_id
        opts
        dev_type
        window_func
        device
        n_fft
        fname
        unambig_range
    end

    properties(Constant)
        M2FT = 2.23694;
        FC = 2590E6; %(Hz) Center frequency (connected VCO Vtune to +5 for example)
        C_LIGHT = 3e8; %(m/s) speed of light
        FS = 48000;
        SYNC_CHAN = 1;
        SGNL_CHAN = 2;
        FSTART = 2260E6; %(Hz) LFM start frequency for example
        FSTOP = 2590E6; %(Hz) LFM stop frequency for example
    end

    methods
        function me = FmcwConfig(varargin)
            if nargin > 1
                me.opts = containers.Map(varargin(1:2:end), varargin(2:2:end));
            else
                me.opts = containers.Map(1,1);
            end
            me.get_opts('dev_type', 'wav');
            me.get_opts('window_func', @rectwin);
            me.get_opts('n_fft', 2048);
            me.get_device_id();
            me.init_audio_device();
        end

        function get_params(me, n_samp_pulse)
            range_rez = me.C_LIGHT/(2*(me.FSTOP - me.FSTART));
            me.unambig_range = range_rez*n_samp_pulse/2;
        end

        function init_audio_device(me)
            if strcmp(me.dev_type, 'wav')
                me.get_opts('fname', 'radar_data_cache.wav');
            end
        end

        function get_device_id(me)
            adi = audiodevinfo();
            for i = 1:length(adi.input)
                if strfind(adi.input(i).Name, 'Scarlett') > 0
                    me.dev_id = adi.input.ID;
                    return
                end
            end
            error('Unable to find audio device');
        end

        function get_opts(me, key, default_value)
            if isKey(me.opts, key)
                me.(key) = me.opts(key);
            else
                me.(key) = default_value;
            end
        end
    end
end

