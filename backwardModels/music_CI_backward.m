%
% music_CI_backward
% Part of the EEGmusic2020 code.
% Author: Octave Etard, 2020
%
% Train linear backward models in the Competing Instrument conditions for
% each subject with leave-one-data-part-out cross-validation; then save the
% results.
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
% use EEG data processed as EEGproc to reconstruct either the attended or
% the ignored instrument in each condition
%
% fGc = guitar attended x piano ignored
% fPc = piano attended x guitar ignored
%
conditions = {'fGc', 'fPc'};
EEGopt = [];
EEGopt.proc = 'HP-130'; % high-passed at 130 Hz
fields =  {'attended','ignored'};

% sampling rate
Fs = 5000;

% name of the feature describing the stimulus
featureOpt = [];
featureOpt.typeName = 'waveform';
% processing of the feature
featureOpt.proc = 'LP-2000'; % low-passed at 2000 Hz (anti-aliasing / resampling)

opt = [];
opt.mismatch = false;
% time window in which to train the model ; understood as time lag of
% predictor (here EEG) with respect to predicted (here stimulus) -->
% positive latencies = EEG post stimulus = causal / meaningful
opt.minLagT = 0;
opt.maxLagT = opt.minLagT + 15e-3; % 15 ms reconstruction window

% estimate performance using 10-s slices
opt.perfSliceT = 10; % in s

% top folder where to store the results
baseSaveFolder = EEGmusic2020.getPath('linearModelResults');


%%
nCond = numel(conditions);

% where is the EEG / stimulus data located
EEGopt.baseFolder = EEGmusic2020.getPath('EEG','processed');
featureOpt.baseFolder = EEGmusic2020.getPath('features');

EEGopt.Fs = Fs;
featureOpt.Fs = Fs;
EEGopt.procTrain = EEGopt.proc;
EEGopt.procTest = EEGopt.proc;

% --- options for the LMpackage functions
opt.nFeatures = 2; % predicting attended & ignored

% ---
% train subject specific decoders
opt.generic = false;
% display some progress information
opt.printProgress = true;

% --- options for the ridge regression 
trainOpt = [];
trainOpt.printOut = false;
trainOpt.accumulate = true;
trainOpt.method.name = 'ridge-eig-XtX'; % ridge regression
trainOpt.method.lambda = 10^-0.5; % regularisation parameters
trainOpt.method.normaliseLambda = true;


%% For each condition train & test model
for iCond = 1:nCond
     if opt.printProgress
        fprintf('Starting cond %i / %i\n\n',iCond,nCond);
    end   
    % train & test (cross-validation) a backward model for each intrument
    % / condition  & subjects
    CC = EEGmusic2020.linearBackwardModel(conditions{iCond},SID,parts,...
    EEGopt,featureOpt,fields,opt,trainOpt);

    %% save results
    d = [];
    % parameters
    d.SID = SID;
    d.condition = conditions{iCond};
    d.parts = parts;
    
    d.EEG = EEGopt;  
    d.feature = featureOpt;
    d.fields = fields;
    d.opt = opt;
    d.train = trainOpt;
    
    % results
    d.CC = CC;
    
    condition = sprintf('%s-AI',conditions{iCond}); % (A)ttended & (I)gnored
    [saveName,saveFolder] = EEGmusic2020.makePathSaveResults(condition,EEGopt.proc,...
        featureOpt.proc,featureOpt.typeName,Fs,opt.minLagT,opt.maxLagT,'backward',baseSaveFolder);
    
    LM.save(d,saveName,saveFolder);
end
%
%