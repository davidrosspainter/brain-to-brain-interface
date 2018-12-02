%% channels 2 acquire

idx.channels2acquire = 1:6;
N.elec = length(idx.channels2acquire);

labels = {'Iz' 'O1' 'Oz' 'O2' 'POz' 'FCz'}; % reference CPz
%labels = {'Iz' 'O1' 'Oz' 'O2' 'FCz'}; % reference CPz

%% amplifer options

% supported_fs = [32 64 128 256 512 600 1200 2400 4800 9600 19200 38400];
fs = 1200; % sampling_rate
options.NumberOfScans = 0; % if not == 0, override defaults

options.filter = 1; % 1 or 0 (DRP)

options.CommonGround = logical( [0 0 0 0] ); % g.tec: Array of 4 bool elements to enable or disable common ground
options.CommonReference = logical( [0 0 0 0] ); % g.tec: Array of 4 bool values to enable or disable common reference

options.ShortCutEnabled = false; % g.tec: Bool enabling or disabling g.USBamp shortcut
options.CounterEnabled = false; % makes channel 16 a counter channel: Show a counter on first recorded channel which is incremented with every block transmitted to the PC. Overruns at 1000000.
options.TriggerEnabled = true; % appends recorded channels with new trigger channel g.tec: scan the digital trigger channel with the analog inputs


%% gUSBampInternalSignalGenerator (all amplifiers have the same generator when synchronized)

gusbamp_siggen = gUSBampInternalSignalGenerator();

gusbamp_siggen.Enabled = false; % g.tec: true or false
gusbamp_siggen.Frequency = 10;
gusbamp_siggen.WaveShape = 3; % Can be 1 (square), 2 (saw tooth), 3 (sine) 4 (DRL) or 5 (noise)
gusbamp_siggen.Amplitude = 10; % mV (max 250)
gusbamp_siggen.Offset = 0;


%% amplifer sampling settings

load( 'filters.mat', 'BandpassFilters', 'NotchFilters', 'F', 'supported_fs' )

%              FilterIndex: 1
%             SamplingRate: 2
%                    Order: 3
%     LowerCutoffFrequency: 4
%     UpperCutoffFrequency: 5

if options.NumberOfScans ~= 0
    NumberOfScans = options.NumberOfScans;
else
    NumberOfScans = supported_fs( 2, supported_fs(1,:) == fs ); % default value
end



% ( 1000 ./ supported_fs(1,:) ) .* supported_fs(2,:)

switch fs
    case 256
        BandpassFilterIndex = 47;   % 47         256           8           1         100 
        NotchFilterIndex    = 2;    % 2          256           4          48          52
    case 512
        BandpassFilterIndex = 72; % 72     512       8       1     100
        NotchFilterIndex = 4; % 4     512       4      48      52
    case 1200
        BandpassFilterIndex = 132; % 132    1200       8       1     100
        NotchFilterIndex = 8; % 8    1200       4      48      52
    case 38400
        BandpassFilterIndex = 363;  % 363       38400       4       1     100
        NotchFilterIndex = 18;      % 18        38400       4      48      52
    otherwise
        BandpassFilterIndex = -1; % (-1 = no filter)
        NotchFilterIndex = -1; % (-1 = no filter)
end

if ~options.filter
    BandpassFilterIndex = -1; % (-1 = no filter)
    NotchFilterIndex = -1; % (-1 = no filter)
end


%% configure interface

gds_interface = gtecDeviceInterface;

gds_interface.IPAddressHost = '127.0.0.1';
gds_interface.IPAddressLocal = '127.0.0.1';
gds_interface.HostPort = 50223;
gds_interface.LocalPort = 50224;

connected_devices = gds_interface.GetConnectedDevices();
N.connected_devices = length( connected_devices );

gusbamp_configs( 1, 1:N.connected_devices ) = gUSBampDeviceConfiguration();
gds_interface.DeviceConfigurations = gusbamp_configs;


%% set device order

N.amplifiers = 4;
N.gUSBampChannels = 16;

ampChanIdx(1,:) = 1:16;
ampChanIdx(2,:) = 17:32;
ampChanIdx(3,:) = 33:48;
ampChanIdx(4,:) = 49:64;

channelNames = cell(1,N.amplifiers);

for i = 1:N.amplifiers
    for j = 1:N.gUSBampChannels
        channelNames{i}{j} = num2str( ampChanIdx(i,j) );
    end
end


%% channels to acquire

N.channels2acquire = length( idx.channels2acquire ) * N.connected_devices + options.TriggerEnabled; % + 2 x printer port channels & read counter for saving and analysis

channels2acquire = ismember( 1:N.gUSBampChannels, idx.channels2acquire );

for i = 1 : N.connected_devices
    gusbamp_configs(1,i).Name = connected_devices(i).Name; % master ( master must be #1 or crash! ) - SYNC OUT
end

gds_interface.DeviceConfigurations = gusbamp_configs;
 

%% configure amplifers & channels

available_channels = cell( 1, N.connected_devices );

for i = 1 : N.connected_devices
    
    disp( [ 'configuring... ' gusbamp_configs(1,i).Name ] )
    
    %gusbamp_configs(1,i).Name = connected_devices(1,i).Name;
    
    available_channels{i} = gds_interface.GetAvailableChannels( gusbamp_configs(1,i).Name );
    
    % ----- SamplingRate & NumberOfScans
    
    gusbamp_configs(1,i).SamplingRate = fs;
    gusbamp_configs(1,i).NumberOfScans = NumberOfScans;
    
    % ----- CommonGround & CommonReference
    
    gusbamp_configs(1,i).CommonGround = options.CommonGround;
    gusbamp_configs(1,i).CommonReference = options.CommonReference;
    
    % ----- InternalSignalGenerator
    
    gusbamp_configs(1,i).InternalSignalGenerator = gusbamp_siggen;
    
    % ----- ShortCutEnabled, CounterEnabled & TriggerEnabled
    
    gusbamp_configs(1,i).ShortCutEnabled = options.ShortCutEnabled;
    gusbamp_configs(1,i).CounterEnabled = options.CounterEnabled;
    gusbamp_configs(1,i).TriggerEnabled = options.TriggerEnabled;
    
    % ----- individual channel settings
    
    for j = 1 : size( gusbamp_configs(1,i).Channels, 2)
        if ( available_channels{i}(1,j) )
            
            % ----- recording
            gusbamp_configs(1,i).Channels(1,j).Available = true; % don't know what this does
            gusbamp_configs(1,i).Channels(1,j).Acquire = channels2acquire(j); % if false, channel not acquired in the read
            
            % ----- filters
            gusbamp_configs(1,i).Channels(1,j).BandpassFilterIndex = BandpassFilterIndex;
            gusbamp_configs(1,i).Channels(1,j).NotchFilterIndex = NotchFilterIndex;
            
            % ----- bipolar channels
            gusbamp_configs(1,i).Channels(1,j).BipolarChannel = 0; % do not use a bipolar channels
            
        end
    end
    
end

gds_interface.DeviceConfigurations = gusbamp_configs;
gds_interface.SetConfiguration();
