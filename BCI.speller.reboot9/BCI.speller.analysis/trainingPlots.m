function trainingPlots( experiment, amp_plot, n, n2, chan2use, IDX_best, f2, Hz, IDX_Hz2, template_Synth, erp2use_cca, t, RHO, theta, maxR, accuracy )

direct.results = [experiment.direct '\trainingPlots\']; mkdir(direct.results);


%% fft spike figure

amp_plot(1,:) = 0; % artificially remove offset

h = figure; hold on;

cm = colormap( jet(n.Hz) );

ampplot2 = NaN(n2.x,n.Hz);

for FF = 1 : n.Hz
    ampplot2(:,FF) = mean( amp_plot(:, chan2use.OI_idx( IDX_best(FF,:) ), FF), 2);
    plot(f2, ampplot2(:,FF), 'color', cm(FF, :));
end

xlim( [Hz(1)-1 Hz(end)+1] )
ylabel('fft amp (µV)')
xlabel('Frequency (Hz)')

TIT = [ 'fft.spike.' experiment.session ];
title( TIT )

saveas(h, [ direct.results TIT '.png' ] )


%% fft image figure wide

range = prctile( ampplot2(:), [0 99.99] );

h = figure;
imagesc(f2, Hz,  ampplot2')
caxis(range)
colormap('jet')

xlabel('output freq (Hz)')
ylabel('input freq (Hz)')
xlim( [1 2*16] )

C = colorbar;
title(C, 'µV')

TIT = [ 'fft.image.' experiment.session ];
title( TIT )

saveas(h, [ direct.results TIT '.png' ] )

xlim( [1 5*16] )
saveas(h, [ direct.results TIT '.fig' ] )


%% topo
% 
% addpath([direct.toolbox 'topoplot\'])
% load chanlocs
% 
% h = figure;
% 
% for FF = 1:n.Hz
%     head = squeeze(amp_plot(IDX_Hz2(FF),:,FF))';
%     limit = [min(head) max(head)];
%     
%     subplot(5,8,FF)
%     topoplot(head, chanlocs, 'maplimits', limit);
% end
% 
% TIT = [ 'Topo.' experiment.session ];
% suptitle(TIT);
% 
% saveas(h, [ direct.results TIT '.fig' ] )
% saveas(h, [ direct.results TIT '.png' ] )


%% example templates

col = {'r' 'b'};

R = [0 1];
dR = diff( R );

for HH = 1:n.harmonics
    
    h = figure;
    
    for FF = 1:n.Hz
        
        subplot(5,8,FF); hold on
        
        for PP = 1:2
            switch PP
                case 1
                    EEG = template_Synth(:,HH,FF);
                case 2
                    EEG = erp2use_cca(:,HH,FF);
            end
            
            EEG =  EEG - min( EEG(:)); % set range of A between [0, inf)
            EEG =  EEG ./ max( EEG(:)) ; % set range of A between [0, 1]
            EEG =  EEG .* dR ; % set range of A between [0, dRange]
            EEG =  EEG + R(1); % shift range of A to R
            
            plot(t,EEG,col{PP})
            
        end
        
        title( num2str( Hz(FF) ) )
        %xlim( [ 0 2/( Hz(FF)*HH ) ] + 1 )
        set(gca,'xtick',[],'ytick',[])
        
    end
    
    TIT = [ 'template.Synth, Harm ' num2str(HH) ];
    suptitle(TIT)
    
    saveas(h, [ direct.results TIT experiment.session '.png' ] )
    
end


%% plot CCA

h = figure;

for FF = 1:n.Hz
    ax = subplot(5,8,FF);
    plot(Hz, mean(RHO(:,FF, :),3))
    xlim([Hz(FF)-1.5 Hz(FF)+1.5])
    line([Hz(FF) Hz(FF)], get(gca, 'ylim'), 'color', 'r')
    
    set(ax,'YTick',[])
    set(ax,'XTick',[])
    
    title([ num2str(Hz(FF)) 'Hz ' num2str(theta(FF)/pi) '\pi'])
end

TIT = ['CCA.Correlations.' experiment.session ];
suptitle(TIT)
saveas(h, [direct.results TIT '.png'])


%% display

h=figure;
imagesc(1:n.trials_block,Hz, maxR, [1 n.Hz])
% colormap(jet)
C=colorbar;
title(C, 'Frequency classified')

xlabel('trial #')
ylabel('frequency')
set(gca, 'YDir',  'default');

TIT = ['accuracy.'  experiment.session '.Acc=' num2str(accuracy*100) '%'];
title(TIT)

saveas(h, [direct.results TIT '.png'])
