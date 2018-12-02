function filter_bank_analysis3(Hz,theta,fs,n,trig,rt,chan2use,options,IDX_Hz,filters,timeE,epoch,shiftperiod,experiment,direct)

startTime = tic;

%% ----- settings for five second epoch

limit2 = [0 5]; % zero-padding for FFT and determining the best electrodes!
n2 = [];
[n2, ~, ~, f2, IDX_Hz2, ~ ] = freqsettings( Hz, limit2, fs, n2 );


%% ----- get epochs, make ERPs, get best electrodes based on amplitude

trig.count = NaN( n.Hz, 2);

for FF = 1:n.Hz
    trig.count(FF,:) = [ trig.flick(FF) sum( rt.trialTrigger(1:n.trainTrials) == trig.flick(FF) ) ];
end

trig.count

n.trials_block = max( trig.count(:,2) );

trial = zeros( n.x, n.best, n.trials_block, n.Hz ); % ----- change to NaN
erp = NaN( n.x, n.best, n.Hz );

amp = NaN( n.x, n.best, n.Hz );
amp_plot = NaN( n2.x, n.best, n.Hz );

IDX_best = NaN( n.Hz, n.best );
erp2use_cca = NaN( n.x, n.harmonics, n.Hz );


%%

countTT = zeros(n.Hz,1);

for TRIAL = 1:n.trainTrials
    
    data2use = rt.trialData(:,:,TRIAL);
    data2use(:,chan2use.bad_idx) = 0;
    data2use = data2use(:,chan2use.OI_idx);
    
    if ~options.virtualPhotodiode
    	data2use = detrend(data2use, 'linear'); %
    	data2use = data2use-repmat(data2use(1,:), size(data2use,1), 1); % remove offset
    end
    
    FF = rt.trialTrigger(TRIAL)-100;
    countTT(FF) = countTT(FF)+1;
    
    trial(:,:,countTT(FF),FF) = data2use;
    
end

for FF = 1:n.Hz
    
    % -- make erp
	tmp = mean( trial(:,:,:,FF), 3);
    
    if ~options.virtualPhotodiode
        tmp = detrend(tmp, 'linear');
        tmp = tmp-repmat(tmp(1,:), size(tmp,1), 1); % remove offset
    end
    
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
        tmp = filtfilt(                     filters.Xnotch,         filters.Ynotch, erp2use ); % notch
        tmp =                   filtfilt(   filters.Xl_erp{HH,FF},  filters.Yl_erp{HH,FF}, tmp); % Apply the Butterworth filter
        erp2use_cca(:,HH,FF) =  filtfilt(   filters.Xh_erp{HH,FF},  filters.Yh_erp{HH,FF}, tmp); % Apply the Butterworth filter
    end

end
    
close all
figure;

for FF = 1:n.Hz
	subplot(7,4,FF)
    imagesc(timeE,[],erp(epoch,:,FF)')
    colormap('jet')
    caxis( [0 1] )
end

if options.virtualPhotodiode
    %trial = trial + rand( size(trial ) ) .* 0.005; % add noise to avoid Warning: X is not full rank.
    trial = trial + rand( size(trial ) ) .* 0.5; % add noise to avoid Warning: X is not full rank.
end


%% ----- get unique chan2use

chan2use.unique = chan2use.OI_idx( unique( IDX_best(:) ) );
n.best = length( chan2use.unique );

trial = trial( :, chan2use.unique, :, : ); % reduced to unique channels


%% ------ filter trials at harmonics

trial_harm = NaN( n.x, n.best, n.trials_block, n.Hz, n.harmonics );

for HH = 1:n.harmonics
    tmp = filtfilt( filters.Xnotch, filters.Ynotch, trial ); % notch
    tmp = filtfilt( filters.Xlowpass{HH}, filters.Ylowpass{HH}, tmp );
    trial_harm(:,:,:,:,HH) = filtfilt( filters.Xharm{HH}, filters.Yharm{HH}, tmp);
end


%% ----- create sinusoidal templates

n.shifts = length( shiftperiod );

templates_all = NaN( n.x, n.harmonics, n.shifts, n.Hz );

for FF = 1:n.Hz
    for HH = 1 : n.harmonics
        for SS = 1:length(shiftperiod)
            templates_all(:,HH,SS,FF) = sin( HH*2*pi*Hz(FF)*timeE  + shiftperiod(SS) ); % contstruct signal
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
        template_Synth(:,HH,FF) = sin( HH*2*pi*Hz(FF)*timeE  + Tau(FF,HH) ); % contstruct signal
    end
end


%% ----- CCA FILTER BANK ANALYSIS


disp( 'classifying training data...' )

n.epoch = length( epoch );

rho = cell( n.Hz, 1); % RHO = NaN( n.Hz, n.trials_block );

tic
parfor FF = 1:n.Hz
    rho{FF,1} = CCAF2(n, FF, epoch, IDX_best, trial, template_Synth, trial_harm, erp2use_cca, chan2use, filters);
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

accuracy = sum(diffR==0)/length(diffR);
disp( ['CCA accuracy = ' num2str(accuracy*100) '% (chance = 2.5%)' ] )
toc( startTime )


%% ----- save data

save( [ experiment.dataFile '.templates.mat' ], 'IDX_best', 'trial', 'trial_harm', 'template_Synth', 'erp2use_cca', 'RHO', 'accuracy', 'Tau', 'chan2use', 'amp_plot', 'n', 'n2', 'experiment', 'IDX_Hz2', 'Hz', 'f2', 'timeE', 'maxR' );

FNAME = [ direct.DataResultsRoot 'lastTemplates.txt'];
txt = strrep([ experiment.dataFile '.templates.mat' ],'\','\\');

if exist( FNAME, 'file' )
    delete( FNAME )
end

fileID = fopen( FNAME, 'w' );
fprintf(fileID,txt);
fclose(fileID);


%% ----- plot

trainingPlots( experiment, amp_plot, n, n2, chan2use, IDX_best, f2, Hz, IDX_Hz2, template_Synth, erp2use_cca, timeE, RHO, theta, maxR, accuracy ) 

