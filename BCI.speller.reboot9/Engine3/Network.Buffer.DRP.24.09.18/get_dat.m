function dat = get_dat( bufferD, idxSample )
% dat = get_dat( bufferD, idxSample )

if bufferD.running 
    try
        if all( idxSample >= 0 ) && idxSample(2) >= idxSample(1)
            dat = buffer('get_dat', idxSample, bufferD.host, bufferD.port );
            dat = dat.buf;
        else
            dat = [];
        end
    catch
        dat = [];
        bufferD.running = false;
        warning( 'hdr = buffer(''get_dat'' : FAILED!' )
    end
else
    dat = [];
end