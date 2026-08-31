function step1_make_image_models()

% for each stimulus, calculate values to associate with pupil response:
% -- mean luminance
% -- mean valence rating

stims = dir('stimuli/*.jpg');
imnames = {stims(:).name};
% reorder imnames so face,pareidolia, then object
imnames = imnames([find(contains(imnames,'face')) find(contains(imnames,'pare')) find(contains(imnames,'obj'))]);


%% set up and calculate luminance
lum=[];

for i = 1:length(imnames)
    
    % counter
    fprintf('Calculating values for %s\n',imnames{i});
    
    % read image
    ii = imread(sprintf('stimuli/%s',imnames{i}));
    ii = imresize(ii, [400 400]);

    if size(ii,3) == 1
        ii = cat(3,ii,ii,ii);
    end
    iig = rgb2gray(im2double(ii));
    
    % luminance
    lum(i) = mean2(iig);
        
end


%% now do valence scores
% analyse ratings data from online qualtrics for 300 stimuli

% read data from different tasks

val = dir('results/qualtrics-emotional-valence-data.xlsx');
val = readtable([val.folder '/' val.name]);
names = val.Properties.VariableNames(21:320);

dat = table2array(val(1:21,21:320));

% reorder ratings data to match order of rest of data (face,illusory,obj)
reorderIDX = [find(contains(names,'h')) find(contains(names,'p')) find(contains(names,'o'))];
dat_re = dat(:,reorderIDX);
valence = mean(dat_re,1);
val_se = std(dat_re,[],1)/sqrt(size(dat_re,1));

%% put data in structure

dat = struct();
dat.imagefiles = imnames;
dat.luminance.data = lum;
dat.valence.dat = dat_re;
dat.valence.mu = valence;
dat.valence.se = val_se;

%% make image vector

category = [repelem(1,100) repelem(2,100) repelem(3,100)];

dat.category = category;

save('results/allmodeldata.mat','dat')






