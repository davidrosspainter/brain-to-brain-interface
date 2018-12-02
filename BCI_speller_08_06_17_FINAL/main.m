%% require input

input('press enter')

%% clear everything

fclose all;
close all
clear mex
clear
clc

%% TO DO


%% set seed state

reset(RandStream.getGlobalStream,sum(100*clock))
seed_state = rng;

%% path

restoredefaultpath;

%% options

n.epochs = 2;

options.returnAfterPath = 0; % 1 = load path only
options.salienceMod = 0;
options.ArtificialFocus = 0; % 1 = one box at a time

options.OnlyChanOIFilled = 0;

%% options

observer.number = 23; %20
observer.viewingDistance = [57];

options.photodiode = 0; % photodiode test - changes display so bottom right is the target frequency!

if options.photodiode
    observer.number = 0; % photodiode!
end

options.record_eeg = 1;
options.read_buffer = 1;
options.saveTemplates = 1; % save 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau'
options.eyetracker =1;

options.practice = 0;

% options.nTrainBlocks = 10;

switch options.practice
    case 1
        options.nTrainBlocks = 3; % PRACTICE! - minimum 3 required for scipts to run!
        options.eyetracker =0;
    case 0
        options.nTrainBlocks = 20; % 20 blocks = 30 minutes!
end

options.rest = 1; % needed to send 255 triggers, important for trigger decoding!

options.parallel = 1;
options.port = {'D030'};

options.testtime_phase2 = 3*60;
options.testtime_phase3 = 30*60;
% options.testtime_phase3 = 7*60;

disp(options)


%% select sections to run

doStuff.train = 1;
doStuff.fba = 1;
doStuff.test = 1;


%% monitor

mon.ref = 144;
mon.num = 2;
mon.res = [1920 1080];

color.background = [0 0 0];


%% Frequency settings

charuse_idx = 11:38;
charuse_idxX = [11:30 32:39]; % for x positions

Hz = (8 : 0.2 : 15.8)'; % Hz

theta = [0.00 0.35 0.70 1.05 1.40 1.75 0.10 0.45 ...
    0.80 1.15 1.50 1.85 0.20 0.55 0.90 1.25 ...
    1.60 1.95 0.30 0.65 1.00 1.35 1.70 0.05 ...
    0.40 0.75 1.10 1.45 1.80 0.15 0.50 0.85 ...
    1.20 1.55 1.90 0.25 0.60 0.95 1.30 1.65] * pi;

Hz = Hz(charuse_idx );
theta = theta(charuse_idx );

n.Hz = length(theta);


%% directories

direct.main = cd;

direct.program = 'Program\';
direct.stim = [ direct.program '\stim\' ];
direct.gamma = [ direct.program '\gammaCorrection\' ];

direct.analysis = 'Analysis\';

direct.dataRoot = [cd '\Data\'];
direct.data = [direct.dataRoot 'S' num2str(observer.number) '\']; mkdir(direct.data);
direct.resultsRoot = 'results\';

direct.toolbox = '..\..\toolboxes\';
direct.cogent = [direct.toolbox 'Cogent2000v1.33\Toolbox\'];
direct.io64 = [direct.toolbox  'io64\'];
direct.keyInject = [direct.toolbox 'keyInject\']; % functions for entering keystrokes to save eeg automatically!
direct.realtime_hack = [direct.toolbox 'realtime_hack_07-12-2016\'];
direct.biosig = [direct.toolbox  'biosig4octmat-3.1.0\']; % load data
direct.hat = [direct.toolbox 'hat'];
direct.eyefunctions = 'E:\toolboxes\EYELINK';

%% access functions and scripts

addpath( direct.program )
addpath( direct.cogent ); cgshut;
addpath( direct.analysis )
addpath( direct.io64 )
addpath( direct.hat )

addBiosig( direct ) % function prevents extraneous variables in workspace

if options.eyetracker
       addpath( genpath(  direct.eyefunctions ))
       addpath('E:\toolboxes\eye_tools\Eyelink.mexw64')
end

if options.returnAfterPath
    return
end


%% timing

fs = 2048;

% -- timing epoching

s.flicker = 1.50*n.epochs;

s.cue = 0.50; %0.5

s.rest = 5.0;

% -- timing whole
lim.s = [0 s.flicker];

lim.x = ceil(lim.s*fs) + 1;
lim.x(2) = lim.x(2)  - 1;
n.x = length( lim.x(1):lim.x(2) );

cfg.blocksize = s.flicker + 0.25; % number, size of the blocks/chunks that are processed (default = 1 second)


m.trainTime =   ( ...
                ( s.cue + s.flicker ) * n.Hz * options.nTrainBlocks + ...
                s.rest * ( options.nTrainBlocks + 1 ) ) / 60;

disp( [ 'm.trainTime = ' num2str( m.trainTime ) ' minutes' ] )

%% timing epochs

spaceing = s.flicker/n.epochs;
for LL = 1:n.epochs
    limit_epoch{LL} = [spaceing*(LL-1) spaceing*(LL)];
end

for LL = 1:n.epochs
    [n, lim_epoch{LL}, t, ~, IDX_Hz, ~ ] = freqsettings( Hz, limit_epoch{LL}, fs, n );
end

%% File Names

observer.date = date;
observer.start_clock = clock;

observer.fname.train = [ 'S' num2str(observer.number) ' train ' observer.date ' ' num2str(observer.start_clock(4)) '-' num2str(observer.start_clock(5)) '-' num2str(observer.start_clock(6)) '.' num2str(n.epochs) 'FlickEpochs' ];
observer.fname.test = [ 'S' num2str(observer.number) ' test ' observer.date ' ' num2str(observer.start_clock(4)) '-' num2str(observer.start_clock(5)) '-' num2str(observer.start_clock(6)) '.' num2str(n.epochs) 'FlickEpochs' ];
observer.fname.templates = [ 'S' num2str(observer.number) ' templates ' observer.date ' ' num2str(observer.start_clock(4)) '-' num2str(observer.start_clock(5)) '-' num2str(observer.start_clock(6)) '.' num2str(n.epochs) 'FlickEpochs'];

fileNames = {observer.fname.train; observer.fname.test; observer.fname.templates};
fileNames = strrep( fileNames, '-', '.' );
fileNames = strrep( fileNames, ' ', '.' );

observer.fname.train_tmp = fileNames{1};
observer.fname.test_tmp = fileNames{2};
observer.fname.templates_tmp = fileNames{3};


%% load templates
if doStuff.fba == 0
    
    FNAME = dir( [ direct.data 'S' num2str( observer.number ) '.templates*mat' ] );
    
    tmp = NaN( length(FNAME), 1);
    
    for FF = 1:length(FNAME)
       tmp(FF) = datenum( FNAME(FF).date );
    end
    
    [~,i] = min(tmp);

    load( [ direct.data FNAME(i).name ], 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau', 'chan2use', 'amp_plot', 'n', 'n2', 'observer', 'IDX_Hz2', 'Hz', 'f2', 't', 'maxR' );
end
    

%% ----- classification settings

shiftperiod = ( 0 : 0.1 : 1.9 ) * pi; % change back to 1.9 pi
epoch = [0.25 spaceing]*fs; epoch = epoch(1) : epoch(2);% ---- assumes 2048!

n.harmonics = 5;
[ Xnotch, Ynotch, Xl_erp, Yl_erp, Xh_erp, Yh_erp, Xlowpass, Ylowpass, Xharm, Yharm] = filterSettings(Hz, fs, n);

n.best = 4;
n.channels = 64;

load E:\toolboxes\topoplot\biosemiChanlocs

labels = {  'Fp1'    'AF7'    'AF3'    'F1'    'F3'    'F5'    'F7'    'FT7'    'FC5'    'FC3'    'FC1'    'C1'    'C3'    'C5'    'T7'    'TP7'    'CP5'    'CP3'    'CP1'    'P1'    'P3'    'P5'    'P7' ...
            'P9'    'PO7'    'PO3'    'O1'    'Iz'    'Oz'    'POz'    'Pz'    'CPz'    'Fpz'    'Fp2'    'AF8'    'AF4'    'Afz'    'Fz'    'F2'    'F4'    'F6'     'F8'    'FT8'    'FC6'    'FC4'    'FC2' ...
            'FCz'    'Cz'    'C2'    'C4'    'C6'    'T8'    'TP8'    'CP6'    'CP4'    'CP2'    'P2'    'P4'    'P6'    'P8'    'P10'    'PO8'    'PO4'    'O2' };


chan2use.OI = {'P1' 'P3' 'P5' 'PO7' 'PO3' 'O1' 'Iz' 'Oz' 'POz' 'Pz' 'P2' 'P4' 'P6'  'PO8' 'PO4' 'O2'}; % 'P7' 'P9' 'P8' 'P10'
chan2use.OI_idx = find( ismember( labels, chan2use.OI ) );

if options.OnlyChanOIFilled
    chan2use.bad_idx = find( ~ismember( labels, chan2use.OI ) );
    chan2use.bad = labels( chan2use.bad_idx );
else
    chan2use.bad_idx =find( ismember( labels, {'P2' } ) ); % [];chan2use.bad_idx =[];% 
    chan2use.bad = labels( chan2use.bad_idx ); %chan2use.bad = {}; %
end

% figure
% subplot(2,1,1)
% topoplot(zeros(64,1),chanlocs,'electrodes','on','emarker2', { chan2use.OI_idx,'o','w',2,1} )
% subplot(2,1,2)
% topoplot(zeros(64,1),chanlocs,'electrodes','labels')

n.workers = 6;


%% ----- trigger settings

trig.rest = 255;
trig.cue = 1:40;
trig.flick = 101:140;

n.photo_frames = 15;


%% ----- setup parallel

p = gcp;

if isempty(p)
    %delete( gcp('nocreate') )
    poolobj = parpool( n.workers ); % 6 workers but 2 computational cores
end


%% ###################### TRAIN!

if doStuff.train
    
    tmp = dir( [direct.data observer.fname.train '*.gdf' ] );
    Recnum = num2str(length(tmp)+1);
    observer.fname.train = [ observer.fname.train_tmp '.Rec' Recnum ];
    observer.fname.templates = [ observer.fname.templates_tmp '.Rec' Recnum ];
    
    if options.record_eeg % start real-time acquisition
        wname = startBiosemi2ft( observer.fname.train, direct);
    end

    setupCommonSprites; % everything common!
    
    if options.eyetracker
        initialise_eyetracker
        calibrate_eyetracker_start_file_Speller
    end

    if ~options.salienceMod
        Train2
    else
        TrainSalienceMod
    end
    
    doing = 'train';
    stopNsave
    
end

%% ###################### FILTER BANK ANALYSIS!

if doStuff.fba
    %% ----- start parallel CPU
    
    ticker.fba = hat;
    
    ACCURACY = filter_bank_analysis2( observer, options, chan2use, n, shiftperiod, epoch, direct, Hz, trig, fs, s, Recnum );
    
    tocker.fba = hat;
    ticToc.fba = tocker.fba - ticker.fba;
    
    if doStuff.test
        load( [ direct.data observer.fname.templates '.mat' ], 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau', 'chan2use', 'amp_plot', 'n', 'n2', 'direct', 'observer', 'IDX_Hz2', 'Hz', 'f2', 't', 'maxR' );
        input('Template generation complete!! Press enter to continue to test')
    end

end

%% ###################### TEST!

% testphase 2 = cued, 3 = free!
% options.testtime_phase3

if doStuff.test
    
    testphase = 1;
    
    % - eeg recording
    tmp = dir( [direct.data observer.fname.test_tmp '.TestPhase' num2str(testphase) '*.gdf' ] );
    Recnum = num2str(length(tmp)+1);
    observer.fname.test = [ observer.fname.test_tmp '.TestPhase' num2str(testphase) '.Rec.' Recnum ];
    
    if options.record_eeg % start real-time acquisition
        wname = startBiosemi2ft(observer.fname.test, direct);
    end
    
    setupCommonSprites;
    
    if options.eyetracker
        initialise_eyetracker
        calibrate_eyetracker_start_file_Speller
    end
    
    if options.read_buffer
        setupBuffer;
    end
    
    % annnd go
    s.cue = 0.75;

    switch testphase
        case 1
            Test_phase1 % cycle through all letters
        case 2
            Test_phase2 % Type in cued word
        case 3
            Test_phase3 % Freely generate word
    end
    
    doing = 'test';
    stopNsave
    
end


%% stop parallel

% delete(poolobj)