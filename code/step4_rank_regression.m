%% Rank regression: category, luminance, valence on the per-image pupil
%
% PRIMARY ANALYSIS 
%   per participant, per timepoint, regress the 300 per-image pupil values
%   on category (dummy) + rank(luminance) + rank(valence); test each
%   predictor's betas across the 40 participants with a Bayes factor.
%
% OUTPUT per predictor: mean beta + BF timecourse
% Category contrasts: isFace = face-object, isIllusory = illusory-object,
% illusory-face by subtraction.

%% load data
load('results/allres.mat','dat')
pd = dat.pupil_perim;            % [nTime x 300 x nSub]
timevect = dat.timevect;
nTime = size(pd,1); nSub = size(pd,3);

md = load('results/allmodeldata.mat','dat');
lum = md.dat.luminance.data(:);  % 300, face/illus/obj order
val = md.dat.valence.mu(:);
clear dat

% categories
label = [ones(100,1); 2*ones(100,1); 3*ones(100,1)];  % 1=F 2=I 3=O
isFace     = double(label==1);
isIllusory = double(label==2);

% rank-transform continuous predictors, then z-score
zc = @(x)(x-mean(x))./std(x);
lumR = zc(tiedrank(lum));
valR = zc(tiedrank(val));

% construct predictors
X = [isFace isIllusory lumR valR];   % object reference
pidx = struct('face',1,'illusory',2,'luminance',3,'valence',4);

%% fit
betas = nan(size(X,2)+1, nTime, nSub);

for s = 1:nSub
    fprintf('rank reg: sub-%02i\n',s);
    for t = 1:nTime
        y = squeeze(pd(t,:,s))'; % pupil data
        mdl = fitlm(X,y); % multiple regression
        betas(:,t,s) = mdl.Coefficients.Estimate;
    end
end

%% assemble contrasts / predictors and BFs
bfun = @(m) reshape(bayesfactor_R_wrapper(m,'returnindex',2,'verbose',false, ...
    'args','mu=0,rscale="medium",nullInterval=c(-0.5,0.5)'),[],1);

stats = struct(); stats.timevect = timevect;

% category contrasts (object reference), betas are rows 2.. of Estimate
b(:,:,1) = squeeze(betas(2,:,:));    % face - object
b(:,:,2)  = squeeze(betas(3,:,:));    % illusory - object
b(:,:,3) = b(:,:,2) - b(:,:,1);   % illusory - face (subtraction)
b(:,:,4)      = squeeze(betas(4,:,:));
b(:,:,5)      = squeeze(betas(5,:,:));

stats.betas = b;
stats.predictors = {'faceobj' 'illobj' 'illface' 'luminance' 'valence'};
stats.predictorlabels = {'face_vs_object','illusory_vs_object','illusory_vs_face','luminance','valence'};

for p = 1:length(stats.predictors)
    s = struct();
    dat = b(:,:,p);
    s.mu = mean(dat,2);
    s.se = std(dat,[],2)/sqrt(size(dat,2));
    s.bf = bfun(dat);
    stats.results.(stats.predictors{p}) = s;
end

save('results/stats_rank_regression.mat','stats','-v7.3');

%% report peaks
fprintf('\n=== Rank regression (category + ranked luminance + ranked valence) ===\n');
for i = 1:numel(stats.predictors)
    s = stats.results.(stats.predictors{i});
    [~,pk] = max(abs(s.mu));
    fprintf('\n%-20s peak beta %+0.4f at %4d ms | max BF %.3g%s \n', ...
        stats.predictors{i}, s.mu(pk), round(timevect(pk)), max(s.bf));
end
