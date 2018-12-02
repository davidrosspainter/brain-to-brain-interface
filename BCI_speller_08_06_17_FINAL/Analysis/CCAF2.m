function RHO = CCAF2(n, FF, epoch, IDX_best, trial, Xl_erp, Yl_erp, Xh_erp, Yh_erp, template_Synth, trial_harm, erp2use_cca, Xnotch, Ynotch, chan2use)

% RHO(FF2, FF, TT)

RHO = zeros( n.Hz, n.trials_block );

for TT = 1:n.trials_block
    
    
    %% create erp but exclude trial
    
    trialuse2 = NaN( n.epoch, n.harmonics );
    
    for HH = 1:n.harmonics
        
        trial_idx = 1:n.trials_block;
        trial_idx(TT) = [];
        
        IDXBEST = find( ismember( chan2use.unique, chan2use.OI_idx(IDX_best(FF,:)) ) );
        %trialuse = squeeze( mean( mean( trial( epoch, IDX_best(FF,:), trial_idx, FF), 2), 3));
        trialuse = squeeze( mean( mean( trial( epoch, IDXBEST, trial_idx, FF), 2), 3));
        
        tmp = detrend(trialuse, 'linear');
        tmp = tmp-repmat(tmp(1,:), size(tmp,1), 1); % remove offset
        
        tmp = filtfilt( Xnotch, Ynotch, tmp ); % notch
        tmp =                       filtfilt( Xl_erp{HH,FF}, Yl_erp{HH,FF}, tmp ); % Apply the Butterworth filter
        trialuse2(:,HH) = squeeze(  filtfilt( Xh_erp{HH,FF}, Yh_erp{HH,FF}, tmp ) ); % Apply the Butterworth filter
        
    end
    
    for FF2 = 1:n.Hz
        
        if FF == FF2
            erp_cca = trialuse2;
        else
            erp_cca = erp2use_cca( epoch,:,FF2 );
        end
        
        synth_cca = template_Synth(epoch,:,FF2);
        
        % ----- CCA at every harmonic
        rho_use = zeros(1,5);
        
        for HH = 1:n.harmonics
            
            % ----- declare classified trial
            
            trial2classify_long = trial_harm( epoch, :, TT, FF, HH );
            trial2classify = mean( trial2classify_long, 2);
            
            if ~all( trial2classify(:) == 0 )
                
                %% canncor
                
                % -- test(X) V synth(Y)
                [WXyX,WXyY,~,~,~] = canoncorr(trial2classify, synth_cca);
                [~,~,r,~,~] = canoncorr(trial2classify_long, synth_cca);
                rho_tmp(1) = max(r);
                
                % -- test(X) V train(x)
                [WXxX,WXxx,~,~,~] = canoncorr(trial2classify, erp_cca);
                [~,~,r,~,~] = canoncorr(trial2classify_long, erp_cca);
                rho_tmp(2) = max(r);
                
                % -- train(x) V synth(Y)
                [WxYx,WxYY,~,~,~] = canoncorr(trial2classify, erp_cca);
                
                % -- test(X) V train(x) -- Weight(test(X) V synth(Y))
                X = trial2classify; Y = erp_cca;
                U = (X - repmat(mean(X),size(X,1),1))*WXyX;
                V = (Y - repmat(mean(Y),size(X,1),1))*WXyY;
                r = corr(U,V);
                rho_tmp(3) = max(diag(r));
                
                % -- test(X) V train(x) -- Weight(train(x) V synth(Y))
                X = trial2classify; Y = erp_cca;
                U = (X - repmat(mean(X),size(X,1),1))*WxYx;
                V = (Y - repmat(mean(Y),size(X,1),1))*WxYY;
                r = corr(U,V);
                rho_tmp(4) = max(diag(r));
                
                % -- train(X) V train(x) -- Weight(train(x) V test(x))
                X = erp_cca; Y = erp_cca;
                U = (X - repmat(mean(X),size(X,1),1))*WXxX;
                V = (Y - repmat(mean(Y),size(X,1),1))*WXxx;
                r = corr(U,V);
                rho_tmp(5) = max(r);
                
            else
                rho_tmp(1:5) = 0;
            end
            
            %% create weighted combinations
            
            div = HH;
            rho_use(1) = rho_use(1) + (1/div)*(rho_tmp(1)^2);
            rho_use(2) = rho_use(2) + (1/div)*(rho_tmp(2)^2);
            rho_use(3) = rho_use(3) + (1/div)*(rho_tmp(3)^2);
            rho_use(4) = rho_use(4) + (1/div)*(rho_tmp(4)^2);
            rho_use(5) = rho_use(5) + (1/div)*(rho_tmp(5)^2);
            
        end
        
        % -- combine different R values
        RHO(FF2,TT) = ...
            (sign(rho_use(1))*rho_use(1)^2)+...
            (sign(rho_use(2))*rho_use(2)^2)+...
            (sign(rho_use(3))*rho_use(3)^2)+...
            (sign(rho_use(4))*rho_use(4)^2)+...
            (sign(rho_use(5))*rho_use(5)^2);
        
    end
end
