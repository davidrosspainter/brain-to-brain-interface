function accuracy = filter_bank_analysis2( observer, options, chan2use, n, shiftperiod, epoch, direct, Hz, trig, fs, s, Recnum )

start_time = tic;


%% ----- filter settings
[ Xnotch, Ynotch, Xl_erp, Yl_erp, Xh_erp, Yh_erp, Xlowpass, Ylowpass, Xharm, Yharm] = filterSettings(Hz, fs, n);


%% ----- epoch settings


spaceing = s.flicker/n.epochs;
for LL = 1:n.epochs
    limit_epoch{LL} = [spaceing*(LL-1) spaceing*(LL)];
end

for LL = 1:n.epochs
    [n, lim_epoch{LL}, t, ~, IDX_Hz, ~ ] = freqsettings( Hz, limit_epoch{LL}, fs, n );
end

limit2 = [0 5]; % zero-padding for FFT and determining the best electrodes!
n2 = [];
[n2, ~, ~, f2, IDX_Hz2, ~ ] = freqsettings( Hz, limit2, fs, n2 );


%% ----- load gdf

filename = [ observer.fname.train '*.gdf'  ];
fname = dir( [ direct.data filename ] );

EEG = [];
LATENCY = [];
TYPE = [];

for FILE = 1:length( fname )

    hdr = sopen( [ direct.data fname(FILE).name ] );

    fs = hdr.SampleRate; % 2048 Hz

    data = sread(hdr);

    if FILE == 1
        n.dp = size(data,1);
    end

    sdata = data(:, strcmpi( hdr.Label, 'STATUS') ); % find the STATUS channel and read the values from it
    [latency,type] = findTriggers( sdata ); % convert uV to triggers

    if FILE > 1
        latency = latency + n.dp; % adjust trigger samples of concatenated data
    end

    EEG = [ EEG; data ];
    LATENCY = [ LATENCY; latency ];
    TYPE = [ TYPE; type ];
    
end

% ----- info channels

%STATUS = EEG(:,strcmpi( hdr.Label, 'STATUS'));
PHOTODIODE = EEG(:,strcmpi( hdr.Label, 'photodiode'));

if ~options.photodiode
    labels = hdr.Label(2:65);
    %chan2use.OI_bad = find( ismember( labels, chan2use.bad ) );
    
	% ----- eeg data
    EEG = EEG(:,2:65); % get scalp electrodes
  
    EEG(:,chan2use.bad_idx) = 0;
    EEG = EEG - repmat( mean( EEG, 2), 1, size( EEG, 2) ); % average reference
    EEG = EEG - repmat(EEG(1,:), size(EEG,1), 1); % remove offset
    
else

    EEG = repmat( PHOTODIODE, 1, 64 );
    
    % ----- scale to a new range!

    R = [0 1];
    dR = diff( R );

    EEG =  EEG - min( EEG(:)); % set range of A between [0, inf)
    EEG =  EEG ./ max( EEG(:)) ; % set range of A between [0, 1]
    EEG =  EEG .* dR ; % set range of A between [0, dRange]
    EEG =  EEG + R(1); % shift range of A to R

    EEG = EEG + rand( size(EEG ) ) .* 0.001; % add noise

end

labels = hdr.Label(2:65);
%chan2use.OI_idx = find( ismember( labels, chan2use.OI ) );

        
%% ----- get epochs, make ERPs, get best electrodes based on amplitude

n.channels = 64;

trig.count = NaN( n.Hz, 2);

for FF = 1:n.Hz
    trig.count(FF,:) = [ trig.flick(FF) sum( TYPE == trig.flick(FF) ) ];
end

trig.count

n.trials_block = max( trig.count(:,2) );

trial = zeros( n.x, n.channels, n.trials_block, n.Hz ); % ----- change to NaN
erp = NaN( n.x, n.channels, n.Hz );

amp = NaN( n.x, n.channels, n.Hz );
amp_plot = NaN( n2.x, n.channels, n.Hz );

IDX_best = NaN( n.Hz, n.best );
erp2use_cca = NaN( n.x, n.harmonics, n.Hz );

missing = true( n.trials_block, n.Hz );

for FF = 1:n.Hz
    
    keep = find( ismember( TYPE, trig.flick(FF) ) ); % find cue trigger
    
    for LL = 1:n.epochs
        start{LL} = round( LATENCY(keep) + lim_epoch{LL}.x(1) );
        stop{LL} = round( LATENCY(keep) + lim_epoch{LL}.x(2) );
    end
    
    for TT = 1:n.trials_block
        
        % disp( [FF TT] )
        
        if TT <= length(keep)
            
            if stop{end}(TT) > length(EEG)
                continue
            end
            data2use = EEG(start{1}(TT):stop{end}(TT),:);
            data2use = detrend(data2use, 'linear'); %
            data2use = data2use-repmat(data2use(1,:), size(data2use,1), 1); % remove offset
                    
            if ~any(abs(data2use(:)) > 1000)
                tmp2 = nan(n.x, n.channels, n.epochs);
                %             figure;
                for LL = 1:n.epochs
                    tmp = EEG(start{LL}(TT):stop{LL}(TT),:);
                    
                    tmp = detrend(tmp, 'linear'); %
                    tmp = tmp-repmat(tmp(1,:), size(tmp,1), 1); % remove offset
                    tmp2(:,:,LL) = tmp;
                    
                    %                 subplot(2,1,LL);
                    %                 plot(tmp(:,1))
                    %                 line([lim_epoch{1}.x(2) lim_epoch{1}.x(2)], get(gca, 'ylim'))
                    
                end
                
                if n.epochs >1
                    trial(:,:,TT,FF) = mean(tmp2,3);
                else
                    trial(:,:,TT,FF) = tmp2;
                end
                missing( TT, FF ) = false;
            else
                missing( TT, FF ) = true;
                disp('exclude')
            end
        else
            missing( TT, FF ) = true;
        end
    end
    
    % -- make erp
	tmp = mean( trial(:,:,:,FF), 3);
    tmp = detrend(tmp, 'linear');
    tmp = tmp-repmat(tmp(1,:), size(tmp,1), 1); % remove offset
    
    erp(:,:,FF) = tmp;
    
    % -- amp for plotting topographies
    amp_plot(:,:,FF) = abs( fft( erp(:,:,FF), n2.x ) )/n2.x;
    amp_plot(2:end-1,:,FF) = amp_plot(2:end-1,:,FF)*2;
    
    % -- amp for finding best electrodes
    amp(:,:,FF) = abs( fft( erp(:,:,FF), n.x ) )/n.x;
    amp(2:end-1,:,FF) = amp(2:end-1,:,FF)*2;
    [~,tmp] = sort( amp( IDX_Hz(FF), chan2use.OI_idx, FF), 2, 'descend');
    IDX_best(FF,:) = tmp( 1:n.best );

    erp2use = squeeze( mean( erp(:,chan2use.OI_idx(IDX_best(FF,:)),FF), 2) );
    
    for HH = 1 : n.harmonics
        tmp = filtfilt( Xnotch, Ynotch, erp2use ); % notch
        tmp =                   filtfilt( Xl_erp{HH,FF}, Yl_erp{HH,FF}, tmp); % Apply the Butterworth filter
        erp2use_cca(:,HH,FF) =  filtfilt( Xh_erp{HH,FF}, Yh_erp{HH,FF}, tmp); % Apply the Butterworth filter
    end
    
end

% %% 
 
% figure; 
% plot(squeeze(trial(:,1,1,1)))

close all
for FF = 1:n.Hz
figure; 
plot(squeeze( erp(epoch,1,FF)))
% plot(squeeze( erp2use_cca(epoch,1,FF)))
title(Hz(FF))
end

%% ----- get unique chan2use

chan2use.unique = chan2use.OI_idx( unique( IDX_best(:) ) );
n.channels = length( chan2use.unique );

trial = trial( :, chan2use.unique, :, : ); % reduced to unique channels


%% ------ filter trials at harmonics

trial_harm = NaN( n.x, n.channels, n.trials_block, n.Hz, n.harmonics );

for HH = 1:n.harmonics
    tmp = filtfilt( Xnotch, Ynotch, trial ); % notch
    tmp = filtfilt( Xlowpass{HH}, Ylowpass{HH}, tmp );
    trial_harm(:,:,:,:,HH) = filtfilt( Xharm{HH}, Yharm{HH}, tmp);
end


%% ----- create sinusoidal templates

n.shifts = length( shiftperiod );

templates_all = NaN( n.x, n.harmonics, n.shifts, n.Hz );

for FF = 1:n.Hz
    for HH = 1 : n.harmonics
        for SS = 1:length(shiftperiod)
            templates_all(:,HH,SS,FF) = sin( HH*2*pi*Hz(FF)*t  + shiftperiod(SS) ); % contstruct signal
        end
    end
end


%% ----- correlate trials and sinusoidal templates ~ 6.2333 minutes

disp( 'calculating Tau...' )

RHO = cell( n.Hz, 1);

tic

parfor FF = 1:n.Hz
    TRIAL_HARM = squeeze( trial_harm(:,:,:,FF,:) );
    RHO{FF,1} = sinusoid_canoncorr2( n, TRIAL_HARM, templates_all, epoch );
end

toc

% ----- reshape into a 5D array

rho = NaN( n.shifts, n.harmonics, n.Hz, n.trials_block, n.Hz );

for FF = 1:n.Hz
    rho( :, :, :, :, FF) = RHO{FF};
end


%% ----- determine sinusoid phase (Tau) based on CCA classification

maxR = NaN( n.harmonics, n.Hz, n.trials_block );
correct = NaN( n.harmonics, n.Hz, n.trials_block );
accuracy = NaN( n.harmonics, n.Hz, n.trials_block );
Tau = NaN( n.Hz, n.harmonics );

for SS = 1:n.shifts
    for FF = 1:n.Hz
        for HH = 1:n.harmonics
            for TT = 1:n.trials_block
                R = rho(SS,HH,:,TT,FF);
                [~,maxR(HH,SS,TT)] = max(R);
                correct(HH,SS,TT) = FF;
            end
            
            diffR = squeeze(maxR(HH,SS,:))-squeeze(correct(HH,SS,:));
            diffR = diffR(:);
            accuracy(HH,SS,FF) = sum(diffR==0)/length(diffR);
            
        end
    end
end

for FF = 1:n.Hz
    for HH = 1:n.harmonics
        [~,i] = max(accuracy(HH,:,FF));
        Tau(FF,HH) = shiftperiod(i);
    end
end


%% ------ create sinusoids with Tau

template_Synth = NaN(n.x,n.harmonics,n.Hz);

for FF = 1:n.Hz
    for HH = 1:n.harmonics
        template_Synth(:,HH,FF) = sin( HH*2*pi*Hz(FF)*t  + Tau(FF,HH) ); % contstruct signal
    end
end


%% ----- CCA FILTER BANK ANALYSIS

disp( 'classifying training data...' )

n.epoch = length( epoch );

rho = cell( n.Hz, 1); % RHO = NaN( n.Hz, n.trials_block );

tic
parfor FF = 1:n.Hz
%for FF = 1:n.Hz
    rho{FF,1} = CCAF2(n, FF, epoch, IDX_best, trial, Xl_erp, Yl_erp, Xh_erp, Yh_erp, template_Synth, trial_harm, erp2use_cca, Xnotch, Ynotch, chan2use);
end

toc

RHO = NaN( n.Hz, n.Hz, n.trials_block ); % ----- reshape into a 3D array

for FF = 1:n.Hz
    for TT = 1:n.trials_block
        RHO( :, FF, TT ) = rho{FF}(:,TT); % RHO(FF2, FF, TT)
    end
end


%% ----- classify based on CCA FILTER BANK ANALYSIS

maxR = NaN(n.Hz,n.trials_block);
correct = NaN(n.Hz,n.trials_block);

for FF = 1:n.Hz
    for TT = 1:n.trials_block
        R = RHO(:,FF,TT);
        [~,maxR(FF,TT)] = max(R);
        correct(FF,TT) = FF;
    end
end

diffR = maxR-correct;
diffR = diffR(:);
% diffR(~missing(:)) = [];
accuracy = sum(diffR==0)/length(diffR);
disp( ['CCA accuracy = ' num2str(accuracy*100) '% (chance = 2.5%)' ] )


%% ----- save data

if options.saveTemplates
    save( [ direct.data observer.fname.templates '.mat' ], 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau', 'chan2use', 'amp_plot', 'n', 'n2', 'direct', 'observer', 'IDX_Hz2', 'Hz', 'f2', 't', 'maxR' );
end

toc( start_time )


%% plot
charuse_idx = 11:38;
theta = [0.00 0.35 0.70 1.05 1.40 1.75 0.10 0.45 ...
    0.80 1.15 1.50 1.85 0.20 0.55 0.90 1.25 ...
    1.60 1.95 0.30 0.65 1.00 1.35 1.70 0.05 ...
    0.40 0.75 1.10 1.45 1.80 0.15 0.50 0.85 ...
    1.20 1.55 1.90 0.25 0.60 0.95 1.30 1.65] * pi;
theta = theta(charuse_idx );

trainingPlots( direct, observer, amp_plot, n, n2, chan2use, IDX_best, f2, Hz, IDX_Hz2, template_Synth, erp2use_cca, t, RHO, theta, maxR, accuracy ) 