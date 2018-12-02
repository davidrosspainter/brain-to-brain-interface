function nSamples = readBufferSamples( host, port )

hdr = buffer('get_hdr', [], host, port );
nSamples = hdr.nsamples;