n.channels = 64;
n.best = 4;

labels = {  'Fp1'    'AF7'    'AF3'    'F1'    'F3'    'F5'    'F7'    'FT7'    'FC5'    'FC3'    'FC1'    'C1'    'C3'    'C5'    'T7'    'TP7'    'CP5'    'CP3'    'CP1'    'P1'    'P3'    'P5'    'P7' ...
            'P9'    'PO7'    'PO3'    'O1'    'Iz'    'Oz'    'POz'    'Pz'    'CPz'    'Fpz'    'Fp2'    'AF8'    'AF4'    'Afz'    'Fz'    'F2'    'F4'    'F6'     'F8'    'FT8'    'FC6'    'FC4'    'FC2' ...
            'FCz'    'Cz'    'C2'    'C4'    'C6'    'T8'    'TP8'    'CP6'    'CP4'    'CP2'    'P2'    'P4'    'P6'    'P8'    'P10'    'PO8'    'PO4'    'O2' };


chan2use.OI = {'P1' 'P3' 'P5' 'P7' 'P9' 'PO7' 'PO3' 'O1' 'Iz' 'Oz' 'POz' 'Pz' 'P2' 'P4' 'P6' 'P8' 'P10' 'PO8' 'PO4' 'O2'};
chan2use.OI_idx = find( ismember( labels, chan2use.OI ) );

chan2use.realtime = {'Oz' 'Iz' 'O1' 'O2'};        
chan2use.realtime_idx = find( ismember( labels, chan2use.realtime ) );

chan2use.bad = {'P8'};
chan2use.bad_idx = find( ismember( labels, chan2use.bad ) );

load biosemiChanlocs