function [SWITCH] = switchControl3( SWITCH, bufferD, hdr )
    
if hat - SWITCH.lastSwitchTime < SWITCH.coolDownDuration
	return 
end

HDR = get_hdr( bufferD, hdr );

if HDR.nsamples < SWITCH.nx
    return
end

DAT = get_dat( bufferD, [HDR.nsamples-SWITCH.nx+1 HDR.nsamples]-1 )';
%DAT = readBufferData( [HDR.nsamples-SWITCH.nx+1 HDR.nsamples]-1, cfg.host, cfg.port.stream );

DAT = mean( DAT(:,end-1), 2); % second last channel is artifact line
DAT = detrend(DAT,'linear');
DAT = DAT - DAT(1);

AMP = abs(fft(DAT))/SWITCH.nx;
AMP(2:end-1) = AMP(2:end-1)*2;

switchSignal = mean( AMP( SWITCH.f > 50 & SWITCH.f < 100 ) );
time = hat;

if ( switchSignal > SWITCH.criterion && time - SWITCH.lastSwitchTime > SWITCH.coolDownDuration  )
    
    SWITCH.now = true;
    SWITCH.lastSwitchTime = time;
    SWITCH.count = SWITCH.count + 1;
    
end

if SWITCH.plot

    subplot(2,2,[1 2])
    plot( mean( DAT, 2) );
    ylim([-100 +100])

    title( SWITCH.count )

    subplot(2,2,3)
    plot(SWITCH.f,AMP)
    ylim([0 10])
    xlim([0 100])

    subplot(2,2,4)
    bar( switchSignal )
    ylim([0 SWITCH.yMax])
    line( get(gca,'xlim'), [SWITCH.criterion SWITCH.criterion], 'color', 'r' )
    drawnow

end