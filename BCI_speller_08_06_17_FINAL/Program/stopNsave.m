
direct.results = [direct.resultsRoot 'StopNSavePlots\']; mkdir(direct.results);

%% timing?

FIELDS = fieldnames( fliptime );

h = figure;

switch doing
    case 'train'

        for FF = 1:3
            subplot(1,3,FF)
            df = diff( fliptime.( FIELDS {FF} ) );
            plot( df )
            title( FIELDS {FF} )
            xlim( [1 size(df,1)] )
            xlabel('Frames')

            if FF == 1
                ylabel( '\Deltafliptime (s)' )
            end
        end

        
        TIT = [ 'fliptime ' observer.fname.train  ];
        suptitle( TIT )
        saveas(h, [ direct.results TIT '.png' ] )
        
    case 'test'
        
        for FF = 2:4
            
            subplot(1,3,FF-1); hold on

            if strcmp( FIELDS {FF}, 'type' )
                tmp = fliptime.( FIELDS {FF} )( ~cellfun(@isempty, fliptime.( FIELDS {FF} )) );

                for TT = 1:size(tmp,1)
                    plot( diff( tmp{TT} ) )
                end

                xlim( [1 max(cellfun(@length,tmp))-1] )
            else

                df = diff( fliptime.( FIELDS {FF} ) );
                plot( df )
                xlim( [1 size(df,1)] )
            end
            
            title( FIELDS {FF} )
            xlabel('Frames')

            if FF == 2
                ylabel( '\Deltafliptime (s)' )
            end
            
        end

        TIT = [ 'fliptime ' observer.fname.test ];
        suptitle( TIT )
        saveas(h, [ direct.results TIT  '.png' ] )
        
        
        %% more timing!
        
        close all
        h = figure; hold on

        bar( cueTime(1:letter_count) )
        bar( getLetterTime(1:letter_count), 'r' )
        xlim([1 letter_count])
        xlabel( 'letter count' )
        ylabel( 'Time (s)')
        legend( {'cueTime' 'getLetterTime'} )
        
        TIT = [ 'calc.time.' observer.fname.test ];
        suptitle( TIT )
        saveas(h, [ direct.results TIT '.png' ] )
        
        %%
        
        close all
        h = figure;
        
        subplot(3,1,1)
        bar( diff( elapsed(1:WORD) ) )
        ylabel('Time (s)')
        title('Time per word')
        
        subplot(3,1,2)
        bar( cell2mat(data(1:WORD, D.missionSuccess)) )
        ylabel('success')
        title('Mission Success')
        
        subplot(3,1,3)
        bar( cell2mat(data(1:WORD, D.BCIWord_NumBackspaces)) )
        xlabel('Word')
        ylabel('# Backspaces')
        title('Number of backspaces')
        
        TIT = [ 'realtime.acc.' observer.fname.test ];
        suptitle( TIT )
        saveas(h, [direct.results TIT '.png' ] )        

end


%% stop real-time acquisition (biosemi2ft.exe) and save data

if options.record_eeg
    keyInject( wname, 'd', wname ) % stop save!
    keyInject( wname, [ hex2dec('01B') '__' ], wname ) % escape key, stop real-time!
end

%% stop eyetracking

if options.eyetracker
    switch doing
        case 'train'
            FNAME = observer.fname.train;
        case 'test'
            FNAME = observer.fname.test;
    end
    stop_eyetracker_Speller
end
%% save data
observer.stop_clock = clock;

clear h % removes figure warning from save!

switch doing
    case 'train'
        tic; save( [ direct.data observer.fname.train '.mat' ] ); toc
    case 'test'
        tic; save( [ direct.data observer.fname.test '.mat' ] ); toc
end


disp( observer )
diary off


%% end cogent

cgshut
cogstd('spriority','normal');