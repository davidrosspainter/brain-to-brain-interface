% ----- cfg settings
cfg.host = 'localhost';
cfg.port = 1972;
cfg.overlap = 0; % seconds of overlap between reads

% note last will miss samples
cfg.bufferdata = 'last'; % whether to start on the 'first or 'last' data that is available (default = 'last')
cfg.jumptoeof = 1; % whether to skip to the end of the stream/file at startup (default = 'yes')

% ----- initialise buffer
hdr = buffer('get_hdr', [], cfg.host, cfg.port); % ----- read header

blocksize = round( cfg.blocksize * hdr.fsample );
overlap   = round( cfg.overlap * hdr.fsample );

if cfg.jumptoeof
    prevSample = hdr.nsamples;
else
    prevSample = 0;
end

