clear
clc
%close all

addpath 'eeg_read_bdf'
addpath 'biosigHack.bdf'


%%

addpath 'biosigHack.bdf'

FNAME = {   'data/realtime with classification2.bdf' };

options.checkOnset = [false];

ID = 1;

FNAME = FNAME{ID};
options.checkOnset = options.checkOnset(ID);

[HDR,H1,h2] = sopen(FNAME);
type = HDR.EVENT.TYP;
latency = HDR.EVENT.POS;

[data,numChan,labels,txt,fs,gain,prefiltering,ChanDim] = eeg_read_bdf(FNAME,'all','n');
data = data';
pd = data(:,35);
%pd = data(:,259);
%
figure
ax(1)=subplot(2,1,1);
plot(pd)

ax(2)=subplot(2,1,2);
stem(latency,type)

linkaxes(ax,'x')


%%

%close all



cutOff = -3.95*10^6;

fs = 2048;
lim.s = [0 0.6];
lim.x = round( lim.s*fs );
lim.x(2) = lim.x(2) - 1;
lim.x = lim.x(1) : lim.x(2);
n.x = length(lim.x);

timeE = (0:length(lim.x)-1)/fs*1000;

if ~options.checkOnset
    
    IM = cell(4,7);
    
    for TRIGGER = 101:128
        
        LATENCY = latency(ismember(type,TRIGGER));
        TYPE = type(ismember(type,TRIGGER));
        
        nEpochs = length(LATENCY);
        epoch = NaN(n.x,nEpochs);
        timeE2= NaN(n.x,nEpochs);
        
        for TT = 1:nEpochs
            try
                epoch(:,TT) =  pd(lim.x+LATENCY(TT));
            catch
            end
        end
        
        nEpochs = sum(~isnan(epoch(1,:)));
        
        start = NaN(nEpochs,1);
        stop = NaN(nEpochs,1);
        
        h = figure;
        
        subplot(3,2,[1 2]); cla; hold on
        plot(timeE,epoch,'r')
        line( get(gca,'xlim'), [1 1]*cutOff )
        
        title(num2str(TRIGGER))
        
        subplot(3,2,[3 4]); cla; hold on
        imagesc(timeE,1:nEpochs,epoch')
        ylim([1 nEpochs])
        
        for TT = 1:nEpochs
            
            
            idx = find( epoch(:,TT) > cutOff, 1, 'first' );
            
            if isempty(idx)
                idx = NaN;
            end
            
            start(TT) = timeE(idx);
            idx = find( epoch(:,TT) > cutOff, 1, 'last' );
            
            if isempty(idx)
                idx = NaN;
            end
            
            stop(TT) = timeE(idx);
        end
        
        subplot(3,2,5); cla; hold on
        hist( start,100)
        line( mean(start).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title( [ mean(start) std(start) ] )
        
        subplot(3,2,6); cla; hold on
        hist(stop,100)
        line( mean(stop).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title([ mean(stop) std(stop) ])
        
        saveas(h, [ num2str(TRIGGER) '.png' ] )
        IM{TRIGGER-100} = imread( [ num2str(TRIGGER) '.png' ] );
        delete( [ num2str(TRIGGER) '.png' ] )
        
    end
    
    imwrite(cell2mat(IM), [ FNAME 'results.png' ] )
    
else
    
    
      TRIGGER = 101:128
        
        LATENCY = latency(ismember(type,TRIGGER));
        TYPE = type(ismember(type,TRIGGER));
        
        nEpochs = length(LATENCY);
        epoch = NaN(n.x,nEpochs);
        timeE2= NaN(n.x,nEpochs);
        
        for TT = 1:nEpochs
            try
                epoch(:,TT) =  pd(lim.x+LATENCY(TT));
            catch
            end
        end
        
        nEpochs = sum(~isnan(epoch(1,:)));
        
        start = NaN(nEpochs,1);
        stop = NaN(nEpochs,1);
        
        h = figure;
        
        subplot(3,2,[1 2]); cla; hold on
        plot(timeE,epoch,'r')
        line( get(gca,'xlim'), [1 1]*cutOff )
        
        title(num2str(TRIGGER))
        
        subplot(3,2,[3 4]); cla; hold on
        imagesc(timeE,1:nEpochs,epoch')
        ylim([1 nEpochs])
        
        for TT = 1:nEpochs
            
            
            idx = find( epoch(:,TT) > cutOff, 1, 'first' );
            
            if isempty(idx)
                idx = NaN;
            end
            
            start(TT) = timeE(idx);
            idx = find( epoch(:,TT) > cutOff, 1, 'last' );
            
            if isempty(idx)
                idx = NaN;
            end
            
            stop(TT) = timeE(idx);
        end
        
        subplot(3,2,5); cla; hold on
        hist( start,100)
        line( mean(start).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title( [ mean(start) std(start) ] )
        
        subplot(3,2,6); cla; hold on
        hist(stop,100)
        line( mean(stop).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title([ mean(stop) std(stop) ])
        
        saveas(h, [ FNAME '.png' ] )
       
        
        
end
    
