function hdr = get_hdr( bufferD, hdr )
% hdr = get_hdr( bufferD )

if bufferD.running
    try
        hdr = buffer('get_hdr', [], bufferD.host, bufferD.port );
    catch
        %hdr = [];
        bufferD.running = false;
        warning( 'hdr = buffer(''get_hdr'' : FAILED!' )
    end

end