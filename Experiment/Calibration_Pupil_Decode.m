

%% To exit

% alt+tab until on command window
% let go of alt+tab
% crtl + C
% enter
% try to type sca, then hit enter
% then ctrl + alt + delete
% arrow down to task manager and then enter to open
% if this doesn't close PTB, then try alt+tab again and close the PTB window that way
% if even this fails, try open the task manager again with ctrl+alt+delete


%On starting for first time, first press 'r' to reset the parameters, then
%press 8, then enter
%Then 60, then enter

%% Startup

clear all
close all
clearvars
sca
rng('shuffle');
commandwindow



%% Where are we???... what does it all mean?

directs = struct;
    
cd('..')
directs.main = cd;
directs.experiment = strcat(directs.main,'\Experiment');
directs.BEH_data = strcat(directs.main,'\Data\BEH');
directs.EYE_data = strcat(directs.main,'\Data\EYE');
directs.images = strcat(directs.experiment,'\Images\');
directs.calFiles = strcat(directs.main,'\Calibration_Files');
cd(directs.calFiles)

toolBox = 'C:\Toolbox\';

%Paths
addpath(genpath(strcat(toolBox,'Psignifit')),'-end')
addpath(genpath('C:\Program Files\VPixx Technologies\Software Tools\DatapixxToolbox_trunk\DatapixxToolbox'),'-end')
% addpath(genpath(strcat(researchProjects,'\Toolbox\QuestPlus-master')),'-end')
% addpath(genpath(strcat(toolBox,'mQUESTPlus-master')),'-end')
addpath(genpath(strcat(toolBox,'VPixx_CustomEye')),'-end')
addpath(genpath(strcat(toolBox,'Matlab_CustomFunctions')),'-end')


%% Eye tracker initialise and calibration & Other Datapixx startup commands

% For info, see page 67 of VPixx Application Guide
Datapixx('Open')
Datapixx('SetTPxAwake')
Datapixx('SetLedIntensity',8) %1-8

Datapixx('SetExpectedIrisSizeInPixels',170) %Copy from PyPixx demo test

Datapixx('RegWrRd')

% PsychDebugWindowConfiguration
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
screenNumber = max(screens);

TPxCalibrationTesting_BSedit_centreOnly_grey(1,screenNumber)
sca
