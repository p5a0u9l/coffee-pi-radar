
fnames = dir('*radar_data*');
for i = 1:length(fnames)
    batch_fmcw_detection('fname', fnames(i).name);
    keyboard
end

