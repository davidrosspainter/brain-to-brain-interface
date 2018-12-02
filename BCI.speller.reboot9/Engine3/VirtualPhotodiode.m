
AMP = 100;

options.GenerateNoise = true;
noiseOn = false;

time = time + (NumberOfScans)/fs;

if any( ismember( data(:,end), 150  )) % viewing chat
   flickerOn = false;
   LUM = zeros(NumberOfScans,1);
end

switch flickerOn
    
    case false
        
        if any( ismember( data(:,end), 101:128  ))
            
            flickerOn = true;
            
            idx = find( ismember( data(:,end), 101:128 ), 1, 'first' );
            time = ((1:NumberOfScans)-idx)/fs; % reset time
            
            FREQ = Hz(data(idx,end)-100);
            THETA = theta(data(idx,end)-100);

            if ismember(data(idx,end)-100,21:28) && io64( trig.obj, trig.address(2) ) == 2 && options.GenerateNoise
                
                noiseOn = true;
                
                LUM = zeros(NumberOfScans,1);
                
                for FREQ = 50:100
                    LUM = LUM + 1000 * ( 1 + sin(2*pi*FREQ*time+rand*pi*2) )'; % contstruct signal
                end
                
            else
                
                noiseOn = false;
                
                LUM = AMP * ( sin(2*pi*FREQ*time+THETA) )'; % contstruct signal
                LUM( time < 0 ) = 0;  
            end
            
        else
            LUM = zeros(NumberOfScans,1);
        end
        
    case true
        
        if any( ismember( data(:,end), 1:28 ) )
            
            flickerOn = false;
            idx = find( ismember( data(:,end), 1:28 ), 1, 'first' );
            
            if ismember(data(idx,end),21:28) && io64( trig.obj, trig.address(2) ) == 2 && options.GenerateNoise && noiseOn

                LUM = zeros(NumberOfScans,1);
                
                for FREQ = 50:100
                    LUM = LUM + 1000 * ( sin(2*pi*FREQ*time+rand*pi*2) )'; % contstruct signal
                end
                
            else
                %FREQ = Hz(data(idx,end));
                %THETA = theta(data(idx,end));
                LUM = AMP * ( sin(2*pi*FREQ*time+THETA) )'; % contstruct signal
            end
            
            LUM(idx:end) = 0;
            
        else
            LUM = AMP * ( sin(2*pi*FREQ*time+THETA) )'; % contstruct signal
        end
        
end

%LUM = LUM + ( rand( size(LUM) ) .* .5*AMP ); % add noise to avoid Warning: X is not full rank.

data(:,1:end-1) = repmat( LUM, 1, size(data,2)-1);





