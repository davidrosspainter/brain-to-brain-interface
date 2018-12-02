%% get words

FileID = fopen([direct.stim 'words.txt']);
C = textscan(FileID, '%s', 'Headerlines', 0);
fclose(FileID);

words_all = C{1,1};

n.words = length(words_all);
wordOrder = randperm(n.words);
words = words_all(wordOrder);


%% data

n.boxes = 40;

D.wordStim = 1;

D.wordGen = 2;
D.wordGen_IDX = 3;
D.wordGen_CharCount = 4;
D.wordGen_CharsTypedCount = 5;
D.wordGen_NumBackspaces = 6;

D.BCIWord = 7;
D.BCIWord_IDX = 8;
D.BCIWord_CharCount = 9;
D.BCIWord_CharsTypedCount = 10;
D.BCIWord_NumBackspaces = 11;

D.maxBCIChars = 12;
D.missionSuccess = 13;

data = cell( n.words, 13 );

data(:,D.wordStim) = words;

maxCharInputs = 3;

%% sprites - words (501:550)

letter.size = 80;
cgfont( 'Andale Mono', letter.size )

letter.color = [0.9 0.9 0.9];

cgpencol( letter.color )

sprite.words = nan(n.words,1);

for WORD = 1:n.words
    sprite.words(WORD) = WORD+500;
    n.char = size(words{WORD},2);
    
    wordsize.x = letter.size*n.char;
    wordsize.y = letter.size;
    
    cgmakesprite(sprite.words(WORD),  wordsize.x , wordsize.y, [0 0 0] )
    cgsetsprite(sprite.words(WORD))
    cgtrncol(sprite.words(WORD),'n')
    
    cgtext( words{WORD}, 0, 0  )
    cgsetsprite(0)
    
end


%% Sprites - enter text

% -- hit enter text
letter.size = 40;
cgfont( 'Andale Mono', letter.size )
cgpencol( [0.5 0.5 0.5] )

n.char = size('[ Enter To Submit ]',2);
wordsize.x = letter.size*n.char;
wordsize.y = letter.size;

cgmakesprite(sprite.hitEnter,  wordsize.x , wordsize.y, [0 0 0] )
cgsetsprite(sprite.hitEnter)
cgtrncol(sprite.hitEnter,'n')

cgtext('[ Enter To Submit ]', 0, 0  )
cgsetsprite(0)

% -- enter text text
letter.size = 70;
cgfont( 'Andale Mono', letter.size )

n.char = size('Enter Text',2);
wordsize.x = letter.size*n.char;
wordsize.y = letter.size;

cgmakesprite(sprite.inputText,  wordsize.x , wordsize.y, [0 0 0] )
cgsetsprite(sprite.inputText)
cgtrncol(sprite.inputText,'n')

cgtext('Enter Text', 0, 0  )
cgsetsprite(0)


%% Start cogent

% cgpencol( [0.1 0.1 0.1] )

cgpencol( [0.5 0.5 0.5] )

letter.size = 100; %70
cgfont( 'Andale Mono', letter.size )

elapsed = nan(n.words,1);

data = cell( n.words, 13 );
data(:,D.wordStim) = words;


%% pre-allocate results/data

n.letters_max = 800;

results.RHO = NaN(n.Hz, n.letters_max);
results.maxR = NaN(1, n.letters_max);
results.EEG = NaN( n.x, length( chan2use.unique ), n.letters_max );
results.photo = NaN( n.x, n.letters_max );
results.sampleIDX = NaN( n.x, n.letters_max );

getLetterTime = NaN(n.letters_max,1);
cueTime = NaN(n.letters_max,1);


%% preallocate fliptimes

fliptime.type = cell(n.words,1);
fliptime.cue = NaN(f.cue, n.letters_max);
fliptime.flicker = NaN(f.cue, n.letters_max);

%% photodiode trigger and dummy signal

letter_count = 0;
CUE_BOX = repmat( randperm(n.boxes)', n.letters_max / n.boxes, 1); 


%% Start experiment

ticker.Test = hat;

for WORD = 1:n.words
    
    % ----- initialise
    
    SPELL = true;
    phase = 'Keyboard';
    FRAME = 0;
    
    disp('***********************************')
    disp( [ 'CUE WORD = ' num2str(WORD) ] )
    disp( [ words{WORD} ] )
    
    cgpencol( [0.1 0.1 0.1] )
    %% get target word!
    
    while SPELL
        
        FRAME = FRAME + 1;
        
        switch phase
            
            case 'Keyboard'
                
                %% get keys
                
                [ks,kp] = cgkeymap;
                Inp = find(kp);
                
                if ~isempty(Inp) %% has there been an input?
                    
                    cogInp = find(ismember(cogentCharMap,Inp)); % map to our coords
                    data{WORD,D.wordGen_IDX} = [data{WORD,D.wordGen_IDX} cogInp]; % IDX
                    
                    % -- Actual Characters to print
                    if any(cogInp==30) % deal with Backspaces
                        if ~isempty(data{WORD,D.wordGen}) % if backspace is first entered character
                            data{WORD,D.wordGen}(end) = [];
                        end
                    else
                        data{WORD,D.wordGen} = [data{WORD,D.wordGen} characters{cogInp}];
                    end
                    
                    % -- generate sprite
                    cgmakesprite(sprite.textTyped,  textbox.size.x , wordsize.y, [0 0 0] )
                    cgtrncol(sprite.textTyped,'n')
                    cgsetsprite(sprite.textTyped)
                    cgtext(data{WORD,D.wordGen}, 0, 0  )
                    cgsetsprite(0)
                    
                end
                
                
                %% draw word
                cgdrawsprite(sprite.words(WORD), 0, 200 )
                
                
                %% draw textbox
                
                cgdrawsprite(sprite.textBox, 0, textbox.offset.key )
                cgdrawsprite(sprite.hitEnter, 0, -300 )
                
                % - text
                if isempty(data{WORD,D.wordGen})
                    cgdrawsprite(sprite.inputText, 0, textbox.offset.key )
                else
                    cgdrawsprite(sprite.textTyped, 0, textbox.offset.key )
                end
                
                fliptime.type{WORD}(FRAME) = cgflip( color.background );
                
                if options.parallel
                    sendParallel( FRAME, n, trig.rest, ioObj, address )
                end

                if any(Inp == 28) %% Enter key
                    %% store
                    
                    data{WORD,D.wordGen_CharCount} = length(data{WORD,D.wordGen});
                    data{WORD,D.wordGen_CharsTypedCount} = length(data{WORD,D.wordGen_IDX});
                    data{WORD,D.wordGen_NumBackspaces} = sum(data{WORD,D.wordGen_IDX}==30);
                    
                    data{WORD,D.maxBCIChars} = data{WORD,D.wordGen_CharCount}*maxCharInputs;
                    
                    %% move on
                    phase = 'BCI';
                    
                end
                
            case 'BCI'
                
                data{WORD,D.missionSuccess} = 0;
                
                if options.photodiode
                    word2type = [ data{WORD,D.wordGen_IDX} 38];
                end
                
                for LETTER = 1:data{WORD,D.maxBCIChars}
                    
                    letter_count = letter_count + 1;
                    
                    if options.photodiode
                        cue_box = word2type(LETTER);
                    else
                        cue_box = CUE_BOX( letter_count );
                    end

                    
                    %% Get letter
                    if LETTER == 1
                        cgmakesprite(sprite.textTyped,  textbox.size.x , wordsize.y, [0 0 0] )
                        cgsetsprite(sprite.textTyped)
                        cgtrncol(sprite.textTyped,'n')
                        cgtext(' ', 0, 0  )
                        cgsetsprite(0)
                        
                        cgmakesprite(sprite.textTypedShort,  textbox.size.x , wordsize.y, [0 0 0] )
                        cgsetsprite(sprite.textTypedShort)
                        cgtrncol(sprite.textTypedShort,'n')
                        cgtext(' ', 0, 0  )
                        cgsetsprite(0)
                        
                        
                        
                        for FRAME = 1:f.cue
                            
                            %% Display
                            for BOX = 1:n.boxes
                                cgdrawsprite( placeholder.sprite, X(BOX), Y(BOX) ) % placeholder
                                cgdrawsprite( BOX + 2000, X(BOX), Y(BOX)) % character
                                cgdrawsprite(sprite.textTypedShort, X(BOX), Y(BOX)+40 )
                            end
                            
                            % -----Draw Textbox
                            cgdrawsprite(sprite.textBox, 0, textbox.offset.bci )
                           
                            fliptime.cue(FRAME, letter_count) = cgflip( color.background );
                            
                        end
                    end
                        
                    
                    %% ----- flicker period
                    
                    for FRAME = 1:f.flicker
                        
                        for BOX = 1:n.boxes
                            
                            cgdrawsprite( y4(FRAME,BOX), X(BOX), Y(BOX) ) % box sprite
                            cgdrawsprite( BOX + 2000, X(BOX), Y(BOX) ) % character
                            cgdrawsprite(sprite.textTypedShort, X(BOX), Y(BOX)+40 )
                        end
                        
                        % -----Draw Textbox
                        cgdrawsprite(sprite.textBox, 0, textbox.offset.bci )
                        cgdrawsprite(sprite.textTyped, 0, textbox.offset.bci )
                        
                        % ----- photodiode trigger

                        if ismember( FRAME, 1:n.photo_frames )
                            cgdrawsprite( 256, mon.res(1)/2 - box.size/4, -mon.res(2)/2 + box.size/4, box.size/2, box.size/2 ) % box sprite
                        else
                            cgdrawsprite( y4(FRAME,cue_box), mon.res(1)/2 - box.size/4, -mon.res(2)/2 + box.size/4, box.size/2, box.size/2 ) % box sprite
                        end
                        
                        fliptime.flicker(FRAME, letter_count) = cgflip( color.background );
                        
                        if options.parallel
                            sendParallel( FRAME, n, cue_box + 100, ioObj, address )
                        end
                    end
                    
                    if data{WORD,D.missionSuccess} == 1
                        break
                    end
                    
                    %% ----- eye movement period
                    
                    ticker.cue = hat;
                    
                    for FRAME = 1:f.cue
                        
                        %% Display
                        for BOX = 1:n.boxes
                            cgdrawsprite( placeholder.sprite, X(BOX), Y(BOX) ) % placeholder
                            cgdrawsprite( BOX + 2000, X(BOX), Y(BOX)) % character
                            cgdrawsprite(sprite.textTypedShort, X(BOX), Y(BOX)+40 )
                        end
                        
                        % -----Draw Textbox
                        cgdrawsprite(sprite.textBox, 0, textbox.offset.bci )
                        cgdrawsprite(sprite.textTyped, 0, textbox.offset.bci )
                        
                        fliptime.cue(FRAME, letter_count) = cgflip( color.background );
                        
                        if options.parallel
                            sendParallel( FRAME, n, cue_box, ioObj, address )
                        end
                        
                        if FRAME == n.photo_frames %% read buffer to get letter
                            
                            ticker.bci = hat;
                            
                            [RHO, maxR, EEG, photo, prevSample, sampleIDX] = CCAF2_realtime2(n, epoch, template_Synth, erp2use_cca, Xnotch, Ynotch, Xlowpass, Ylowpass, Xharm, Yharm, prevSample, lim, cfg, blocksize, overlap, options, chan2use);
                            
                            results.RHO(:,letter_count) = RHO;
                            results.maxR( letter_count ) = maxR;
                            results.EEG(:,:,letter_count) = EEG;
                            results.photo(:,letter_count) = photo;
                            results.sampleIDX(:,letter_count) = sampleIDX;
                            
                            InpBCI = maxR; % <---- BCI selected letter!
                            
                            %%
                            
                            data{WORD,D.BCIWord_IDX} = [data{WORD,D.BCIWord_IDX} InpBCI]; % IDX
                            
                            % -- Actual Characters to print
                            if any(InpBCI==30) % deal with Backspaces
                                if ~isempty(data{WORD,D.BCIWord}) % if backspace is first entered character
                                    data{WORD,D.BCIWord}(end) = [];
                                end
                            else
                                data{WORD,D.BCIWord} = [data{WORD,D.BCIWord} characters{InpBCI}];
                            end
                            
                            cgpencol( [0.1 0.1 0.1] )
                            % -- generate sprite
                            cgmakesprite(sprite.textTyped,  textbox.size.x , wordsize.y, [0 0 0] )
                            cgtrncol(sprite.textTyped,'n')
                            cgsetsprite(sprite.textTyped)
                            cgtext(data{WORD,D.BCIWord} , 0, 0  )
                            cgsetsprite(0)
                            
                            short = data{WORD,D.BCIWord}; % get the last three letters typed
                            
                            if length(short) ==1 % deal withe the first two letters typed
                                short = short(end);
                            elseif length(short)==2
                                short = short((end-1):end);
                            elseif length(short)>2
                                short = short((end-2):end);
                            end
                            
                            cgpencol( [0.5 0.5 0.5] )
                            cgfont( 'Andale Mono', 40 )
                            cgmakesprite(sprite.textTypedShort,  textbox.size.x , wordsize.y, [0 0 0] )
                            cgtrncol(sprite.textTypedShort,'n')
                            cgsetsprite(sprite.textTypedShort)
                            cgtext(short , 0, 0  )
                            cgsetsprite(0)
                            cgfont( 'Andale Mono', 100 )
                            
                            
                            %%
                            getLetterTime(letter_count) = hat - ticker.bci;
                            %
                        end
                        
                        cueTime(letter_count) = hat - ticker.cue;
                        
                        if cueTime(letter_count) >= s.cue
                           break; 
                        end
                        
                    end
                    
                    %% generate new sprites
                    
                    
                    
                    % -- check if words typed allign with BCI words
                    if options.photodiode
                        if length(data{WORD,D.BCIWord}) == data{WORD,D.wordGen_CharCount}
                             data{WORD,D.missionSuccess} = 1;
                        end
                    else
                        if (strcmp(data{WORD,D.BCIWord}, [ data{WORD,D.wordGen}])) %nb change to remove space
                            data{WORD,D.missionSuccess} = 1;
                        end
                    end
                end
                
                data{WORD,D.BCIWord_CharCount} = length(data{WORD,D.BCIWord});
                data{WORD,D.BCIWord_CharsTypedCount} = length(data{WORD,D.BCIWord_IDX});
                data{WORD,D.BCIWord_NumBackspaces} = sum(data{WORD,D.BCIWord_IDX}==30);
                
                SPELL = false;
        end
    end
    
    %% timing
    
    elapsed(WORD) = hat - ticker.Test;
    
    if elapsed(WORD) >= options.testtime
       break; 
    end
    
end


%% timing!

tocker.Test = hat;
ticToc.Test = ( tocker.Test - ticker.Test )/60;


%% more timing

% wordTime = [elapsed(1); diff(elapsed(1:WORD))];
% 
% figure;
% hist(wordTime)