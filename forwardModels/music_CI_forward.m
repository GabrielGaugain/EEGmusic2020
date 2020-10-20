%
% music_CI_forward
% Part of the JoNmusic2020 code.
% Author: Octave Etard
%
% Train linear forward models by pooling data from the two Competing
% Instrument conditions with leave-one-data-part-out and
% leave-one-subject-out cross-validation ; then save the results.
%
%
%% Parameters
% subject IDs to use
SID = 1:17;
% 'EBIP01' to 'EBIP17'
SID = arrayfun(@(idx) sprintf('EBIP%02i',idx),SID,'UniformOutput',false);
% data from each condition divided in parts corresponding to different
% inventions: data parts indices to use here
% (1 was training block, not used)
parts = 2:7;
% conditions:
% short hands for the CI conditions 'focus(Guitar/Piano)Competing'
conditions = {'fGc','fPc'};
% sampling rate
Fs = 5000;
% processing of the EEG to use
EEGopt = struct();
EEGopt.proc  = 'HP-115'; % high-passed at 115 Hz as the data contains responses to guitar & piano

% name of the feature describing the stimulus
featureOpt = struct();
featureOpt.typeName = 'waveform';
% processing of the feature
featureProc = 'LP-2000';  % low-passed at 2000 Hz (anti-aliasing / resampling)
fields = {'attended','ignored'}; % fitting the 2 instruments together

% time window in which to train the model ; understood as time lag of
% predictor (here stimulus) with respect to predicted (here EEG) -->
% negative latencies = stimulus preceding EEG = causal / meaningful
opt = struct();
opt.minLagT = -45e-3; % in s
opt.maxLagT = 100e-3;

% estimate performance using 10-s slices
opt.perfSliceT = 10; % in s

% top folder where to store the results
baseSaveFolder = JoNmusic2020.getPath('linearModelsResults');


%%
nCond = numel(conditions);

% where is the EEG / stimulus data located
EEGopt.baseFolder = JoNmusic2020.getPath('EEG','processed');
featureOpt.baseFolder = JoNmusic2020.getPath('features');

EEGopt.Fs = Fs;
featureOpt.Fs = Fs;
featureOpt.procTrain = featureProc;
featureOpt.procTest = featureProc;

% --- options for the LMpackage functions
opt.nFeatures = 2; % 2 predictor features (attended / ignored)

% ---
% train a generic / population average model
opt.generic = true;
% display some progress information
opt.printProgress = true;

% --- options for the ridge regression
trainOpt = struct();
trainOpt.printOut = false;
trainOpt.accumulate = true;
trainOpt.method.name = 'ridge-eig-XtX'; % use ridge regression
trainOpt.method.lambda = 10.^(-6:0.5:6); % regularisation parameters
trainOpt.method.normaliseLambda = true;


%%
% train & test (cross-validation) a forward model for each intrument
% / condition (guitar or piano)
[model,CC] = JoNmusic2020.linearForwardModel(conditions,SID,parts,...
    EEGopt,featureOpt,fields,opt,trainOpt);


%% save results
d = struct();
% parameters
d.SID = SID;
d.condition = conditions;
d.parts = parts;

d.EEG = EEGopt;
d.feature = featureOpt;
d.fields = fields;
d.opt = opt;
d.train = trainOpt;

% results
d.CC = CC;
d.model = model;

[saveName,saveFolder] = JoNmusic2020.makePathSaveResults(conditions,EEGopt.proc,...
    featureProc,featureOpt.typeName,Fs,opt.minLagT,opt.maxLagT,'forward',baseSaveFolder);

LM.save(d,saveName,saveFolder);
%
%