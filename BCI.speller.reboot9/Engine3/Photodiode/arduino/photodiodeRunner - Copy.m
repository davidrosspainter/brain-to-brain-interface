CloseMaster

direct.engine = 'C:\Users\phineas\Desktop\Engine3\'; % direct.engine
addpath( direct.engine )
AddDirectories

experiment.dataFile = {};
options.checkOnset = false;

if isempty(experiment.dataFile)
    
    options.resetPort = false;
    SetupPort
    
    
    %% inter-computer buffer!
    
    N.channels2acquire = 1;
    NumberOfScans = 1; % not used
    fs = 250; % not used, but approximate
    
    hdr = startBuffer( direct, cfg.host, cfg.port.photodiode, N.channels2acquire, NumberOfScans, fs, 9 ); % single precision
    
    
    %% start photodiodes - serial comms!
    
    if ~isempty(instrfind); fclose(instrfind); delete(instrfind); end
    
    baud = 9600;
    
    photodiode = serial('COM11','BaudRate',baud);
    fopen(photodiode);

    experiment.dataFile = [ datestr(now,'yy.mmm.dd.HH.MM.SS') '.bin' ];
    fid = fopen( [direct.DataResultsRoot experiment.dataFile], 'w');
    
    
    %% transmit!
    
    addpath 'C:\Users\labpc\Desktop\toolboxes\hat'
    flipTime = [];
    count = 0;
    
    startRecording = true;
    
    while true
        
%         if io64(trig.obj, trig.address(1) ) == trig.stopRecording
%             break
%         elseif io64(trig.obj, trig.address(1) ) == trig.startRecording
%             startRecording = true;
%         end
        
        while photodiode.BytesAvailable == 0
        end
        
        data = fread(photodiode,photodiode.BytesAvailable,'uint8');
        
        hdr.buf = single(data)';
        buffer('put_dat', hdr, cfg.host, cfg.port.photodiode )
        
        trigger = io64( trig.obj, trig.address(1) );
        trigger = ones(length(data),1)*double(trigger);
        
        time = hat*1000; % ms
        time = ones(length(data),1)*time;
        
        if startRecording
            fwrite( fid, single( [ trigger data time ] )', 'float32' );
        end

    end
    
    fclose(fid);
    
end

%%

fid = fopen( [ direct.DataResultsRoot experiment.dataFile], 'rb');
DATA = fread(fid, [3 inf], 'float32')';

latency = find( [NaN; diff(DATA(:,1)) ~= 0] );
type = DATA(latency,1);


%%

figure;
stem(latency,type)



%%

time = DATA(:,3) - DATA(1,3);
%time = ( 1:length(time) ) / (range(time)/1000);

close all
figure;

ax = NaN(2,1);

for PP = 1:2
    ax(PP) = subplot(2,1,PP); cla; hold on
    plot(time, DATA(:,PP));
    scatter( time( latency ), DATA( latency, PP ) )
    scatter( time( latency(type==127) ), DATA( latency(type==127), PP), 'g' )
    
end



linkaxes(ax,'x');

fs = round( 1/( max(time/1000)/length(DATA) ) );
lim.s = [0 0.4];
lim.x = round( lim.s*fs );
lim.x(2) = lim.x(2) - 1;
lim.x = lim.x(1) : lim.x(2);
n.x = length(lim.x);

timeE = (0:length(lim.x)-1)/fs*1000;

latency2use = latency( ismember(type,101:129) );
type2use = type(ismember(type,101:129));

nTrials = length(latency2use);

for TT = 101:129
    disp( [ TT sum(type2use==TT) TT-100 sum(type==TT-100) ] )
    
end

%

uType = unique(type2use);

close all

clear results


%%

cutOff.start = 160;
cutOff.stop = 180;

if ~options.checkOnset
    
    
    IM = cell(4,7);
    
    for TRIGGER = 1:28
        
        LATENCY = latency2use(ismember(type2use,uType(TRIGGER)));
        TYPE = type2use(ismember(type2use,uType(TRIGGER)));
        
        nEpochs = length(LATENCY);
        %     nEpochs = length(latency2use);
        epoch = NaN(n.x,nEpochs);
        timeE2= NaN(n.x,nEpochs);
        
        for TT = 1:nEpochs
            %epoch(:,TT) =  DATA(lim.x+latency2use(TT),2);
            
            try
                epoch(:,TT) =  DATA(lim.x+LATENCY(TT),2);
                %timeE2(:,TT) = DATA(lim.x+LATENCY(TT),3);
                %timeE2(:,TT) = timeE2(:,TT)-timeE2(1,TT);
            catch
            end
        end
        
        nEpochs = sum(~isnan(epoch(1,:)));
        
        %
        
        
        start = NaN(nEpochs,1);
        stop = NaN(nEpochs,1);
        
        h = figure;
        
        subplot(4,2,1:2); cla; hold on
        
        
        plot(timeE,epoch(:,1:end),'r')
        plot(timeE,epoch(:,1),'k')
        
        title( num2str(TRIGGER ) )
        
        for TT = 1:nEpochs
            idx = find( epoch(:,TT) > cutOff.start, 1, 'first' );
            start(TT) = timeE(idx);
            idx = find( epoch(:,TT) > cutOff.stop, 1, 'last' );
            stop(TT) = timeE(idx);
        end
        
        dur = stop-start;
        
        subplot(4,2,3); cla; hold on
        hist( start,100)
        line( mean(start).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title( [ mean(start) std(start) ] )
        
        subplot(4,2,4); cla; hold on
        hist(stop,100)
        line( mean(stop).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title([ mean(stop) std(stop) ])
        
        subplot(4,2,5); cla; hold on
        hist(dur,100)
        line( mean(dur).*[1 1], get(gca,'ylim'), 'color', 'r' )
        title([ mean(dur) std(dur) ])
        
        subplot(4,2,6); cla; hold on
        scatter(start(2:end),stop(2:end),'r')
        scatter(start(1),stop(1),'k')
        [r,p] = corr( start, stop );
        title([r,p])
        
        subplot(4,2,[7 8])
        imagesc(timeE,[],epoch')
        colormap('jet')
        caxis( [min(epoch(:)) max(epoch(:)) ] )
        
        
        
        results(TRIGGER,:) = [ mean(start) std(start) mean(dur) std(dur)  mean(dur) std(dur) corr( start, stop ) ] ;
        
        
        saveas(h, [ num2str(TRIGGER) '.png' ] )
        IM{TRIGGER} = imread( [ num2str(TRIGGER) '.png' ] );
        delete( [ num2str(TRIGGER) '.png' ] )
        
        
        
    end
    
    imwrite(cell2mat(IM), [ direct.DataResultsRoot experiment.dataFile '.results.png'] )
    save( [experiment.dataFile 'results.mat' ])
    
else
    
    TRIGGER = (1:28)+100;
    
    LATENCY = latency2use(ismember(type2use,TRIGGER));
    TYPE = type2use(ismember(type2use,TRIGGER));
    
    nEpochs = length(LATENCY);
    %     nEpochs = length(latency2use);
    epoch = NaN(n.x,nEpochs);
    timeE2= NaN(n.x,nEpochs);
    
    for TT = 1:nEpochs
        %epoch(:,TT) =  DATA(lim.x+latency2use(TT),2);
        
        try
            epoch(:,TT) =  DATA(lim.x+LATENCY(TT),2);
        catch
        end
    end
    
    nEpochs = sum(~isnan(epoch(1,:)));
    
    start = NaN(nEpochs,1);
    stop = NaN(nEpochs,1);
    
    h = figure;
    
    subplot(4,2,1:2); cla; hold on
    
    plot(timeE,epoch(:,1:end),'r')
    plot(timeE,epoch(:,1),'k')
    
    title( num2str(TRIGGER ) )
    
    for TT = 1:nEpochs
        idx = find( epoch(:,TT) > cutOff.start, 1, 'first' );
        start(TT) = timeE(idx);
        idx = find( epoch(:,TT) > cutOff.stop, 1, 'last' );
        stop(TT) = timeE(idx);
    end
    
    dur = stop-start;
    
    subplot(4,2,3); cla; hold on
    hist( start,100)
    line( mean(start).*[1 1], get(gca,'ylim'), 'color', 'r' )
    title( [ mean(start) std(start) ] )
    
    subplot(4,2,4); cla; hold on
    hist(stop,100)
    line( mean(stop).*[1 1], get(gca,'ylim'), 'color', 'r' )
    title([ mean(stop) std(stop) ])
    
    subplot(4,2,5); cla; hold on
    hist(dur,100)
    line( mean(dur).*[1 1], get(gca,'ylim'), 'color', 'r' )
    title([ mean(dur) std(dur) ])
    
    subplot(4,2,6); cla; hold on
    scatter(start(2:end),stop(2:end),'r')
    scatter(start(1),stop(1),'k')
    [r,p] = corr( start, stop );
    title([r,p])
    
    subplot(4,2,[7 8])
    imagesc(timeE,[],epoch')
    colormap('jet')
    caxis( [min(epoch(:)) max(epoch(:)) ] )

    saveas(h, [ direct.DataResultsRoot experiment.dataFile 'results.png' ] )

end

return


%%


filename = 'test.txt';
M = csvread(filename);

figure
plot(M(:,3))

nEpochs = max( M(:,1) );

data = cell( nEpochs, 1);
dTime = NaN( nEpochs, 1);

for TRIAL = 0:nEpochs
    
    data{TRIAL+1,1} = M( M(:,1) == TRIAL,:);
    dTime(TRIAL+1) = data{TRIAL+1}(end,end);
end

figure;hold on; cla

for TRIAL = 1:nEpochs
    
    plot( data{TRIAL}(:,2), data{TRIAL}(:,3) )
    xlim( [ min( data{TRIAL}(:,2) ) max( data{TRIAL}(:,2) ) ] )
    
end


figure
plot(M(:,end)*1000)


%%

% dTime2 = [ NaN ; dTime(2:end-1) ];
% figure;
% scatter( start, dTime2 )
% [r,p] = corr(start(2:end),dTime2(2:end))
