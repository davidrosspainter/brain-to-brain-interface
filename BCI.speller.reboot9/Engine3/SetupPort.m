% Parallel port

trig.obj = io64; % eeg trigger create an instance of the io32 object
trig.status = io64(trig.obj); % eeg trigger initialise the inpout32.dll system driver
%trig.address = [hex2dec('D030'),hex2dec('D010')]; % physical address of the destinatio I/O port; 378 is standard LPT1 output port address
trig.address = [hex2dec('2FF8'),hex2dec('21')]; % physical address of the destinatio I/O port; 378 is standard LPT1 output port address

if options.resetPort
    io64(trig.obj, trig.address(1), 0); % set the trigger port to 0 - i.e. no trigger
    io64(trig.obj, trig.address(2), 0); % set the trigger port to 0 - i.e. no trigger
end


%% Triggers

trig.startRecording = 254;
trig.stopRecording = 255;