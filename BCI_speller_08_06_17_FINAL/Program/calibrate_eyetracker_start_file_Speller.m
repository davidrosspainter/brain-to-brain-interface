% #########################################################################
% #################### Calibrate and Start File ####################
% #########################################################################

cgfont('Andale Mono', 20 )
cgpencol(1,1,1)

% Run the calibration/validation routine....
status(36) = DLcgEyelinkDoTrackerSetup(ELdefaults,0,'DisplayUserCommand','DisplaySubjectCommand');

% now that everything is setup and prepared at this point - start the eyetracker data recording to file....
if Eyelink('IsConnected') ~= ELdefaults.notconnected
    if Eyelink('CheckRecording') ~= 0 % i.e. if not already recording, then start a recording
        % open a file to record to
        %filename_edf_eyetrackPC = '1.edf'; % 
        filename_edf_eyetrackPC = 'tmp.edf'; % used on the eyetracker PC - no more than 8 chars in length
        % i.e. the fifth block will be 'DLB_rvm5.edf' on the eyetracker
        
        Eyelink( 'OpenFile', filename_edf_eyetrackPC );
        pause(1); % to give the eyelink host some time to find and open the file
        % start recording eye position
        Eyelink('StartRecording');
    else
        errordlg('EyeTracker is already recording data at this time.','Error','modal');
    end
else
    errordlg('EyeTracker is not connected.','Error','modal');
end

% done with setting up data recording to a file
% send some preamble message to the eyetracker data file

Eyelink('Message', 'SYNCTIME');
Eyelink('Message', 'StartExperiment');
