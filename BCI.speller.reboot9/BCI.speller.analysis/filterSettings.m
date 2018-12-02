function [ Xnotch, Ynotch, Xl_erp, Yl_erp, Xh_erp, Yh_erp, Xlowpass, Ylowpass, Xharm, Yharm] = filterSettings(Hz, fs, n)

%% ----- filter settings

ORDER = 4;

% ----- create broad-band harmonic filters for trials
freq_lowpass = [ 16*1 16*2 16*3 16*4 16*5 ];
freq_highpass = [ 7.8*1 7.8*2 7.8*3 7.8*4 7.8*5 ];

% ----- notch filter
[ Xnotch, Ynotch ] = butter( ORDER, ( [48 51] )./(fs/2), 'stop');

% ----- create narrow-band harmonic filters for erps
Xl_erp = cell(n.harmonics,n.Hz); Yl_erp = cell(n.harmonics,n.Hz);
Xh_erp = cell(n.harmonics,n.Hz); Yh_erp = cell(n.harmonics,n.Hz);
Xlowpass = cell(n.harmonics,1); Ylowpass = cell(n.harmonics,1);
Xharm = cell(n.harmonics,1); Yharm = cell(n.harmonics,1);

for HH = 1:n.harmonics
    
    % ----- create narrow-band harmonic filters for erps
    
    for FF = 1:n.Hz
        [ Xl_erp{HH,FF}, Yl_erp{HH,FF} ] = butter(ORDER, HH*(Hz(FF)+0.2)./(fs/2), 'low'); % Define the filter
        [ Xh_erp{HH,FF}, Yh_erp{HH,FF} ] = butter(ORDER, HH*(Hz(FF)-0.2)./(fs/2), 'high'); % Define the filter
    end
    
    % ----- create broad-band harmonic filters for trials
    
    [ Xlowpass{HH}, Ylowpass{HH} ] = butter(ORDER, (freq_lowpass(HH))./(fs/2), 'low');
    [ Xharm{HH}, Yharm{HH} ] = butter(ORDER, (freq_highpass(HH) )./(fs/2), 'high');
    
end