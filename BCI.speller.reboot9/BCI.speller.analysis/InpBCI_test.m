input( 'realtimeMain ... press enter' )
restoredefaultpath
CloseMaster


%% ///// access engine

BUILD_VERSION = 9;

direct.engine = [ 'C:\Users\labpc\Desktop\BCI.speller.reboot' num2str(BUILD_VERSION) '\Engine3\' ]; % direct.engine
addpath(direct.engine)

AddDirectories

scheme = { 'cobalt.prf' 'darksteel.prf' 'matrix.prf' 'oblivion.prf' 'solarized-light.prf' 'vibrant.prf' 'darkmate.prf' 'default.prf' 'monokai.prf' 'solarized-dark.prf' 'tango.prf' 'david.prf' };
schemer_import( [ direct.schemer '\schemes\' scheme{1} ] );

% ---- load current observer

load( [ direct.DataResultsRoot 'recordingSettings.mat'], 'fs', 'NumberOfScans', 'labels', 'N', 'labels' )
load( [ direct.DataResultsRoot 'experiment.mat'] )


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




% BufferConfig.name =     {'EEG'      'feedback' };
ConfigNetworkRT;

%%

InpBCI  = CODE.busy

hdr(BID.feedback).buf = single(InpBCI)'; % UNITY HANDSHAKE
result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
nSamples = readBufferSamples( bufferD( BID.feedback ).host, bufferD( BID.feedback ).port )


return

%%

InpBCI  = CODE.train

hdr(BID.feedback).buf = single(InpBCI)'; % UNITY HANDSHAKE
result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
nSamples = readBufferSamples( bufferD( BID.feedback ).host, bufferD( BID.feedback ).port )


%% feedback stimulation

keyAlphabet =     { 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', ...
                    'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', '<', ...
                    'Z', 'X', 'C', 'V', 'B', 'N', 'M', ' ' ,'>' };

while true

    disp('******************')
    
    TestPhrase = randperm(29);
    TestPhrase = TestPhrase( 1: find( TestPhrase == 29 ) );

    phrase = [];

    for i = 1:length(TestPhrase)
        
        phrase = [ phrase keyAlphabet(TestPhrase(i)) ];

        InpBCI  = TestPhrase(i);
        hdr(BID.feedback).buf = single(InpBCI)'; % UNITY HANDSHAKE
        result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
        pause(.75+1.5)

    end

    disp(phrase)
    pause(2)
    
    while true
        
        try
            nSamples = readBufferSamples( bufferD( BID.feedback ).host, 4444 );
            if nSamples > 0
                status = readBufferData( [nSamples nSamples]-1, bufferD( BID.feedback ).host, 4444 );
            end
        catch
        end
            
        if status == 4000
            break
        end
        
    end

end