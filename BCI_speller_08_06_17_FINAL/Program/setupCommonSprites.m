%% timing

FIELDS = fieldnames(s);

for FF = 1:length(FIELDS)
    
    if length( s.( FIELDS {FF} ) ) == 1
        f.( FIELDS {FF} ) = round( s.( FIELDS {FF} ) * mon.ref );
    elseif length( s.( FIELDS {FF} ) ) == 2
        f.( FIELDS {FF} ) = round( s.( FIELDS {FF} ) .* mon.ref );
        f.( FIELDS {FF} ) = round(linspace(f.( FIELDS {FF} )(1), f.( FIELDS {FF} )(2), n.trials_block));
    end
    
end


%% parallel ports

if options.parallel
    
    addpath( direct.io64 )
    
    n.ports = length(options.port);
    address = NaN(n.ports,1);
    
    for PP = 1:n.ports
        address(PP) = hex2dec( options.port{PP} );
    end
    
    ioObj = io64;
    status = io64(ioObj);
    
    for PP = 1:n.ports
        io64(ioObj, address(PP), 0);
    end
end

n.trigger_frames = 4;


%% setup characters

characters = {  '1' '2' '3' '4' '5' '6' '7' '8' ...
    '9' '0' 'Q' 'W' 'E' 'R' 'T' 'Y' ...
    'U' 'I' 'O' 'P' 'A' 'S' 'D' 'F' ...
    'G' 'H' 'J' 'K' 'L' '<' 'Z' 'X' ...
    'C' 'V' 'B' 'N' 'M' ' ' ',' '.' };

cogentCharMap = [ 2  3  4  5  6  7  8  9  10 11 ...
    16 17 18 19 20 21 22 23 24 25 ...
    30 31 32 33 34 35 36 37 38 14 ...
    44 45 46 47 48 49 50 57 51 52];

cogentCharMap = cogentCharMap(charuse_idx);
characters = characters(charuse_idx);


%% allocate flicker positions

box.size = 140;
gap.size = 42;

pos.x = 71 - mon.res(1)/2 + box.size/2 : box.size + gap.size : mon.res(1)/2 - box.size/2;
% pos.y = -mon.res(2)/2 + 165 : box.size + gap.size : mon.res(2)/2 - box.size/2;
pos.y = -mon.res(2)/2 + 165 + 165/2 : box.size + gap.size : mon.res(2)/2 - box.size/2;

pos.y = pos.y(1:4);

[X, Y] = meshgrid( pos.x, pos.y );

X = imrotate(X,-90);
Y = imrotate(Y,-90);

X = X(:);
Y = Y(:)';

X = X(charuse_idxX);
Y = Y(charuse_idx);

n.boxes = length(X);

photodiode.size(1) = box.size/2;
photodiode.size(2) = box.size/2;


%% allocate flicker frequencies

% ----- epoch

d.model = s.flicker;
nx.model = mon.ref * d.model;
tModel = 1/mon.ref : 1/mon.ref : d.model;
tModel_short = 1/mon.ref : 1/mon.ref : d.model/n.epochs;
f.model = 0 : 1/d.model : mon.ref - 1/d.model;

% ----- Hz

y1 = NaN( nx.model, n.Hz );

theta_estimated = [];
freq_estimated = [];

for FREQ = 1:n.Hz
    tmp = 1/2 * ( 1 + sin(2*pi*Hz(FREQ)*tModel_short  + theta(FREQ) ) ); % contstruct signal
    
    tmp2 = [];
    for LL = 1:n.epochs
       tmp2 = [tmp2 tmp];
    end
    
    y1(:,FREQ) = tmp2; % contstruct signal
end

y2 = y1;

% ----- gamma correction!

load( [ direct.gamma '\merged.mat' ], 'CLUT' )

y3 = NaN( nx.model, n.Hz );

for FREQ = 1:n.Hz
    
    for SAMPLE = 1:nx.model
        [v,i] = min( abs( y2(SAMPLE,FREQ) - CLUT(:,2,end) ) );
        y3(SAMPLE,FREQ) = CLUT(i,1,end) / 255;
    end
    
end

y4 = (y3 .* 255) + 1; % convert to sprite numbers!


%% start cogent

cgopen( mon.res(1), mon.res(2), 0, mon.ref, mon.num)

config_keyboard % keys for calibration
start_cogent
clearkeys

cogstd('spriority','high') % 'normal', 'real-time'

cgfont( 'Andale Mono', 50 )
cgpencol(0,0,0)

cgflip( color.background )
cgflip( color.background )


%% sprites - flickering boxes (1:256)

for RGB = 1:256
    
    cgmakesprite(RGB, box.size, box.size, [0 0 0] )
    cgsetsprite(RGB)
    cgrect( 0, 0, box.size, box.size, [RGB-1 RGB-1 RGB-1] ./ 255 ) % box
    cgsetsprite(0)
    
end


%% sprites!!! (1001)

% ----- placeholder

placeholder.sprite = 1001;
placeholder.size = box.size;
placeholder.colour = [1 1 1];
placeholder.width = 5;

cgmakesprite( placeholder.sprite, box.size, box.size, [0 0 0] )
cgsetsprite( placeholder.sprite )
cgtrncol( placeholder.sprite, 'n')

cgpenwid( placeholder.width )

cgdraw( -placeholder.size/2, -placeholder.size/2, -placeholder.size/2, +placeholder.size/2, placeholder.colour )
cgdraw( +placeholder.size/2, -placeholder.size/2, +placeholder.size/2, +placeholder.size/2, placeholder.colour )
cgdraw( -placeholder.size/2, -placeholder.size/2, +placeholder.size/2, -placeholder.size/2, placeholder.colour )
cgdraw( -placeholder.size/2, +placeholder.size/2, +placeholder.size/2, +placeholder.size/2, placeholder.colour )

cgsetsprite(0)


%% sprites - textbox 1010-1014

textbox.size.x = 1700;
textbox.size.y = 150;
textbox.offset.bci = 350;
textbox.offset.key = -100;

sprite.textBox = 1010;
sprite.inputText = 1011;
sprite.textTyped = 1012;
sprite.hitEnter = 1013;
sprite.textTypedShort = 1014;

% -- textbox
cgloadbmp(sprite.textBox, [direct.stim 'textbox.bmp'], textbox.size.x, textbox.size.y)
cgtrncol(sprite.textBox, 'n')
cgsetsprite(0)


%% sprites - characters (2001:2040)
cgfont( 'Andale Mono', 50 )
letter.size = 50*1.5; % should be 32 - but want all leters to fit into sprite box - looking at you "W"
letter.color = [0.1 0.5 0.1];

cgpencol( letter.color )

for BOX = 1:n.boxes
    
    cgmakesprite(BOX+2000, letter.size, letter.size, [0 0 0] )
    cgsetsprite(BOX+2000)
    cgtrncol(BOX+2000,'n')
    
    % cgrect( X(BOX), Y(BOX), 32, 32, [0 1 0] ) % letter area
    
    posmod = -1-10;
    
    if BOX == 38
        posmod = +15-10;
    end
    
    if BOX == 39
        posmod = +14-10;
    end
    
    cgtext( characters{BOX}, 0, 0 + posmod )
    cgsetsprite(0)
    
    %     cgdrawsprite(BOX+2000,0,0)
    %     cgflip(color.background)
    
end
