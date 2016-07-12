% Script to setup and run event_doppler

clear DopplerConfig;
dc = event_doppler('wav_file',...
        fullfile('..', 'reference', 'charvat_doppler', 'Off of Newton Exit 17.wav'), ...
    'debug_level', 1, ...
    'oversample_factor', 4, ...
    'dwell_period_ms', 130, ...
    'n_detection_dwell', 2, ...
    'windowing_function', 'taylor', ...
    'real_time', false, ...
    'channel_vector', 2);




