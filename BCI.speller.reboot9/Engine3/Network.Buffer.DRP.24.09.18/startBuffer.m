function hdr = startBuffer( direct, host, port, nChannels, nScans, fs, dataType )

% !taskkill /F /IM buffer.exe /T
% !taskkill /F /IM cmd.exe /T


% type                                 size in bytes
% 
% byte, uint8, int8                     1
% uint16, int16                         2
% uint32, int32, float32                4
% uint64, int64, float64, complex64     8
% complex128                           16


switch dataType
    case 4
        dataBytes = 8;
    case 9 % 9 = single precision
        dataBytes = 4;
    case 10 % 10 = double precision
        dataBytes = 8;
end

system( ['cd "' direct.realtime_hack '" & buffer.exe ' num2str( host ) ' ' num2str( port ) ' -&'] ); % start buffer - necessary!

hdr.nchans = uint32( nChannels );
hdr.nsamples = uint32( nScans );
hdr.nevents = 0;
hdr.fsample = single( fs );
hdr.data_type = uint32( dataType );
hdr.bufsize = uint32( hdr.nchans * hdr.nsamples * dataBytes );

buffer( 'put_hdr', hdr, host, port )