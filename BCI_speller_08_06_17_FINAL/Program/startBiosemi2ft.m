%% start real-time acquisition (biosemi2ft.exe)

function wname = startBiosemi2ft( FNAME, direct)

% ----- start recording
addpath( direct.keyInject ) % allows access to keyInject_sendKey.mexw64
addpath( direct.realtime_hack ) % allows access to buffer.mexw64 & biosemi2ft

fname.eeg = [ FNAME '.gdf' ];

fname.config = 'biosemi_config_64+photodiode_v2.txt';

command = [ 'cd "' direct.realtime_hack '" & biosemi2ft.exe ' fname.config ' ' direct.data fname.eeg ' -&' ];
wname = [ 'biosemi2ft.exe  ' fname.config ' ' direct.data fname.eeg ' -' ]; % two spaces after .exe!

!taskkill /F /IM cmd.exe /T
!taskkill /F /IM biosemi2ft.exe /T

system( ['cd "' direct.realtime_hack '" & buffer.exe -&'] ); % start buffer - necessary!

% kill the buffer necessary for reading buffer!
!taskkill /F /IM buffer.exe /T
!taskkill /F /IM cmd.exe /T

system( command ); % start acquisition!

keyInject( wname, 's', wname ) % start save!

disp( 'Saving data to:' )
disp( [ direct.data fname.eeg ] )