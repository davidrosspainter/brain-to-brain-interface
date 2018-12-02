function data = readBufferData( idxSample, host, port )

dat = buffer('get_dat', idxSample, host, port );
data = dat.buf';