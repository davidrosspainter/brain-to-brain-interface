function [n, lim, t, f, IDX_Hz, real_Hz ] = freqsettings(Hz, limit, fs, n)
% 
% [n, lim, t, f, IDX_Hz, real_Hz ] = freqsettings(Hz, limit)
% 
% INPUT:
% Hz = frequencies of interest. if Hz is a vector, indices will be
% generated for each element
% If Hz is an MxN matrix, an MxN matrix of indices will be generated
%
% limit = time period of interest in seconds i.e. [0 5]
%
% fs = EEG sampling freqency
%
% n = any structure n so as not to overwright
%
% OUTPUT:
% n:
% n.s - duration in sec
% n.x - duration in EEG sampling points - i.e.if n.s = 1, n.x = fs
% n.Hz - number of frequencies - M in MxN matrix of freqs
%
% lim:
% lim.s - limit which was inputed
% lim.x - limits in EEG sampling points
% 
% t - time vector from lim.s(1):lim.s(2) at sampling freq - for plotting
%
% f - frequency vector from 0Hz to fs at sampling freq - for plotting
% 
% IDX_Hz - indices of frequencies of interest in fft output
% 
% real_Hz - real frequencies at the indices in IDX_Hz - may differ from
% input depending on frequency resolution

n.Hz = length(Hz);

lim.s = limit; % epoch limits (seconds) relative to trigger

lim.x = ceil(lim.s*fs) + 1;
lim.x(2) = lim.x(2)  - 1;

n.s = lim.s(2)-lim.s(1);
n.x = lim.x(2)-lim.x(1)+1;

% t = (0:n.x-1)/fs;
t = lim.s(1):1/fs:lim.s(2)-1/fs;

f = 0 : 1/n.s : fs - 1/n.s; % f = 0 : 1/n.s : fs;

for CC = 1:size(Hz,1)
    for H = 1:size(Hz,2)
        [~, IDX_Hz(CC, H)] = min( abs( f - Hz(CC, H) ) );
        real_Hz(CC, H) = f(IDX_Hz(CC, H));
    end
end
 