%% ----- frequencies

n.Hz = 28;

selectedHz = 11:38; % !!!!!!!! ENSURE THERE ARE 28 frequencies

Hz = (8 : 0.2 : 15.8)'; % Hz

theta = [   0.00 0.35 0.70 1.05 1.40 1.75 0.10 0.45 ...
            0.80 1.15 1.50 1.85 0.20 0.55 0.90 1.25 ...
            1.60 1.95 0.30 0.65 1.00 1.35 1.70 0.05 ...
            0.40 0.75 1.10 1.45 1.80 0.15 0.50 0.85 ...
            1.20 1.55 1.90 0.25 0.60 0.95 1.30 1.65] * pi;

Hz = Hz(selectedHz);
theta = theta(selectedHz);

HzAdjust = 0;

Hz = Hz + HzAdjust; % 13-18.4 Hz

for i = 1:n.Hz
    disp( [ num2str(Hz(i)) '/' num2str( theta(i)/pi ) ] );
end



%% key settings

n.trainBlocks = 15;  % 20 blocks = 30 minutes!
n.trainTrials = n.Hz*n.trainBlocks;
n.trialPreallocate = n.trainTrials*5;

s.monitorLatency = 35.7782/1000;
nx.monitorLatency = round( s.monitorLatency*fs ); % datapoints

s.flicker = 1.5;
s.flicker = s.flicker;


%% channels

% labels = {'Iz'  'O1'  'Oz'  'O2'  'POz'  'FCz'}; % from recording setting

n.best = 5;
n.channels = 6;

chan2use.OI_idx = 1:n.best;
chan2use.bad_idx = [];


%% Triggers

trig.viewingChat = 50;
trig.freeSpelling = 200;

trig.testFlicker = 100;
trig.cueFlicker = 150;

trig.rest = 155;
trig.cue = 1:n.Hz;
trig.flick = (1:n.Hz) + 100;

trig.initAnalysis = 252;
trig.stopAnalysis = 253;


%% timing

% -- timing whole

lim.s = [0 s.flicker];

lim.x = round(lim.s*fs) + 1;
lim.x(2) = lim.x(2) - 1;
n.x = length( lim.x(1):lim.x(2) );

timeE = (0:n.x-1)/fs;

n.s = lim.s(2)-lim.s(1);

f = 0 : 1/n.s : fs - 1/n.s; % f = 0 : 1/n.s : fs;

IDX_Hz = NaN(n.Hz,1);
real_Hz = NaN(n.Hz,1);

for FF = 1:n.Hz
    [~, IDX_Hz(FF)] = min( abs( f - Hz(FF) ) );
    real_Hz(FF) = f(IDX_Hz(FF));
end


%% extraction epoch

if options.virtualPhotodiode
    epoch = round([0 s.flicker]*fs); epoch(1) = epoch(1)+1;
    epoch = epoch(1) : epoch(2);
else
    epoch = round([0.25 s.flicker]*fs); epoch(1) = epoch(1)+1;
    epoch = epoch(1) : epoch(2);
end


%% ----- classification settings

shiftperiod = ( 0 : 0.1 : 1.9 ) * pi; % change back to 1.9 pi
n.harmonics = 5;


%% ----- filter settings

[ filters.Xnotch, filters.Ynotch, filters.Xl_erp, filters.Yl_erp, filters.Xh_erp, filters.Yh_erp, filters.Xlowpass, filters.Ylowpass, filters.Xharm, filters.Yharm] = filterSettings(Hz, fs, n);


%% ----- setup parallel pool

n.workers = 8;
p = gcp;

if isempty(p)
    %delete( gcp('nocreate') )
    poolobj = parpool( n.workers ); % 6 workers but 2 computational cores
end