function RHO = runCCAF2( FF2, erp2use_cca, template_Synth, epoch, filters, n, EEG )

% for FF2 = 1:n.Hz

erp_cca = erp2use_cca( epoch,:,FF2 );
synth_cca = template_Synth(epoch,:,FF2);

% ----- CCA at every harmonic
rho_use = zeros(1,5);

for HH = 1:n.harmonics
    
    % ----- declare classified trial
    
    tmp = filtfilt(         filters.Xnotch, filters.Ynotch, double(EEG) ); % notch
    tmp = filtfilt(         filters.Xlowpass{HH}, filters.Ylowpass{HH}, tmp );
    trial_harm = filtfilt(  filters.Xharm{HH}, filters.Yharm{HH}, tmp );
    
    trial2classify_long = trial_harm( epoch, : );
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
RHO = ...
    (sign(rho_use(1))*rho_use(1)^2)+...
    (sign(rho_use(2))*rho_use(2)^2)+...
    (sign(rho_use(3))*rho_use(3)^2)+...
    (sign(rho_use(4))*rho_use(4)^2)+...
    (sign(rho_use(5))*rho_use(5)^2);

%end