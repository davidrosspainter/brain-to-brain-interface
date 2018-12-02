function [latency,type] = find_triggers(sdata)

% convert to 32-bit integer representation and only preserve the lowest 24 bits
sdata = bitand(int32(sdata), 2^24-1);
byte1 = 2^8  - 1;
byte2 = 2^16 - 1 - byte1;
% byte3 = 2^24 - 1 - byte1 - byte2;

% get the respective status and trigger bits
trigger = bitand(sdata, bitor(byte1, byte2)); % this is contained in the lower two bytes
trigger = double(trigger)./65280;
trigger = trigger*255;

% determine when the respective status bits go up or down
flank_trigger = diff([0 trigger']);
    
% close all
% figure; hold on
% plot(trigger,'r')
% plot(flank_trigger >= 1,'b')
% plot(flank_trigger,'b')    

type = trigger( flank_trigger >= 1 );
latency = find( flank_trigger >= 1 )';