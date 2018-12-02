% shut down the eyetracker


% stop eyelink data recording and automatically transfer the eyetracker data file onto the display PC..............
if Eyelink('IsConnected') ~= ELdefaults.notconnected
    if Eyelink('CheckRecording') == 0 % i.e. if it is currently recording data
        Eyelink('Stoprecording');
        Eyelink('CloseFile');
        % transfer eyetracker data file to PC using the predefined filenames
        filename_edf_displayPC1 = [ direct.edf filename_edf_eyetrackPC ]; % where the edf data will be transferred to on the display PC
        filename_edf_displayPC2 = [ direct.edf strrep( observer.fname, '.', '_'), '_block_' num2str(BLOCK) '.edf']; % where the edf data will be transferred to on the display PC
        Eyelink('ReceiveFile', filename_edf_eyetrackPC, filename_edf_displayPC1 ); % this brings file from the eyelink host to the display PC
        
        movefile( filename_edf_displayPC1, filename_edf_displayPC2, 'f' )
        
    else
        errordlg('EyeTracker is not recording data at this time.','Error','modal');
    end
else
    errordlg('EyeTracker is not connected.','Error','modal');
end

if Eyelink('IsConnected') ~= ELdefaults.notconnected
    Eyelink('Shutdown');
else
    errordlg('EyeTracker is not connected.','Error','modal');
end