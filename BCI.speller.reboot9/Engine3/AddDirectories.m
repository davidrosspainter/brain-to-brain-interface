%% directories

direct.network = [ direct.engine 'Network.Buffer.DRP.24.09.18\' ];
addpath( direct.network )

direct.RealtimeHack = [ direct.network 'realtimeHack.10.11.17\' ];
addpath( direct.RealtimeHack )

direct.DataResultsRoot = [ direct.engine 'DataResults\' ];

direct.gNEEDaccessMATLABAPI = 'C:\Program Files\gtec\gNEEDaccessMATLABAPI\';
direct.gNEEDaccess = 'C:\Program Files\gtec\gNEEDaccess\';

addpath( genpath( direct.gNEEDaccessMATLABAPI ) )
addpath( genpath( direct.gNEEDaccess ) )

direct.toolbox = [ direct.engine 'matlabTools\' ];
direct.io64 = [ direct.toolbox  'io64\' ];
direct.hat = [ direct.toolbox 'hat\' ];
direct.schemer = [ direct.toolbox 'scottclowe-matlab-schemer-f8115af\' ];

addpath( direct.io64 )
addpath( direct.hat )
addpath( direct.schemer )
