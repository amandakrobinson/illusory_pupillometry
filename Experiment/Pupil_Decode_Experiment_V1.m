CCSXXXXSSSS     
%% TO DO

%make delay at start and eye of eye tracking period longer, to account for
%sample period



%% Determine next pNum to use

for pNum = 1 : 50
    Subj = strcat('P',num2str(pNum));
    filename = fullfile(strcat(directs.BEH_data,'\',Subj,'_BEH_DATA.mat'));
    if ~(exist(filename) == 2)
        break
    end
end


%% Code for Vpixx Button Box

Datapixx('Open')
Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache
Datapixx('LoadCalibration')

nBits = Datapixx('GetDinNumBits');

Datapixx('SetDinDataDirection', hex2dec('1F0000'));
Datapixx('SetDinDataOut', hex2dec('1F0000'));
Datapixx('SetDinDataOutStrength', 1);   % Set brightness of buttons

Datapixx('EnableDinDebounce');      % Filter out button bounce
%Datapixx('DisableDinDebounce');    % Uncomment this line to log gruesome details of button bounce
Datapixx('SetDinLog');              % Configure logging with default values


%% Open Psychtoolbox

% PsychDebugWindowConfiguration
% Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
whiteish_grey = white * 0.75;
blackish_grey = white * 0.25;
inc = white - grey;
red = [1 0 0];
green = [0 1 0];
blue = [0 0 1];
reddishGrey = [0.75 0.5 0.5];

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);

% Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

commandwindow

pause(1)

waitframes = 1;
topPriorityLevel = MaxPriority(window);

oldTextSize = Screen('TextSize', window, 15);
rotateMode = kPsychUseTextureMatrixForRotation;


%% Frame rate checker

EXP_PROPS.frameRate = 120;

if round(1/ifi) ~= EXP_PROPS.frameRate
    sca
    error('frame rate seems off...')
end


%% Screen Dimensions

lengthOfPixelCM = 0.2715/10;
pixelsPerCM = 1/lengthOfPixelCM;
distFromScreen = 78;

EXP_PROPS.DVA_perPixel_fromCentre = asind(lengthOfPixelCM/distFromScreen);
EXP_PROPS.pixelPerDVA_forCentre = round(1/EXP_PROPS.DVA_perPixel_fromCentre);
ppDVA = EXP_PROPS.pixelPerDVA_forCentre;


%% Stimulus Properties

EXP_PROPS.imagePositions = [
    0 0] * ppDVA;

EXP_PROPS.fixationPositions = [
    0 0] * ppDVA;

realFixation = zeros(2,2);
realFixation(:,1) = EXP_PROPS.fixationPositions(1,:);
realFixation(:,2) = EXP_PROPS.fixationPositions(1,:);

EXP_PROPS.fixationBound = 5 * ppDVA;

EXP_PROPS.frameRate = 120;
EXP_PROPS.numberOfImageStimuli = 96;
% imageFileNames = dir(directs.images);
EXP_PROPS.fixationRadius = 6;
EXP_PROPS.fixationPosition = [xCenter-EXP_PROPS.fixationRadius yCenter-EXP_PROPS.fixationRadius xCenter+EXP_PROPS.fixationRadius yCenter+EXP_PROPS.fixationRadius];

EXP_PROPS.imagePositionsFull(:,1) = [xCenter+EXP_PROPS.imagePositions(1,1)-200 yCenter+EXP_PROPS.imagePositions(1,2)-200 xCenter+EXP_PROPS.imagePositions(1,1)+200 yCenter+EXP_PROPS.imagePositions(1,2)+200];

EXP_PROPS.fixationPositionsFull(:,1) = [xCenter+EXP_PROPS.fixationPositions(1,1)-EXP_PROPS.fixationRadius yCenter+EXP_PROPS.fixationPositions(1,2)-EXP_PROPS.fixationRadius xCenter+EXP_PROPS.fixationPositions(1,1)+EXP_PROPS.fixationRadius yCenter+EXP_PROPS.fixationPositions(1,2)+EXP_PROPS.fixationRadius];


%% Experiment Properties


%THIS EXP IS RUN WITH A 120 Hz MONITOR, so we can match the image cycle Hz
%to a previous experiment (3.75 Hz)


EXP_PROPS.numImageFrames = 16;
EXP_PROPS.numISIFrames = 16;



%% Create trial structure

EXP_PROPS.numImageTypes = 3;
EXP_PROPS.numImagePerType = 100;
EXP_PROPS.numPresentationsPerImage = 25;

EXP_PROPS.numTrialsPerSession = EXP_PROPS.numImageTypes * EXP_PROPS.numImagePerType;
EXP_PROPS.numTrials = EXP_PROPS.numImageTypes * EXP_PROPS.numImagePerType * EXP_PROPS.numPresentationsPerImage;

EXPERIMENT_DATA = nan(EXP_PROPS.numTrials,6);


trialNum = 0;
startSessionTrialNum = 0;
for sessionNum = 1 : EXP_PROPS.numPresentationsPerImage
    startSessionTrialNum = trialNum + 1;
    for imageType = 1 : EXP_PROPS.numImageTypes
        for imageNum = 1 : EXP_PROPS.numImagePerType

            trialNum = trialNum + 1;
    
            EXPERIMENT_DATA(trialNum,1) = sessionNum;
            EXPERIMENT_DATA(trialNum,2) = imageType;
            EXPERIMENT_DATA(trialNum,3) = imageNum;

        end
    end
    randomised = EXPERIMENT_DATA(startSessionTrialNum:trialNum,:);
    randomised = randomised(randperm(size(randomised,1)),:);
    EXPERIMENT_DATA(startSessionTrialNum:trialNum,:) = randomised;
end



%% Ethics Form

HideCursor

% SetMouse(xCenter,yCenter);
% [X, Y, buttons] = GetMouse;
% while sum(buttons) > 0
%     [X, Y, buttons] = GetMouse;
% end
% 
% imageString = [directs.experiment '\ethicsForm.jpg'];
% [imageUint8, ~, alpha] = imread(imageString);
% imageTexture = Screen('MakeTexture', window, imageUint8);
% 
% proceedPoint = 230;
% 
% ethicsConsent = 0;
% while ethicsConsent == 0
%     Screen('FillRect', window, grey);
%     Screen('DrawTexture', window, imageTexture, [], [], [], [], [], [], [], rotateMode, []);
%     radDot = 5;
%     [X, Y, buttons] = GetMouse;
% 
%     if X > xCenter+proceedPoint-30 && X < xCenter+proceedPoint+120 && Y > yCenter+proceedPoint-30 && Y < yCenter+proceedPoint+30
%         DrawFormattedText(window, 'PROCEED',xCenter+proceedPoint,yCenter+proceedPoint, blackish_grey);
%         if buttons(1,1) == 1
%             ethicsConsent = 1;
%         end
%     else
%         DrawFormattedText(window, 'PROCEED',xCenter+proceedPoint,yCenter+proceedPoint, black);
%     end
%     Screen('FillOval', window, red, [X-radDot Y-radDot X+radDot Y+radDot]);
% 
%     Screen('Flip', window);
% end



%% Demographics

SetMouse(xCenter,yCenter);
[X, Y, buttons] = GetMouse;
while sum(buttons) > 0
    [X, Y, buttons] = GetMouse;
end

DEMOGRAPHICS.gender = 0;
while DEMOGRAPHICS.gender == 0
    Screen('FillRect', window, grey);
    DrawFormattedText(window, 'Gender?','center',yCenter-200, white);
    DrawFormattedText(window, 'Woman','center',yCenter-150, white);
    DrawFormattedText(window, 'Man','center',yCenter-50, white);
    DrawFormattedText(window, 'Not one of the above options','center',yCenter+50, white);
    DrawFormattedText(window, 'Prefer not to say','center',yCenter+150, white);
    radDot = 5;
    [X, Y, buttons] = GetMouse;

    if Y > yCenter-150-30 && Y < yCenter-150+30
        DrawFormattedText(window, 'Woman','center',yCenter-150, whiteish_grey);
        if buttons(1,1) == 1
            DEMOGRAPHICS.gender = 1;
        end
    elseif Y > yCenter-50-30 && Y < yCenter-50+30
        DrawFormattedText(window, 'Man','center',yCenter-50, whiteish_grey);
        if buttons(1,1) == 1
            DEMOGRAPHICS.gender = 2;
        end
    elseif Y > yCenter+50-30 && Y < yCenter+50+30
        DrawFormattedText(window, 'Not one of the above options','center',yCenter+50, whiteish_grey);
        if buttons(1,1) == 1
            DEMOGRAPHICS.gender = 3;
        end
    elseif Y > yCenter+150-30 && Y < yCenter+150+30
        DrawFormattedText(window, 'Prefer not to say','center',yCenter+150, whiteish_grey);
        if buttons(1,1) == 1
            DEMOGRAPHICS.gender = 4;
        end
    end
    Screen('FillOval', window, red, [X-radDot Y-radDot X+radDot Y+radDot]);
    Screen('Flip', window);
end



SetMouse(xCenter,yCenter);
[X, Y, buttons] = GetMouse;
while sum(buttons) > 0
    [X, Y, buttons] = GetMouse;
end

barHalf = 15 * ppDVA;
DEMOGRAPHICS.age = NaN;
randomXshift = (rand(1)*(barHalf*2))-barHalf;
SetMouse(xCenter+randomXshift,yCenter);
tic
while isnan(DEMOGRAPHICS.age)
    [X, Y, buttons] = GetMouse;
    if X > xCenter + barHalf
        X = xCenter + barHalf;
    elseif X < xCenter - barHalf
        X = xCenter - barHalf;
    end
    SetMouse(X,yCenter);
    currentAgeRating = round( ((X - (xCenter - barHalf)) / ((xCenter + barHalf) - (xCenter - barHalf)))*100 );
    if buttons(1,1) == 1
        reactionTime = toc;
        DEMOGRAPHICS.age = currentAgeRating;
    end

    colourOfMarker = whiteish_grey;
    if ~isnan(DEMOGRAPHICS.age)
        colourOfMarker = white;
    end
    
    Screen('FillRect', window, grey);
    DrawFormattedText(window, 'What is your age (in years)?','center',yCenter-(ppDVA*4), white);
    DrawFormattedText(window, num2str(currentAgeRating),'center',yCenter-(ppDVA*2), white);
    Screen('FillRect', window, blackish_grey, [xCenter-barHalf yCenter-5 xCenter+barHalf yCenter+5]);
    Screen('FillRect', window, colourOfMarker, [X-5 yCenter-30 X+5 yCenter+30]);
    Screen('Flip', window);
end



%% Instructions + Load the images

oldTextSize = Screen('TextSize', window, 18);

Screen('FillRect', window, grey);
DrawFormattedText(window, 'INSTRUCTIONS','center',yCenter-(ppDVA*9), white);

DrawFormattedText(window, 'This experiment will take about 45 mins to complete. It is made up of 25 sections.','center',yCenter-(ppDVA*7), white);
DrawFormattedText(window, 'You can take a short break between sections, if you need to.','center',yCenter-(ppDVA*6), white);

DrawFormattedText(window, 'Your task is very simple. There will be a small black dot in the middle of the screen.','center',yCenter-(ppDVA*4), white);
DrawFormattedText(window, 'Please look at the dot. Occasionally, the dot will briefly change to red.','center',yCenter-(ppDVA*3), white);
DrawFormattedText(window, 'When you see this flashed red dot appear, click the left mouse button as quickly as possible.','center',yCenter-(ppDVA*2), white);
DrawFormattedText(window, 'We use the red flashes to check that you are paying attention to the dot.','center',yCenter-(ppDVA*1), white);
DrawFormattedText(window, 'This is important for our analysis of your pupil dilation.','center',yCenter-(ppDVA*0), white);

DrawFormattedText(window, 'While you are doing this, you will be shown a rapid stream of images.','center',yCenter+(ppDVA*2), white);
DrawFormattedText(window, 'You do not need to pay attention to these, and there will be no questions about them.','center',yCenter+(ppDVA*3), white);

DrawFormattedText(window, 'Blink naturally during the experiment, and try to maintain the calibrated head position.','center',yCenter+(ppDVA*5), white);

DrawFormattedText(window, 'Any questions?','center',yCenter+(ppDVA*7), white);


DrawFormattedText(window, 'Loading the images...','center',yCenter+(ppDVA*9), white);

Screen('Flip', window);



% Load the images & create textures

fileDirects = {'RealFaces\'; 'IllusoryFaces\'; 'Objects\'};
imageTextures = nan(EXP_PROPS.numImagePerType,EXP_PROPS.numImageTypes);

for imageType = 1 : EXP_PROPS.numImageTypes
    imageFileNames = dir([directs.images, char(fileDirects(imageType,1))]);
    imageFileNames = imageFileNames(3:end,1);
    
    for imageNum = 1 : EXP_PROPS.numImagePerType
        imageString = [directs.images char(fileDirects(imageType,1)) imageFileNames(imageNum,1).name];
        [imageUint8, ~, alpha] = imread(imageString);
        imageTextures(imageNum,imageType) = Screen('MakeTexture', window, imageUint8);
    end
end


Screen('FillRect', window, grey);
DrawFormattedText(window, 'INSTRUCTIONS - to be CHANGED!!!','center',yCenter-(ppDVA*11), white);

% DrawFormattedText(window, 'There are 600 quick trials in this experiment. It will take about 45 mins to complete. You will get to take a short break every few minutes.','center',yCenter-(ppDVA*9), white);
% 
% DrawFormattedText(window, 'On each trial, you will see an image flashed on the screen.','center',yCenter-(ppDVA*7), white);
% DrawFormattedText(window, 'These will be flashed very briefly. Pay attention so you do not miss them.','center',yCenter-(ppDVA*6), white);
% 
% DrawFormattedText(window, 'After the image disappears, you will see another image with a grid checkerboard pattern.','center',yCenter-(ppDVA*5), white);
% DrawFormattedText(window, 'Below are some examples of images you might see.','center',yCenter-(ppDVA*4), white);

% imageString = [directs.experiment '\exampleImages.png']
% [imageUint8, ~, alpha] = imread(imageString);
% imageTexture = Screen('MakeTexture', window, imageUint8);
% Screen('DrawTexture', window, imageTexture, [], [], [], [], [], [], [], rotateMode, []);

DrawFormattedText(window, 'Ready! Click the middle mouse button to continue.','center',yCenter+(ppDVA*9), white);

Screen('Flip', window);
            


[X, Y, buttons] = GetMouse;
while sum(buttons) > 0
    [X, Y, buttons] = GetMouse;
end
while buttons(1,2) == 0
    [X, Y, buttons] = GetMouse;
end



%% first eye tracking check

while sum(buttons) > 0
    [X, Y, buttons] = GetMouse;
end

blueBound = [xCenter+((-10-2)*ppDVA) yCenter+((-0-2)*ppDVA) xCenter+((-10+2)*ppDVA) yCenter+((-0+2)*ppDVA)];
redBound = [xCenter+((+10-2)*ppDVA) yCenter+((-0-2)*ppDVA) xCenter+((+10+2)*ppDVA) yCenter+((-0+2)*ppDVA)];

%check eye tracking
[X, Y, buttons] = GetMouse;
SetMouse(xCenter,yCenter);
setBestEye = 0;
while setBestEye == 0
    [X, Y, buttons] = GetMouse;
    
    Screen('FillRect', window, grey);
    Screen('FillOval', window, white, EXP_PROPS.fixationPosition);
    
    Datapixx('RegWrRd');
    [xScreenLeft, yScreenLeft, xScreenRight, yScreenRight, xRawLeft, yRawLeft, xRawRight, yRawRight] = Datapixx('GetEyePosition');
    Screen('FillOval', window, blue, [xCenter+xScreenLeft-5 yCenter-yScreenLeft-5 xCenter+xScreenLeft+5 yCenter-yScreenLeft+5]);
    Screen('FillOval', window, red, [xCenter+xScreenRight-5 yCenter-yScreenRight-5 xCenter+xScreenRight+5 yCenter-yScreenRight+5]);
    
    Screen('FillRect', window, blue, blueBound);
    DrawFormattedText(window, 'Blue = Left Eye',xCenter+((-10-1)*ppDVA),yCenter+((-0)*ppDVA), white);
    Screen('FillRect', window, red, redBound);
    DrawFormattedText(window, 'Red = Right Eye',xCenter+((+10-1)*ppDVA),yCenter+((-0)*ppDVA), white);
    if abs(X - (xCenter+((-10)*ppDVA))) < 2*ppDVA && abs(Y - (yCenter+((-0)*ppDVA))) < 2*ppDVA
        if buttons(1,1) == 1
            setBestEye = 1;
        end
    elseif abs(X - (xCenter+((+10)*ppDVA))) < 2*ppDVA && abs(Y - (yCenter+((-0)*ppDVA))) < 2*ppDVA
        if buttons(1,1) == 1
            setBestEye = 2;
        end
    end

    radDot = 5;
    Screen('FillOval', window, white, [X-radDot Y-radDot X+radDot Y+radDot]);
    Screen('FillOval', window, white, EXP_PROPS.fixationPosition);
    Screen('Flip', window);
end

while sum(buttons) > 0
    [X, Y, buttons] = GetMouse;
end

pause(1)




%% Practice Trials





%% Full Loop

oldTextSize = Screen('TextSize', window, 16);


for sessionNum = 1 : EXP_PROPS.numPresentationsPerImage


    if sessionNum > 1
        %Break
        oldTextSize = Screen('TextSize', window, 18);
        
        [X, Y, buttons] = GetMouse;
        while sum(buttons) > 0
            [X, Y, buttons] = GetMouse;
        end
        
        %break
        [X, Y, buttons] = GetMouse;
        while buttons(1,2) == 0
            [X, Y, buttons] = GetMouse;
            SetMouse(xCenter,yCenter);
            Screen('FillRect', window, grey);
            DrawFormattedText(window, 'BREAK','center',yCenter-(ppDVA*10), white);
            DrawFormattedText(window, 'Take a few moments to rest your eyes.','center',yCenter-(ppDVA*8), white);
    
            DrawFormattedText(window, ['Session Number: ' num2str(sessionNum) ' / ' num2str(EXP_PROPS.numPresentationsPerImage)],'center',yCenter-(ppDVA*6), white);
            
            DrawFormattedText(window, 'Make sure you are seated correctly with your chin on the chin rest.','center',yCenter-(ppDVA*4), white);
            DrawFormattedText(window, 'Press the middle mouse button to continue.','center',yCenter-(ppDVA*3), white);
            
            DrawFormattedText(window, 'Data saved.','center',yCenter-(ppDVA*1), white);
            Screen('Flip', window);
        end
        
        while sum(buttons) > 0
            [X, Y, buttons] = GetMouse;
        end
        
        blueBound = [xCenter+((-10-2)*ppDVA) yCenter+((-0-2)*ppDVA) xCenter+((-10+2)*ppDVA) yCenter+((-0+2)*ppDVA)];
        redBound = [xCenter+((+10-2)*ppDVA) yCenter+((-0-2)*ppDVA) xCenter+((+10+2)*ppDVA) yCenter+((-0+2)*ppDVA)];
        
        %check eye tracking
        [X, Y, buttons] = GetMouse;
        SetMouse(xCenter,yCenter);
        setBestEye = 0;
        while setBestEye == 0
            [X, Y, buttons] = GetMouse;
            
            Screen('FillRect', window, grey);
            Screen('FillOval', window, white, EXP_PROPS.fixationPosition);
            
            Datapixx('RegWrRd');
            [xScreenLeft, yScreenLeft, xScreenRight, yScreenRight, xRawLeft, yRawLeft, xRawRight, yRawRight] = Datapixx('GetEyePosition');
            Screen('FillOval', window, blue, [xCenter+xScreenLeft-5 yCenter-yScreenLeft-5 xCenter+xScreenLeft+5 yCenter-yScreenLeft+5]);
            Screen('FillOval', window, red, [xCenter+xScreenRight-5 yCenter-yScreenRight-5 xCenter+xScreenRight+5 yCenter-yScreenRight+5]);
            
            Screen('FillRect', window, blue, blueBound);
            DrawFormattedText(window, 'Blue = Left Eye',xCenter+((-10-1)*ppDVA),yCenter+((-0)*ppDVA), white);
            Screen('FillRect', window, red, redBound);
            DrawFormattedText(window, 'Red = Right Eye',xCenter+((+10-1)*ppDVA),yCenter+((-0)*ppDVA), white);
            if abs(X - (xCenter+((-10)*ppDVA))) < 2*ppDVA && abs(Y - (yCenter+((-0)*ppDVA))) < 2*ppDVA
                if buttons(1,1) == 1
                    setBestEye = 1;
                end
            elseif abs(X - (xCenter+((+10)*ppDVA))) < 2*ppDVA && abs(Y - (yCenter+((-0)*ppDVA))) < 2*ppDVA
                if buttons(1,1) == 1
                    setBestEye = 2;
                end
            end
        
            radDot = 5;
            Screen('FillOval', window, white, [X-radDot Y-radDot X+radDot Y+radDot]);
            Screen('FillOval', window, white, EXP_PROPS.fixationPosition);
            Screen('Flip', window);
        end

    end
    
    while sum(buttons) > 0
        [X, Y, buttons] = GetMouse;
    end

    Screen('FillRect', window, grey);
    Screen('FillOval', window, white, EXP_PROPS.fixationPositionsFull(:,1));
    Screen('Flip', window);
    
    pause(2)






    oldTextSize = Screen('TextSize', window, 16);

    timeSinceAttendCheck = 2;

    Priority(topPriorityLevel);
    Datapixx('SetupTPxSchedule');
    Datapixx('RegWrRd');
    Datapixx('StartTPxSchedule');
    Datapixx('RegWrRd');


    for trialNumInSession = 1 : EXP_PROPS.numTrialsPerSession
        trialNum = ((sessionNum - 1) * EXP_PROPS.numTrialsPerSession) + trialNumInSession;

        imageType = EXPERIMENT_DATA(trialNum,2);
        imageNum = EXPERIMENT_DATA(trialNum,3);

        %Attention check
        EXPERIMENT_DATA(trialNum,4) = 0;
        dice = rand(1);
        if dice < 0.05 && timeSinceAttendCheck > 2
            tic
            EXPERIMENT_DATA(trialNum,4) = 1;
            trialNumOfLastCheck = trialNum; %note that it comes before this real trial num... 

            imageType_rand = ceil(rand(1)*3);
            imageNum_rand = ceil(rand(1)*100);

            for isiFrame = 1 : EXP_PROPS.numISIFrames
                [xScreenLeft, yScreenLeft, xScreenRight, yScreenRight, xRawLeft, yRawLeft, xRawRight, yRawRight] = Datapixx('GetEyePosition');
                Screen('FillRect', window, grey);
                if (setBestEye == 1 && (abs(xScreenLeft) > EXP_PROPS.fixationBound || abs(yScreenLeft) > EXP_PROPS.fixationBound) && xScreenLeft < 2000 && yScreenLeft < 2000) || (setBestEye == 2 && (abs(xScreenRight) > EXP_PROPS.fixationBound || abs(yScreenRight) > EXP_PROPS.fixationBound) && xScreenRight < 2000 && yScreenRight < 2000)
                    Screen('FillRect', window, reddishGrey);
                    Screen('FillRect', window, grey, EXP_PROPS.imagePositionsFull(:,1));
                    EXPERIMENT_DATA(trialNum,6) = 1;
                end
                Screen('FillOval', window, red, EXP_PROPS.fixationPositionsFull(:,1));
                Screen('Flip', window);
    
                if isiFrame == 1
                    Datapixx('RegWrRd');
                    EXP_PROPS.DATA_trialTimeTags(trialNum,1) = Datapixx('GetTime');
                end

                timeSinceAttendCheck = toc;
                [X, Y, buttons] = GetMouse;
                if buttons(1,1) == 1
                    if timeSinceAttendCheck < 2 && isnan(EXPERIMENT_DATA(trialNumOfLastCheck,5))
                        EXPERIMENT_DATA(trialNumOfLastCheck,5) = timeSinceAttendCheck;
                    else
                        EXPERIMENT_DATA(trialNumOfLastCheck,5) = 0;
                    end
                end
            end
            
            for imageFrame = 1 : EXP_PROPS.numImageFrames
                [xScreenLeft, yScreenLeft, xScreenRight, yScreenRight, xRawLeft, yRawLeft, xRawRight, yRawRight] = Datapixx('GetEyePosition');
                Screen('FillRect', window, grey);
                if (setBestEye == 1 && (abs(xScreenLeft) > EXP_PROPS.fixationBound || abs(yScreenLeft) > EXP_PROPS.fixationBound) && xScreenLeft < 2000 && yScreenLeft < 2000) || (setBestEye == 2 && (abs(xScreenRight) > EXP_PROPS.fixationBound || abs(yScreenRight) > EXP_PROPS.fixationBound) && xScreenRight < 2000 && yScreenRight < 2000)
                    Screen('FillRect', window, reddishGrey);
                    Screen('FillRect', window, grey, EXP_PROPS.imagePositionsFull(:,1));
                    EXPERIMENT_DATA(trialNum,6) = 1;
                end
                Screen('DrawTexture', window, imageTextures(imageNum_rand,imageType_rand), [], EXP_PROPS.imagePositionsFull(:,1), [], [], [], [], [], rotateMode, []);
                Screen('FillOval', window, red, EXP_PROPS.fixationPositionsFull(:,1));
                Screen('Flip', window);

                if imageFrame == 1
                    Datapixx('RegWrRd');
                    EXP_PROPS.DATA_trialTimeTags(trialNum,2) = Datapixx('GetTime');
                end

                timeSinceAttendCheck = toc;
                [X, Y, buttons] = GetMouse;
                if buttons(1,1) == 1
                    if timeSinceAttendCheck < 2 && isnan(EXPERIMENT_DATA(trialNumOfLastCheck,5))
                        EXPERIMENT_DATA(trialNumOfLastCheck,5) = timeSinceAttendCheck;
                    else
                        EXPERIMENT_DATA(trialNumOfLastCheck,5) = 0;
                    end
                end
            end


        end

            
        for isiFrame = 1 : EXP_PROPS.numISIFrames
            [xScreenLeft, yScreenLeft, xScreenRight, yScreenRight, xRawLeft, yRawLeft, xRawRight, yRawRight] = Datapixx('GetEyePosition');
            Screen('FillRect', window, grey);
            if (setBestEye == 1 && (abs(xScreenLeft) > EXP_PROPS.fixationBound || abs(yScreenLeft) > EXP_PROPS.fixationBound) && xScreenLeft < 2000 && yScreenLeft < 2000) || (setBestEye == 2 && (abs(xScreenRight) > EXP_PROPS.fixationBound || abs(yScreenRight) > EXP_PROPS.fixationBound) && xScreenRight < 2000 && yScreenRight < 2000)
                Screen('FillRect', window, reddishGrey);
                Screen('FillRect', window, grey, EXP_PROPS.imagePositionsFull(:,1));
                EXPERIMENT_DATA(trialNum,6) = 1;
            end
            Screen('FillOval', window, black, EXP_PROPS.fixationPositionsFull(:,1));
            Screen('Flip', window);

            if isiFrame == 1
                Datapixx('RegWrRd');
                EXP_PROPS.DATA_trialTimeTags(trialNum,1) = Datapixx('GetTime');
            end

            timeSinceAttendCheck = toc;
            [X, Y, buttons] = GetMouse;
            if buttons(1,1) == 1
                if timeSinceAttendCheck < 2 && isnan(EXPERIMENT_DATA(trialNumOfLastCheck,5))
                    EXPERIMENT_DATA(trialNumOfLastCheck,5) = timeSinceAttendCheck;
                else
                    EXPERIMENT_DATA(trialNum,5) = 0;
                end
            end
        end
        
        for imageFrame = 1 : EXP_PROPS.numImageFrames
            [xScreenLeft, yScreenLeft, xScreenRight, yScreenRight, xRawLeft, yRawLeft, xRawRight, yRawRight] = Datapixx('GetEyePosition');
            Screen('FillRect', window, grey);
            if (setBestEye == 1 && (abs(xScreenLeft) > EXP_PROPS.fixationBound || abs(yScreenLeft) > EXP_PROPS.fixationBound) && xScreenLeft < 2000 && yScreenLeft < 2000) || (setBestEye == 2 && (abs(xScreenRight) > EXP_PROPS.fixationBound || abs(yScreenRight) > EXP_PROPS.fixationBound) && xScreenRight < 2000 && yScreenRight < 2000)
                Screen('FillRect', window, reddishGrey);
                Screen('FillRect', window, grey, EXP_PROPS.imagePositionsFull(:,1));
                EXPERIMENT_DATA(trialNum,6) = 1;
            end
            Screen('DrawTexture', window, imageTextures(imageNum,imageType), [], EXP_PROPS.imagePositionsFull(:,1), [], [], [], [], [], rotateMode, []);
            Screen('FillOval', window, black, EXP_PROPS.fixationPositionsFull(:,1));
            Screen('Flip', window);
            
            if imageFrame == 1
                Datapixx('RegWrRd');
                EXP_PROPS.DATA_trialTimeTags(trialNum,2) = Datapixx('GetTime');
            end

            timeSinceAttendCheck = toc;
            [X, Y, buttons] = GetMouse;
            if buttons(1,1) == 1
                if timeSinceAttendCheck < 2 && isnan(EXPERIMENT_DATA(trialNumOfLastCheck,5))
                    EXPERIMENT_DATA(trialNumOfLastCheck,5) = timeSinceAttendCheck;
                else
                    EXPERIMENT_DATA(trialNum,5) = 0;
                end
            end
        end
        
    end

        
        

    % stop buffer
    Datapixx('RegWrRd');
    EXP_PROPS.DATA_trialTimeTags(trialNum,3) = Datapixx('GetTime');
    Priority(0);
    Datapixx('StopTPxSchedule');

    oldTextSize = Screen('TextSize', window, 18);
    Screen('FillRect', window, grey);
    DrawFormattedText(window, 'Saving data...','center',yCenter-(ppDVA*10), white);
    Screen('Flip', window);

    bufferStatus = Datapixx('GetTPxStatus');
    [bufferData, underflow, overflow] = Datapixx('ReadTPxData', bufferStatus.newBufferFrames);
    bufferTrialString = strcat('S',num2str(sessionNum));
%     DATA_eyeBuffer.(bufferTrialString) = bufferData;
    
    %Save EYE data
    filename = fullfile([directs.EYE_data,'\',Subj,'\',Subj,'_S',num2str(sessionNum),'_EYE_DATA.mat']);
    save(filename,'bufferData','-v7.3');

    %Save beh data
    filename = fullfile(strcat(directs.BEH_data,'\',Subj,'_BEH_DATA.mat'));
    BEH_DATA = struct;
    BEH_DATA.EXPERIMENT_DATA = EXPERIMENT_DATA;
    BEH_DATA.EXP_PROPS = EXP_PROPS;
    BEH_DATA.DEMOGRAPHICS = DEMOGRAPHICS;
    save(filename,'BEH_DATA','-v7.3');

end




%% Debrief Sheet

SetMouse(xCenter,yCenter);
[X, Y, buttons] = GetMouse;
while sum(buttons) > 0
    [X, Y, buttons] = GetMouse;
end

imageString = [directs.experiment '\debrief.jpg']
[imageUint8, ~, alpha] = imread(imageString);
imageTexture = Screen('MakeTexture', window, imageUint8);

Screen('FillRect', window, grey);
Screen('DrawTexture', window, imageTexture, [], [], [], [], [], [], [], rotateMode, []);
Screen('Flip', window);

pause(5)

% % ethicsConsent = 0;
% % while ethicsConsent == 0
% %     Screen('FillRect', window, grey);
% %     Screen('DrawTexture', window, imageTexture, [], [], [], [], [], [], [], rotateMode, []);
% %     Screen('Flip', window);
% % 
% %     [X, Y, buttons] = GetMouse;
% %     if sum(buttons(1,:)) > 0
% %         ethicsConsent = 1;
% %     end
% % end



sca







