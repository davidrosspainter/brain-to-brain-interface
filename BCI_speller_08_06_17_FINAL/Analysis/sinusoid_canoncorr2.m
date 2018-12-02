function rho = sinusoid_canoncorr2( n, TRIAL_HARM, templates_all, epoch )

rho = NaN( n.shifts, n.harmonics, n.Hz, n.trials_block );

for TT = 1:n.trials_block
    for FF2 = 1:n.Hz
        for HH = 1:n.harmonics

            trial2classify = squeeze( TRIAL_HARM(epoch,:,TT,HH));

            for SS = 1:n.shifts
                
                % disp( [ TT FF2 HH SS ] )
                
                if all( trial2classify(:) == 0 )
                    rho(SS,HH,FF2,TT) = 0;
                else
                    
                    templates = squeeze( templates_all(epoch,HH,SS,FF2) ); % ----- all shifts!
                    
                    try
                        [~,~,r,~,~] = canoncorr( trial2classify, templates );
                    catch
                         fuckedUp   
                    end
                    
                    rho(SS,HH,FF2,TT) = r;
                end
            end
        end
    end    
end