%% Current Experiment

experiment.clock = cell(1,2);
experiment.clock{1} = clock;
experiment.session = ['S' num2str(experiment.number,'%02u') '.' datestr(now,'yy.mmm.dd.HH.MM.SS')];

experiment.direct = [ direct.DataResultsRoot experiment.session '\' ];
mkdir( experiment.direct )

experiment.dataFile = [ experiment.direct experiment.session '.bin' ];

if options.SaveEEG
    fid = fopen( experiment.dataFile, 'w');
end

save( [ direct.DataResultsRoot 'experiment.mat' ], 'experiment' )


%%

FNAME = [ direct.DataResultsRoot 'lastExperiment.txt'];
txt = strrep( [ experiment.dataFile ],'\','\\');

if exist( FNAME, 'file' )
    delete( FNAME )
end

fileID = fopen( FNAME, 'w' );
fprintf(fileID,txt);
fclose(fileID);
