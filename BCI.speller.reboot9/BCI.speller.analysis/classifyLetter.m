tic

% if hat - SWITCH.lastSwitchTime < SWITCH.coolDownDuration
% 	return 
% end

if SWITCH.now == false
    [SWITCH] = switchControl3( SWITCH, bufferD(BID.EEG), hdr(BID.EEG) );
end




%% get EEG

EEG = rt.trialData(:,1:n.channels,TRIAL);
EEG = EEG( :, chan2use.unique ); % reduced to unique channels

if options.virtualPhotodiode
    %EEG = EEG + rand( size(EEG) ) .* 0.005; % add noise to avoid Warning: X is not full rank.
    trial = trial + rand( size(trial ) ) .* 0.5;
else
    EEG = detrend(EEG, 'linear'); %
    EEG = EEG - repmat(EEG(1,:), size(EEG,1), 1); % remove offset
end    


%% perform CCA

RHO = cell( n.Hz, 1);

parfor FF2 = 1:n.Hz
    RHO{FF2,1} = runCCAF2( FF2, erp2use_cca, template_Synth, epoch, filters, n, EEG );
end

RHO = cell2mat(RHO);


%% choose letter

[~, InpBCI ] = max( RHO );

disp( [ rt.trialTrigger(TRIAL) InpBCI ] )

if SWITCH.now == true
    InpBCI = 29;
    SWITCH.now = false;
    disp('-----SWITCH-----')
else
    disp( keyAlphabet(InpBCI) )
end

hdr(BID.feedback).buf = single(InpBCI)'; % UNITY HANDSHAKE
result = put_dat( bufferD( BID.feedback ), hdr( BID.feedback ) );
   

%% save results

results.RHO(:,TRIAL) = RHO;
results.maxR(TRIAL) = InpBCI;

toc