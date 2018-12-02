% ----- pre-allocate

TRIAL = TRIAL + 1;

rt.trialTrigger(TRIAL,1) = NaN;
rt.trialData(n.x,N.channels2acquire,TRIAL) = NaN;
rt.maxR(TRIAL,1) = NaN;

results.RHO(:,TRIAL) = NaN(n.Hz,1);
results.maxR(TRIAL) = NaN;

% ----- look for trigger ------ await trig.trial...

eegStarted = false;

while true

    %nSamples = readBufferSamples( cfg.host, cfg.port.stream );
    HDR = get_hdr( bufferD( BID.EEG ), hdr( BID.EEG ) );
   
    if HDR.nsamples == 0
        continue
    end
    
    if ~eegStarted
     
        HDR = get_hdr( bufferD( BID.EEG ), hdr( BID.EEG ) );
        DAT = get_dat( bufferD( BID.EEG ), [HDR.nsamples-NumberOfScans+1 HDR.nsamples]-1 )';

        if isempty(DAT)
            warning('empty...')
            continue;
        end
        
        if any( ismember( DAT(:,end), [trig.flick 129] ) )

            disp( [ 'TRIAL = ' num2str(TRIAL) ] )
            
            i = find( ismember( DAT(:,end), [trig.flick 129] ), 1, 'first' );
            rt.trialTrigger(TRIAL) = DAT(i,end);

            sampleIDX = ( HDR.nsamples-NumberOfScans+1 : HDR.nsamples )';

            % i2 = (1:NumberOfScans)';
            % [ DAT(:,end) sampleIDX i2 ]

            firstSample = sampleIDX(i) + nx.monitorLatency;
            lastSample = firstSample + n.x - 1;

            eegStarted = true;
            
        end

        % ----- trig.stopRecording
        
        if io64( trig.obj, trig.address(1) ) == trig.stopRecording
            break
        end
        
        if SWITCH.now == false % viewiing chat and waiting for next trial trigger
            
            [SWITCH] = switchControl3( SWITCH, bufferD(BID.EEG), hdr(BID.EEG) );
            
            if SWITCH.now == true
                
                InpBCI = 29;
                SWITCH.now = false;
                disp('-----SWITCH-----')

                hdr(BID.feedback).buf = single(InpBCI)'; % UNITY HANDSHAKE
                result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
                
            end
        end
        
    elseif eegStarted
        
        if HDR.nsamples >= lastSample
            rt.trialData(:,:,TRIAL) = get_dat( bufferD( BID.EEG ), [firstSample lastSample]-1 )';
            %rt.trialData(:,:,TRIAL) = readBufferData( [firstSample lastSample]-1, cfg.host, cfg.port.stream );
            break
        end
        
        % ----- trig.stopRecording
        
        if io64( trig.obj, trig.address(1) ) == trig.stopRecording
            break
        end
        
        if SWITCH.now == false % viewiing chat and waiting for next trial trigger
            [SWITCH] = switchControl3( SWITCH, bufferD(BID.EEG), hdr(BID.EEG) );
        end
        
    end

end


