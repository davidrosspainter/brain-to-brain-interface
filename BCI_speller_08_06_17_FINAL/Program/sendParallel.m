function sendParallel( FRAME, n, trig2use, ioObj, address )

% ----- parallel trigger
 
if ismember( FRAME, 1 : n.trigger_frames )
    TRIG = trig2use;
else
    TRIG = 0;
end

for PP = 1:n.ports
    io64(ioObj, address(PP), TRIG);
end
    
