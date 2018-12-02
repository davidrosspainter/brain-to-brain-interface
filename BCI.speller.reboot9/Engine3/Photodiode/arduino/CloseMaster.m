%% require input
input('press enter')

%% clear everything

fclose all;
close all
clear mex
clear
clc

%% set seed state

reset(RandStream.getGlobalStream,sum(100*clock))
seed_state = rng;
