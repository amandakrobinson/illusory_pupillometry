function step2_run_eye_processing(subjnr)

%% get behavioural data and timing details

Subj = sprintf('P%d',subjnr);
DATA = load(sprintf('data/BEH/%s_BEH_DATA.mat',Subj));
EXP_PROPS = DATA.BEH_DATA.EXP_PROPS;
DATA_trialTimeTags = EXP_PROPS.DATA_trialTimeTags;

numTrialsPerSession = EXP_PROPS.numTrialsPerSession;
numSessions = 25;
numTrials = size(DATA_trialTimeTags,1);

%% set variables

realIndex = [1 3];

format longG
roundValue = 0.0005;

sampleFreq = 2000;
samplesPerMS = 2000/1000;

imageTime = (1000/3.75) / 2;

baselineTime_ms = round(imageTime*2);
sampleTime_ms = 1500; 

baselineTime_samples = baselineTime_ms * samplesPerMS;

fullTime_samples = (baselineTime_ms + sampleTime_ms) * samplesPerMS + 1;

timevect = -baselineTime_ms:.5:sampleTime_ms;

ANALYSIS_PROPS.downSampleDivider = 8;
ANALYSIS_PROPS.downSampleFreq = sampleFreq / ANALYSIS_PROPS.downSampleDivider;

TYPE_NAMES = {
    'FACE'
    'PARE'
    'OBJECT'};

%% Screen Dimensions

lengthOfPixelCM = 0.2715/10;
pixelsPerCM = 1/lengthOfPixelCM;
distFromScreen = 78;

EXP_PROPS.DVA_perPixel_fromCentre = asind(lengthOfPixelCM/distFromScreen);
EXP_PROPS.ppDVA = round(1/EXP_PROPS.DVA_perPixel_fromCentre);
ppDVA = EXP_PROPS.ppDVA;

%% set up data

errorLimit = 2*ppDVA;

nanErrorIDs = zeros(numTrials,2);
blinkErrorIDs = zeros(numTrials,2);
fixErrorIDs = zeros(numTrials,2);
allErrorIDs = zeros(numTrials,2);
validTypeTrialCount = zeros(3,1);
validImageCount = zeros(300,1);

% repetition-test bookkeeping: per valid trial, keep session number,
% image id and category so trial-level habituation can be modelled later.
repTrial_session  = [];   % session (repetition) index, 1..25
repTrial_image    = [];   % image id 1..300
repTrial_category = [];   % 1=face 2=illusory 3=object
repTrial_pupil    = [];   % downsampled pupil trace per trial (time x 1)
repTrial_serialpos = [];
repTrial_baseline = [];

DATA_pupilSize_sorted_reduced = struct;
DATA_IDsForThisFormat = struct;

validFixTrialCount = zeros(EXP_PROPS.numImagePerType,3);

DATA_bufferEYE_pos = nan(4,fullTime_samples,numTrials);
DATA_bufferEYE_pupil = nan(2,fullTime_samples,numTrials);
DATA_bufferEYE_blink = nan(2,fullTime_samples,numTrials);
DATA_trialTimeTags_ALL = nan(numTrials,3);

EXPERIMENT_DATA_ALL = DATA.BEH_DATA.EXPERIMENT_DATA(1:(numSessions*numTrialsPerSession),1:size(DATA.BEH_DATA.EXPERIMENT_DATA,2));
DATA_trialTimeTags_ALL(1:size(EXP_PROPS.DATA_trialTimeTags,1),:) = EXP_PROPS.DATA_trialTimeTags;

%% collate epoch data

realTrialNum = 0;
for sessionNum = 1 : numSessions
    disp([Subj ' - Sequence ' num2str(sessionNum)])

    % load eye data for that sequence
    DATA = load(sprintf('data/EYE/%s/%s_S%d_EYE_DATA.mat',Subj,Subj,sessionNum));

    for trialNumInSession = 1 : numTrialsPerSession

        realTrialNum = realTrialNum + 1;

        bufferTimes = round(DATA.bufferData(:,1),4);
        bufferTime_StartPresentation = round(round(DATA_trialTimeTags(realTrialNum,2)/roundValue)*roundValue,4);
        bufferPosition_StartPresentation = find(bufferTimes == bufferTime_StartPresentation);

        startFrame = bufferPosition_StartPresentation - samplesPerMS*baselineTime_ms;
        endFrame = bufferPosition_StartPresentation + samplesPerMS*sampleTime_ms;

        if startFrame > 0 && endFrame < size(DATA.bufferData,1) %if whole epoch is recorded
            lengthOfSample = size(startFrame:endFrame,2);
            DATA_bufferEYE_pos(1:4,1:lengthOfSample,realTrialNum) = DATA.bufferData(startFrame:endFrame,[2 3 5 6])';
            DATA_bufferEYE_pupil(1:2,1:lengthOfSample,realTrialNum) = DATA.bufferData(startFrame:endFrame,[4 7])';
            DATA_bufferEYE_blink(1:2,1:lengthOfSample,realTrialNum) = DATA.bufferData(startFrame:endFrame,[9 10])';
        end
    end
end

%% exclude trials for blinks or movements

%strange missing data detection
for eyeNum = 1 : 2
    for trialNum = 1 : numTrials
        for bufferTick = 1 : fullTime_samples
            if isnan(DATA_bufferEYE_pupil(eyeNum,bufferTick,trialNum))
                nanErrorIDs(trialNum,eyeNum) = 1;
                allErrorIDs(trialNum,eyeNum) = 1;
                DATA_bufferEYE_pos(realIndex(1,eyeNum):realIndex(1,eyeNum)+1,:,trialNum) = NaN;
                DATA_bufferEYE_pupil(eyeNum,:,trialNum) = NaN;
                break
            end
        end
    end
end

%blink detection
for eyeNum = 1 : 2
    for trialNum = 1 : numTrials
        for bufferTick = 1 : fullTime_samples
            if DATA_bufferEYE_blink(eyeNum,bufferTick,trialNum) == 1
                blinkErrorIDs(trialNum,eyeNum) = 1;
                allErrorIDs(trialNum,eyeNum) = 1;
                DATA_bufferEYE_pos(realIndex(1,eyeNum):realIndex(1,eyeNum)+1,:,trialNum) = NaN;
                DATA_bufferEYE_pupil(eyeNum,:,trialNum) = NaN;
                break
            end
        end
    end
end


%check if deviated from fixation
for eyeNum = 1 : 2
    for trialNum = 1 : numTrials
        for bufferTick = 1 : fullTime_samples
            if abs(DATA_bufferEYE_pos(realIndex(1,eyeNum),bufferTick,trialNum)) > errorLimit || abs(DATA_bufferEYE_pos(realIndex(1,eyeNum)+1,bufferTick,trialNum)) > errorLimit
                fixErrorIDs(trialNum,eyeNum) = 1;
                allErrorIDs(trialNum,eyeNum) = 1;
                DATA_bufferEYE_pos(realIndex(1,eyeNum):realIndex(1,eyeNum)+1,:,trialNum) = NaN;
                DATA_bufferEYE_pupil(eyeNum,:,trialNum) = NaN;
                break
            end
        end
    end
end


%baseline correct
DATA_bufferEYE_pos = DATA_bufferEYE_pos - mean(DATA_bufferEYE_pos(:,1:baselineTime_samples,:),2,'omitnan');
% capture pre-stimulus baseline pupil per trial (tonic arousal index),
% BEFORE baseline correction removes it. [2 eyes x numTrials]
DATA_baselinePupil = squeeze(mean(DATA_bufferEYE_pupil(:,1:baselineTime_samples,:),2,'omitnan'));
DATA_bufferEYE_pupil = DATA_bufferEYE_pupil - mean(DATA_bufferEYE_pupil(:,1:baselineTime_samples,:),2,'omitnan');

%best eye
eyeToUse = 1;
if sum(allErrorIDs(:,1)) > sum(allErrorIDs(:,2))
    eyeToUse = 2;
end

%% collate data by trial type
for trialNum = 1 : numTrials
    if allErrorIDs(trialNum,eyeToUse) == 0
        
        imageType = EXPERIMENT_DATA_ALL(trialNum,2);
        imageNum = EXPERIMENT_DATA_ALL(trialNum,3);
        imNum = (imageType-1)*100+imageNum;

        % collate trials per category
        validTypeTrialCount(imageType,1) = validTypeTrialCount(imageType,1) + 1;
        
        DATA_pupilSize_sorted_reduced.(TYPE_NAMES{imageType,1})(:,validTypeTrialCount(imageType,1)) = downsample(squeeze(DATA_bufferEYE_pupil(eyeToUse,:,trialNum)),ANALYSIS_PROPS.downSampleDivider);
        DATA_IDsForThisFormat.(TYPE_NAMES{imageType,1}){1,validTypeTrialCount(imageType,1)} = sprintf('%s%d',TYPE_NAMES{imageType,1},imageNum);


        % collate trials per distinct image
        validImageCount(imNum) = validImageCount(imNum) + 1;
        
        DATA_pupilSize_sorted_im.(sprintf('stim%d',imNum))(:,validImageCount(imNum)) = downsample(squeeze(DATA_bufferEYE_pupil(eyeToUse,:,trialNum)),ANALYSIS_PROPS.downSampleDivider);
        stimnames{1,imNum} = sprintf('%s%d',TYPE_NAMES{imageType,1},imageNum);

        % --- repetition-test records ---
        repTrial_session(end+1,1)  = EXPERIMENT_DATA_ALL(trialNum,1);   % true session no.
        repTrial_image(end+1,1)    = imNum;
        repTrial_category(end+1,1) = imageType;
        repTrial_serialpos(end+1,1) = mod(trialNum-1, 300) + 1;   % 1..300 within session
        repTrial_pupil(:,end+1)    = downsample(squeeze(DATA_bufferEYE_pupil(eyeToUse,:,trialNum)),ANALYSIS_PROPS.downSampleDivider);
        repTrial_baseline(end+1,1) = DATA_baselinePupil(eyeToUse, trialNum);

    end
end

timevect_reduced = downsample(timevect,ANALYSIS_PROPS.downSampleDivider);

%% now get means per image

for i = 1:length(stimnames)
    pd_perim(:,i) = squeeze(mean(DATA_pupilSize_sorted_im.(sprintf('stim%d',i)),2));
end


figure
hold on
for a=1:3
    n = ((a-1)*100+1):((a-1)*100+100);
    plot(timevect_reduced,mean(pd_perim(:,n),2))
end
legend({'face' 'illusory' 'object'})

save(sprintf('results/sub-%02i.mat',subjnr), ...
    'DATA_pupilSize_sorted_im', 'pd_perim', 'timevect_reduced', ...
    'repTrial_*')
end