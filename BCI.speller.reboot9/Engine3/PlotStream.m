CloseMaster

direct.engine = [ cd '\' ];

options.resetPort = 0;
AddDirectories
SetupPort

load 'DataResults\recordingSettings.mat';
channelLabel = [ labels {'Trigger'} ];

BufferConfig.hosted = [ false ];
ConfigNetworkRA


%%
scheme = { 'cobalt.prf' 'darksteel.prf' 'matrix.prf' 'oblivion.prf' 'solarized-light.prf' 'vibrant.prf' 'darkmate.prf' 'default.prf' 'monokai.prf' 'solarized-dark.prf' 'tango.prf' 'david.prf' };
schemer_import( [ direct.schemer '\schemes\' scheme{9} ] );



%% dsp.TimeScope (based on N.amplifiers)

scope.nChannels = N.channels2acquire;

scope.s = 10;
scope.fs = fs;
scope.x = scope.s*fs;

scope.LayoutDimensions = [ scope.nChannels 1 ];

scope.chanIDX = cell( 1, N.amplifiers );
scope.handle = cell( 1, N.amplifiers );
scope.command = cell( 1, N.amplifiers );
                     
scope.handle = dsp.TimeScope(	scope.nChannels, scope.fs, 'BufferLength', scope.x, 'TimeAxisLabels', 'Bottom', ...
                                'TimeSpan', scope.s, 'LayoutDimensions', scope.LayoutDimensions, ...
                                'ReduceUpdates', true, 'SampleRate', scope.fs, 'TimeAxisLabels', 'none', 'Name', 'EEG', ...
                                'TimeSpanOverrunAction', 'Wrap' ); % , 'AxesScaling', 'Manual'
                                                                        
for CC = 1:scope.nChannels

    switch CC
        case scope.nChannels
            yLimit = [ 0 255 ];
            scope.command = [ scope.command 'data(:,' num2str(CC) ') );' ];
        case 1
            scope.command = 'step( scope.handle, ';
            yLimit = [-100 100];
        otherwise
            scope.command = [ scope.command 'data(:,' num2str(CC) '), ' ];
            yLimit = [-100 100];
    end
     
    set( scope.handle, 'ActiveDisplay', CC, 'YLabel', channelLabel{CC}, 'ShowGrid', false, 'YLimits', yLimit ) %  'AxesScaling', 'Manual'

end


%% get data stream

sampleIDX = NaN;

while true
    %----- read from the ring buffer

    try
        nSamples = readBufferSamples( bufferD( BID.EEG ).host, bufferD( BID.EEG ).port );
    catch
        disp('nSamples!')
        continue
    end


    if sampleIDX == nSamples
       continue
    else
        sampleIDX = nSamples;
    end

    try
       data = readBufferData( [nSamples-NumberOfScans+1 nSamples]-1, bufferD( BID.EEG ).host, bufferD( BID.EEG ).port );
    catch
       disp('data!')
       continue
    end
    
    if N.connected_devices == 2
       data = [ data(:,1:N.elec) data(:,end) data(:,N.elec+1:end-1) ];
    end

    step( scope.handle, data(:,1), data(:,2), data(:,3), data(:,4), data(:,5), data(:,6), data(:,7) )
    
end
