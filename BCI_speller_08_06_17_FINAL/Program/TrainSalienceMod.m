%% data

n.trials_block = n.boxes;

n.trials = options.nTrainBlocks * n.trials_block;

D.trial = 1;
D.block = 2;
D.trial_block = 3;
D.cue_box = 4;

data = NaN( n.trials, 4 );
data(:,D.trial) = 1:n.trials;

for BLOCK = 1:options.nTrainBlocks
    
    IDX = ( 1 : n.trials_block ) + ( BLOCK - 1 ) * n.trials_block;
    
    data(IDX,D.block) = BLOCK;
    data(IDX,D.trial_block) = 1:n.trials_block;
    data(IDX,D.cue_box) = randperm( n.trials_block );
    
end

randomHz = data(:,D.cue_box);
randomHz = randomHz( randperm( length( randomHz) ) );


%% preallocate fliptimes

fliptime.rest = NaN( f.rest, options.nTrainBlocks+1 );
fliptime.cue = NaN( max(f.cue), n.trials );
fliptime.flicker = NaN( f.flicker, n.trials);


%% Sprites! (1002:1004)

% ----- cue

cue.sprite = 1002;
cue.size = box.size;
cue.colour = [1 0 0];
cue.width = 10;

cgmakesprite( cue.sprite, box.size, box.size, [0 0 0] )
cgsetsprite( cue.sprite )
cgtrncol( cue.sprite, 'n')

cgpenwid( cue.width )

cgdraw( -cue.size/2, -cue.size/2, -cue.size/2, +cue.size/2, cue.colour )
cgdraw( +cue.size/2, -cue.size/2, +cue.size/2, +cue.size/2, cue.colour )
cgdraw( -cue.size/2, -cue.size/2, +cue.size/2, -cue.size/2, cue.colour )
cgdraw( -cue.size/2, +cue.size/2, +cue.size/2, +cue.size/2, cue.colour )

cgsetsprite(0)

% ----- arrow

arrow.sprite = 1003;
arrow.size = 25;
arrow.offset = box.size/2 + gap.size/2;

cgloadbmp( arrow.sprite, [ direct.stim 'arrow.bmp' ] )
cgtrncol( arrow.sprite, 'n')

% ----- arrow_cue

arrow_cue.sprite = 1004;

cgmakesprite( arrow_cue.sprite, box.size*2, box.size*2, [0 0 0] )
cgsetsprite( arrow_cue.sprite )
cgtrncol( arrow_cue.sprite, 'n' )
cgdrawsprite( cue.sprite, 0, 0 ) % cue
cgdrawsprite( arrow.sprite, 0, 0 + arrow.offset, arrow.size, arrow.size ) % arrow
cgsetsprite(0)


%% text feedback (3001 : 3007)

cgpencol( [0.5 0.5 0.5] )

letter.size = 100; %70
cgfont( 'Andale Mono', letter.size )

for BLOCK = 1 : options.nTrainBlocks + 1
    
    cgmakesprite( BLOCK + 3000, 1474, 128, [0 0 0] )
    cgsetsprite( BLOCK + 3000 )
    cgtrncol( BLOCK + 3000, 'n' )
    
    if BLOCK == options.nTrainBlocks + 1
        cgtext( 'Finished!', 0, 0 )
    else
        cgtext( [ 'Block ' num2str(BLOCK) ' of ' num2str(options.nTrainBlocks) ], 0, 0 )
    end
    
    cgsetsprite(0)
    
    %     cgdrawsprite(BLOCK + 3000,0,475)
    %     cgflip(color.background)
    %     pause(1)
    
end


%% sprite - output display (9999)

% sprite.display = 9999;
% 
% cgmakesprite(sprite.display, mon.res(1), mon.res(2), [0 0 0] )
% cgtrncol(sprite.display,'n')
% cgsetsprite(sprite.display)
% cgrect( 0, mon.res(2)/2 - 64, 1474, 128, [1 1 1] ) % output display
% cgsetsprite(0)


%% start experiment

ticker.Train = hat;

for TRIAL = 1:n.trials
    
    % ----- initialise
    
    cue_box = data(TRIAL,D.cue_box);
    randomCueBox = randomHz(TRIAL);

    BLOCK = data(TRIAL,D.block);
    
    disp('***********************************')
    disp( [ 'BLOCK = ' num2str(BLOCK) ] )
    disp( [ 'TRIAL = ' num2str(TRIAL) ] )
    disp( [ 'cue_box = ' num2str(cue_box) ] )
    disp( [ 'frequency = ' num2str( Hz( cue_box ) ) ] )

    if ismember( TRIAL, 1 : n. trials_block : n.trials ) && options.rest
        
        for FRAME = 1:f.rest
            
%           cgdrawsprite(sprite.display,0,0) % output display
            cgdrawsprite(sprite.textBox, 0, textbox.offset.bci )
            cgdrawsprite(BLOCK + 3000, 0, textbox.offset.bci) % rest instruction
            
            for BOX = 1:n.boxes
                cgdrawsprite( placeholder.sprite, X(BOX), Y(BOX) ) % placeholder
                cgdrawsprite( BOX + 2000, X(BOX), Y(BOX) ) % character
            end
            
            % ----- photodiode trigger
            
            if ismember( FRAME, 1:n.trigger_frames )
                cgdrawsprite( 256, mon.res(1)/2 - box.size/4, -mon.res(2)/2 + box.size/4, box.size/2, box.size/2 ) % box sprite
            end
            
            fliptime.rest(FRAME,BLOCK) = cgflip( color.background );
            
            if options.parallel
                sendParallel( FRAME, n, trig.rest, ioObj, address )
            end
        end
        
    end
    
    % ------ command window
    
    disp('************')
    disp(num2str(TRIAL))
    
    % ----- cue period

    for FRAME = 1:f.cue
        
        cgdrawsprite( arrow_cue.sprite,  0, 0 ) % arrow cue
        
        fliptime.cue(FRAME,TRIAL) = cgflip( color.background );
        
        if options.parallel
            sendParallel( FRAME, n, cue_box, ioObj, address )
        end
        
    end
    
    % ----- flicker period
    
    for FRAME = 1:f.flicker
       
        RGB = y4(FRAME,cue_box) - 1;
        RGB = RGB/255;
        cgdrawsprite( arrow_cue.sprite,  0, 0 ) % arrow cue
        fliptime.flicker(FRAME,TRIAL) = cgflip( RGB, RGB, RGB );
        
        if options.parallel
            sendParallel( FRAME, n, cue_box + 100, ioObj, address )
        end
        
    end

end

% ----- block rest

if options.rest
    
    BLOCK = BLOCK + 1;
    
    for FRAME = 1:f.rest
        
        %cgdrawsprite(sprite.display,0,0) % output display
        cgdrawsprite(sprite.textBox, 0, textbox.offset.bci )
        cgdrawsprite(BLOCK + 3000, 0, textbox.offset.bci ) % rest instruct%ion
        
        for BOX = 1:n.boxes
            cgdrawsprite( placeholder.sprite, X(BOX), Y(BOX) ) % placeholder
            cgdrawsprite( BOX + 2000, X(BOX), Y(BOX) ) % character
        end
        
        fliptime.rest(FRAME,BLOCK) = cgflip( color.background );
        
        if options.parallel
            sendParallel( FRAME, n, trig.rest, ioObj, address )
        end

    end
end

tocker.Train = hat;
ticToc.Train = ( tocker.Train - ticker.Train )/60;