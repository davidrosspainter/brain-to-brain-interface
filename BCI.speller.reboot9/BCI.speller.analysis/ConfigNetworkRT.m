% ConfigNetwork

IPs = {'XX.XX.XX.XX', 'YY.YY.YY.YY'}; %  local and remote IPs here

BufferConfig.filepathGetLocalIPAddress = [ direct.network 'GetLocalIPAddress\GetLocalIPAddress\bin\Debug\GetLocalIPAddress.exe' ];
[~,localIP] = system( BufferConfig.filepathGetLocalIPAddress );

if (IPs{1} == localIP) %% logical inference
    remoteIP = IPs{2};
else
    remoteIP = IPs{1};
end

BID.EEG = 1;
BID.feedback = 2;

BufferConfig.name =     {'EEG'      'feedback' };
BufferConfig.port =     [ 1111      2222 ];
BufferConfig.hosted =   [ false     true ];


BufferConfig.nBuffers = length( BufferConfig.name );

BufferConfig.nChans = [ 7     1];
BufferConfig.nScans = [ 64    1];

BufferConfig.directRealtimeHack = [ direct.network 'realtimeHack.10.11.17\' ];

BufferConfig.filepathIsBufferRunning = [ direct.network 'IsBufferRunning\IsBufferRunning\bin\Debug\IsBufferRunning.exe' ];

DataType.FLOAT32 = 9; % single precision
DataBytes.FLOAT32 = 4;

[~,localIPAddress] = system( BufferConfig.filepathGetLocalIPAddress );

for i = 1:BufferConfig.nBuffers
    
    disp('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    
    bufferD(i).name = BufferConfig.name{i};

    bufferD(i).host = localIPAddress;
    
    bufferD(i).port = BufferConfig.port(i);
    bufferD(i).nChans = BufferConfig.nChans(i);
    bufferD(i).nScans = BufferConfig.nScans(i);
	bufferD(i).hosted = BufferConfig.hosted(i);
    
    bufferD(i).str = [ bufferD(i).host ': ' num2str( bufferD(i).port ) ' ' bufferD(i).name ];
    
%    check for open windows
    
    [~,result] = system( [ BufferConfig.filepathIsBufferRunning ' ' bufferD(i).host ' ' num2str( bufferD(i).port ) ] );
    result = result(1:end-1);
    
    if strcmp( result, 'False' )
        bufferD(i).running = false;
    elseif strcmp( result, 'True' )
        bufferD(i).running = true;
    end

    
    hdr(i).nchans = uint32( bufferD(i).nChans );
    hdr(i).nsamples = uint32( bufferD(i).nScans );
    hdr(i).nevents = 0;
    hdr(i).fsample = single( 0 );
    hdr(i).data_type = uint32( DataType.FLOAT32 );
    hdr(i).bufsize = uint32( bufferD(i).nChans * bufferD(i).nScans * DataBytes.FLOAT32 );
    
    if bufferD(i).hosted

        if ( ~bufferD(i).running )
            
            disp('starting!')
            system( ['cd "' BufferConfig.directRealtimeHack '" & buffer.exe ' num2str( bufferD(i).host ) ' ' num2str( bufferD(i).port ) ' -&'] ); % start buffer - necessary!
            
            bufferD(i).running = true;
            
        end
        
        buffer( 'put_hdr', hdr(i), bufferD(i).host, bufferD(i).port )
        
    end
    
    
    
    disp( [ bufferD(i).str '. bufferD(i).running = ' cell2mat( logical2cellstr( bufferD(i).running ) ) ] )
    
end


% config network

CODE.train = 1000; % from feedback
CODE.test = 2000; % from feedback
CODE.busy = 3000; % from feedback
CODE.spelling = 4000; % from Unity
CODE.viewingChat = 5000; % from Unity

CODE.startMessage = 6000;
CODE.stopMessage = 7000;
