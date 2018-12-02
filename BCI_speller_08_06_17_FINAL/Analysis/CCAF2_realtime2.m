function [RHO, maxR, EEG, photo, prevSample, sampleIDX] = CCAF2_realtime2(n, epoch, template_Synth, erp2use_cca, Xnotch, Ynotch, Xlowpass, Ylowpass, Xharm, Yharm, prevSample, lim_epoch, cfg, blocksize, overlap, options, chan2use)

n.harmonics = 5;

% ###############################################################
% REAL-TIME #####################################################
% ###############################################################
%
% for FRAME = 1 : n.photo_frames % ---- wait 104.1660 ms - give extra "buffer" for epoch
%     cgflip(0,0,0) % set screen to black while working things out!
% end

while true
    
    % ----- read hdr!
    
    hdr = buffer('get_hdr', [], cfg.host, cfg.port); % ----- read header
    
    newsamples = hdr.nsamples - prevSample; % see whether new samples are available
    
    if newsamples >= blocksize % ensure buffer has enough data
        
        if strcmp(cfg.bufferdata, 'last') % determine the samples to process
            begsample  = hdr.nsamples - blocksize + 1;
            endsample  = hdr.nsamples;
        elseif strcmp(cfg.bufferdata, 'first')
            begsample  = prevSample + 1;
            endsample  = prevSample + blocksize;
        end
        
        if overlap && ( begsample > overlap ) % this allows overlapping data segments
            begsample = begsample - overlap;
            endsample = endsample - overlap;
        end
        
        prevSample  = endsample; % remember up to where the data was read
        
        %% get data
        
        dat = buffer('get_dat', [begsample-1 endsample-1], cfg.host, cfg.port); % ----- read data (c++ indicies start at zero!)
        dat = dat.buf'; % ----- extract just the data
        
        evt = buffer('get_evt', [], cfg.host, cfg.port); % ----- read last 100 events
        evt = evt( ismember( [evt.sample], begsample:endsample ) ); % ----- get events coinciding with stimulus period
        evt = evt( strcmp( {evt.type}, 'TRIGGER' ) ); % ----- get stimulus events (i.e., parallel triggers)
        evt = rmfield(evt, 'type'); evt = rmfield(evt, 'offset');  evt = rmfield(evt, 'duration'); % ----- remove extraneous fields
        
        sampleIDX = begsample : endsample;
        photo = dat(:,65); photo = photo - photo(1);
        
        if ~options.photodiode
            
            EEG = dat(:,1:64); % get scalp electrodes
            EEG = EEG - repmat( mean( EEG, 2), 1, size( EEG, 2) ); % average reference
            
            EEG = EEG( :, chan2use.unique ); % reduced to unique channels
            
            EEG = double(EEG);
            EEG = detrend(EEG, 'linear'); %
            EEG = EEG - repmat(EEG(1,:), size(EEG,1), 1); % remove offset
            
        else
            
            EEG = repmat( photo, 1, length( chan2use.unique ) );
            
            % ----- scale to a new range!
            
            R = [0 1];
            dR = diff( R );
            
            EEG =  EEG - min( EEG(:)); % set range of A between [0, inf)
            EEG =  EEG ./ max( EEG(:)) ; % set range of A between [0, 1]
            EEG =  EEG .* dR ; % set range of A between [0, dRange]
            EEG =  EEG + R(1); % shift range of A to R
            
            EEG = EEG + rand( size(EEG ) ) .* 0.001; % add noise
            
        end
        
        
        %% epoch!
        
        %         dphoto = [NaN; diff(photo)];
        %
        %         ONSET = find( dphoto > 500, 1, 'first');
        %
        %         start = ONSET;
        %         stop = ONSET + lim.x(2) - 1;
        %
        %         photo = photo(start:stop);
        %         EEG = EEG(start:stop,:);
        
        
        if ~isempty( ismember( [evt.value], 101:140) )
            IDX = find( ismember( sampleIDX, evt( ismember( [evt.value], 101:140) ).sample ) );
        else
            IDX = size(EEG,1) - lim.x(2);
        end
        
        %         start = IDX + lim.x(1);
        %         stop = IDX + lim.x(2);
        
        %         EEG = EEG( start:stop, : );
        %         photo = photo( start:stop);
        %         sampleIDX = sampleIDX( start:stop );
        
        tmp2EEG = nan(n.x, length( chan2use.unique ), n.epochs);
        tmp2photo = nan(n.x, n.epochs);
        
        for LL = 1:n.epochs
            start = IDX + lim_epoch{LL}.x(1) ;
            stop =  IDX + lim_epoch{LL}.x(2) ;

            tmp2EEG(:,:,LL) = EEG( start:stop, : );
            tmp2photo(:,LL) = photo( start:stop );
        end
        
        if n.epochs > 1
            EEG = mean(tmp2EEG,3);
            photo = mean(tmp2photo,2);
        else
            EEG =tmp2EEG;
            photo = tmp2photo;
        end
        
        sampleIDX = sampleIDX( (IDX + lim_epoch{1}.x(1))    :   (IDX + lim_epoch{end}.x(2))  );
        
        % ----- plot epoch
        
        % close all; figure;
        %
        %         ax(1) = subplot(3,1,1); cla; hold on
        %         plot( sampleIDX, photo )
        %
        %         for EE = 1:length(evt)
        %             line( [1 1]*evt(EE).sample, get(gca,'ylim'), 'color', 'r')
        %             line( [1 1]*evt(EE).sample, get(gca,'ylim'), 'color', 'r', 'linestyle', '--')
        %             text( evt(EE).sample, mean( get(gca,'ylim') ), num2str( evt(EE).value ), 'color', 'r' )
        %         end
        
        % ----- display progress!
        
        %         if options.verbose
        %             disp( [ 'analysis frequency = ' num2str( f_fft(i) ) ] )
        %
        %             hdr2 = buffer('get_hdr', [], cfg.host, cfg.port); % ----- read header
        %             delay       = ( hdr2.nsamples - hdr.nsamples ) / hdr.fsample * 1000; % ms
        %
        %             fprintf('processing segment from sample %d to %d, delay = %d ms\n', begsample, endsample, delay);
        %
        %             for EE = 1:length(evt)
        %                 disp(evt(EE))
        %             end
        %         end
        
        break % end the search for enough buffer data
        
    end
end

%% perform CCA

RHO = cell( n.Hz, 1);

tic

parfor FF2 = 1:n.Hz
    RHO{FF2,1} = runCCAF( FF2, erp2use_cca, template_Synth, epoch, Xnotch, Ynotch,Xharm, Yharm,Xlowpass, Ylowpass, n,EEG )
end

RHO = cell2mat(RHO);


%% choose letter
[~, maxR ] = max( RHO );