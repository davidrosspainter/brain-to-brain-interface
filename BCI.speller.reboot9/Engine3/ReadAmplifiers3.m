%% clean up

if exist( 'gds_interface', 'var' ) % turn off if running
    try
        gds_interface.StopDataAcquisition();
    catch
    end
    delete( gds_interface ); clear gds_interface;
end

restoredefaultpath
CloseMaster
disp( mfilename('fullpath') );

experiment.number = 2;


%% options

options.resetPort = true;

options.WaitStart = 0; % set to true if running feedback main
options.SaveEEG = 1;

options.virtualPhotodiode = false;
options.updateExperimentNumber = false;

    
%% setup

direct.engine = [ cd '\' ];
AddDirectories


%% scheme

scheme = { 'cobalt.prf' 'darksteel.prf' 'matrix.prf' 'oblivion.prf' 'solarized-light.prf' 'vibrant.prf' 'darkmate.prf' 'default.prf' 'monokai.prf' 'solarized-dark.prf' 'tango.prf' 'david.prf', 'david2.prf' };
schemer_import( [ direct.schemer '\schemes\' scheme{13} ] );


%% old school setup

SetupPort
SetupExperiment


%% Configure Amplifier settings

RecordingSettings
save( [ direct.DataResultsRoot 'recordingSettings.mat'], 'fs', 'NumberOfScans', 'idx', 'N', 'labels', 'options' )



%% virtualPhotodiode

if options.virtualPhotodiode

    n.Hz = 28; % from analysis settings

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
        disp( [ num2str(Hz(i)) ', ' num2str( theta(i) ) ] );
    end

    flickerOn = false;
    LUM = zeros(NumberOfScans,1);
    time = zeros( 1, NumberOfScans );

end


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

%BufferConfig.name = { 'EEG' };
BufferConfig.hosted = [ true ];
ConfigNetworkRA;


%% start acquisition
disp(['Session: ' experiment.session])
disp('starting aquisition...')
tic; gds_interface.StartDataAcquisition(); toc


%% ----- Start Experiment

if options.WaitStart
    
    disp( 'waiting for trig.startRecording...' )
    
    while io64( trig.obj, trig.address(1) ) ~= trig.startRecording
        [scans_received, data] = gds_interface.GetData( NumberOfScans ); % read to prevent buffer overflow
    end
    
end

pause(.5)


%%

disp('connected!')
disp('collecting, saving & transmitting data...');

while true
    
    [scansReceived, data] = gds_interface.GetData( NumberOfScans ); % size of data reflects the number of synchronized amplifiers

    if options.virtualPhotodiode
        VirtualPhotodiode
    end
    
    % ----- put data in ring buffer

%     buffer( 'put_dat', hdr, cfg.host, cfg.port.stream )
%     HDR = get_hdr( bufferD( BID.EEG ), hdr( BID.EEG ) );
    
    hdr.buf = single(data');
    hdr(BID.EEG).buf = single(data'); % single precision!
    result = put_dat( bufferD( BID.EEG ), hdr( BID.EEG ) );
    
    if result == 0
        warning('empty...')
    end

    % ----- write data to file
    if options.SaveEEG
        fwrite( fid, hdr.buf, 'float32' );
    end
    
    % ----- trig.stopRecording
    if io64( trig.obj, trig.address(1) ) == trig.stopRecording
        break
    end
    
end



%% stop acquisition

disp('stopping acquisition...')

tic
gds_interface.StopDataAcquisition();
delete(gds_interface);
clear gds_interface;

% !taskkill /F /IM buffer.exe /T
% !taskkill /F /IM cmd.exe /T

toc
beep; pause(.5);  beep


%% save experiment

if options.SaveEEG
    
    fclose(fid);
    fclose('all');
    
    experiment.clock{2} = clock;
    save( [experiment.direct experiment.session '.read.mat'] )
    
    
    %% open data
    
    fid = fopen( experiment.dataFile, 'rb');
    DATA = fread(fid, [N.channels2acquire inf], 'float32')';
    fclose(fid);
    
    latency = find( [NaN; diff(DATA(:,end)) > 0] );
    type = DATA(latency,end);
    
    latency2 = find( [NaN; diff(DATA(:,1)) > 0] );
    type2 = DATA(latency2,1);
    
	uTrigger = unique(type);
    
    for TT = 1:length(uTrigger)
        disp( [ uTrigger(TT) sum(type==uTrigger(TT)) ] )
    end
    
    
    %% plot
    
    figure;
    
    ax1(1) = subplot(3,1,1);
    plot( DATA(:,1:end-1) )
    ax1(2) = subplot(3,1,2);
    plot( DATA(:,end) );
    ax1(3) = subplot(3,1,3); cla; hold on
    stem( latency, type, 'g' )
  
    linkaxes(ax1,'x');
   
end


disp('done!')


%%

figure;
subplot(1,2,1)
plot( diff(latency(3:end-1))/fs*1000 )
subplot(1,2,2)
[N,X] = hist( diff(latency(3:end-1))/fs*1000 );
bar(X,N/sum(N))



%% unityData

U.trial = 1;
U.frame = 2;
U.trigger = 3;
U.deltaTime = 4;
U.lum = 5;
U.flipTimeStart = 6;
U.flipTimeStop = 7;
U.cmFrames = 8;
U.cmStimulus = 9;
U.cmTrigger = 10;

nSamples = readBufferSamples( cfg.host, cfg.port.unity );
tmp = readBufferData( [1 nSamples]-1, cfg.host, cfg.port.unity );

tmp(:,[4 6 7]) = tmp(:,[4 6 7])*1000;

cond = [3 4 5 6 7];

figure;

for PP = 1:5
    ax2(PP) = subplot(5,1,PP);
    
    if ismember(cond(PP),[6 7])
        plot( [ NaN; diff(tmp(:,cond(PP))) ] )
        ylim([0 30])
    else
        plot(tmp(:,cond(PP)))
    end
    
    if PP == 2
        ylim([0 30])
    end
    
end

linkaxes(ax2,'x')

figure;

for PP = 1:3
subplot(3,1,PP)
plot(tmp(:,PP+7))
end


figure
subplot(2,1,1)
plot( tmp( tmp( :, U.cmStimulus ) == 2, U.deltaTime ) )
subplot(2,1,2)
hist( tmp( tmp( :, U.cmStimulus ) == 2, U.deltaTime ), 100 )


%% epoch data

lim.s = [0 0.5];

lim.x = round(lim.s*fs) + 1;
lim.x(2) = lim.x(2) - 1;
n.x = length( lim.x(1):lim.x(2) );

timeE = (0:n.x-1)/fs;

h = figure;

for TRIGGER = 101:128

    LATENCY = latency(ismember(type,TRIGGER));
    TYPE = type(ismember(type,TRIGGER));

    nEpochs = length(LATENCY);
    epoch = NaN(n.x,nEpochs);

    for TT = 1:nEpochs
        try
            epoch(:,TT) =  DATA((lim.x(1):lim.x(2))+LATENCY(TT),1);
        catch
        end
    end

    nEpochs = sum(~isnan(epoch(1,:)));

    subplot(7,4,TRIGGER-100)
    imagesc(timeE,[],epoch')
    colormap('jet')
    caxis( [0 1] )
    %title(TRIGGER)

end
