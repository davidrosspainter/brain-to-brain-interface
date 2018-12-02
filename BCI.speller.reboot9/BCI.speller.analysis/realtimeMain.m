input( 'realtimeMain ... press enter' )
restoredefaultpath
CloseMaster


%% options

options.TRAIN = true;

options.resetPort = true;
options.virtualPhotodiode = false; % control from readAmplifers instead



%% ///// access engine

BUILD_VERSION = 9;

direct.engine = [ 'C:\Users\labpc\Desktop\BCI.speller.reboot' num2str(BUILD_VERSION) '\Engine3\' ]; % direct.engine
addpath(direct.engine)

AddDirectories

scheme = { 'cobalt.prf' 'darksteel.prf' 'matrix.prf' 'oblivion.prf' 'solarized-light.prf' 'vibrant.prf' 'darkmate.prf' 'default.prf' 'monokai.prf' 'solarized-dark.prf' 'tango.prf' 'david.prf' };
schemer_import( [ direct.schemer '\schemes\' scheme{1} ] );


%% old school setup

SetupPort
io64(trig.obj, trig.address(1), 0); % clear triggers

% ---- load current observer

load( [ direct.DataResultsRoot 'recordingSettings.mat'], 'fs', 'NumberOfScans', 'labels', 'N', 'labels' )
load( [ direct.DataResultsRoot 'experiment.mat'] )

experiment.startTime = clock;


%% SETTINGS!!!!!!!!!!!!!!!!!

analysisSettings


%% configureNetwork David Ross Painter, 24/09/2018 4:11 PM

%   ___   _      ___   _      ___   _      ___   _      ___   _
%  [(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|
%   '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|
%  /mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /
%        |____________|____________|____________|____________|
%                              |            |            |
%                          ___  \_      ___  \_      ___  \_
%                         [(_)] |=|    [(_)] |=|    [(_)] |=|
%                          '-`  |_|     '-`  |_|     '-`  |_|
%                         /mmm/        /mmm/        /mmm/

%BufferConfig.name = {'EEG' 'feedback'};
ConfigNetworkRT;


%% ----- pre-allocate experiment variables

% rt.trialTrigger = NaN( n.trialPreallocate, 1 );
% rt.trialData = NaN( n.x, N.channels2acquire, n.trialPreallocate ); % channels + trigger channel
% rt.maxR = NaN( n.trialPreallocate, 1 ); % classified signal identifier



%%

keyAlphabet =     [ 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', ...
                    'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', '<', ...
                    'Z', 'X', 'C', 'V', 'B', 'N', 'M', ' ', '>' ];
%         
% lettersSelected = [];
%                 
% for i = 1:length(results.maxR-1)
% 	lettersSelected = cat(2, lettersSelected, keyAlphabet( results.maxR(i) ));
% end


%% ----- load templates

if ~options.TRAIN
    
    disp('loading templates...')
    
    fileID = fopen([ direct.DataResultsRoot 'lastTemplates.txt'],'r');        
    FNAME = fscanf(fileID, '%s');
    fclose(fileID);

    load( FNAME, 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau', 'chan2use', 'amp_plot', 'n', 'n2', 'experiment', 'IDX_Hz2', 'Hz', 'f2', 'timeE', 'maxR' );
    testingNow = true;
    
else 
    testingNow = false;
end


%% ----- SWITCH

SWITCH.criterion = 4.5; % uV
SWITCH.coolDownDuration = 4; % (s) before next switch possible

SWITCH.lastSwitchTime = hat;
SWITCH.count = 0;

SWITCH.nx = round( fs );
SWITCH.f = 0 : 1 : fs-1;

SWITCH.now = false;

SWITCH.yMax = 20;
SWITCH.plot = true;

% while true
%     [SWITCH] = switchControl3( SWITCH, bufferD(BID.EEG), hdr(BID.EEG) );
% end
% % 
% return


%% ready variables

rt.trialTrigger = [];
rt.trialData = [];
rt.maxR = [];

results.RHO = [];
results.maxR = [];


%% run trials

buffer('flush_dat', [], bufferD( BID.feedback ).host, bufferD( BID.feedback ).port );
pause(1)

TRIAL = 0;

if TRIAL == 0
    
    if options.TRAIN
        hdr(BID.feedback).buf = single(CODE.train'); % single precision!
        io64( trig.obj, trig.address(2), 1 ) % read amplifiers for noise control on virtualPhotodiode
    else
        hdr(BID.feedback).buf = single(CODE.test'); % single precision!
        io64( trig.obj, trig.address(2), 2 ) % read amplifiers for noise control on virtualPhotodiode
    end
    
    
    result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
    
    disp('READY!')
end

% HDR = get_hdr( bufferD( BID.feedback ), hdr( BID.feedback ) );
% DAT = get_dat( bufferD( BID.feedback ), [HDR.nsamples HDR.nsamples]-1 )'


%save'


while true
    
    
    if TRIAL == 1 && ~testingNow % send code to prevent handshake on unity side once training has started
        hdr( BID.feedback ).buf = single(CODE.busy)'; % UNITY HANDSHAKE
        result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
    end
    
    disp('*************')
    
    epochData2
    
    if testingNow
        classifyLetter
    end
    
    
    
    %% ###################### FILTER BANK ANALYSIS!
    
    if options.TRAIN && TRIAL == n.trainTrials && ~testingNow

        hdr( BID.feedback ).buf = single(CODE.busy)'; % UNITY HANDSHAKE
        result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
        disp('BUSY!')

        ticker.fba = hat;
        filter_bank_analysis3(Hz,theta,fs,n,trig,rt,chan2use,options,IDX_Hz,filters,timeE,epoch,shiftperiod,experiment,direct)
        tocker.fba = hat;
        ticToc.fba = tocker.fba - ticker.fba;
             
        fileID = fopen([ direct.DataResultsRoot 'lastTemplates.txt'],'r');        
        FNAME = fscanf(fileID, '%s');
        fclose(fileID);

		load( FNAME, 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau', 'chan2use', 'amp_plot', 'n', 'n2', 'experiment', 'IDX_Hz2', 'Hz', 'f2', 'timeE', 'maxR' );
		
        input('Template generation complete!! Press enter to continue to test')
        
        testingNow = true;
        
        hdr(BID.feedback).buf = single(CODE.test)'; % UNITY HANDSHAKE
        result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
        
%         hdr2.buf = single(TRIG.test)'; % UNITY HANDSHAKE
%         buffer('put_dat', hdr2, cfg.host, cfg.port.feedback )

        disp('READY!')
        
        io64( trig.obj, trig.address(2), 2 ) % read amplifiers for noise control
        
    end
    
%     % ----- trig.stopRecording
%     if io64( trig.obj, trig.address(1) ) == trig.stopRecording
%         break
%     end
    
    
end

%%

experiment.stopTime = clock;
tic; save( [ experiment.dataFile '.realtime.mat' ] ); toc

disp('done!')


%%

hdr2.buf = single(TRIG.test)'; % UNITY HANDSHAKE
buffer('put_dat', hdr2, cfg.host, cfg.port.feedback )
nSamples = readBufferSamples( cfg.host, cfg.port.feedback )
tmp = readBufferData( [1 nSamples]-1, cfg.host, cfg.port.feedback )

