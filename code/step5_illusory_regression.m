%% Graded analysis within illusory faces: what does the dilation scale with?
%
% Restricted to the 100 illusory images. Asks whether the pupil response to
% an illusory image scales with how strongly it is seen as a face
% (face-likeness rating), how far the face wins the categorisation decision
% (proportion "face"), its valence, and its luminance.

% Predictors (per illusory image, from Robinson et al. 2025):
%   R  = face-likeness rating
%   C  = proportion "face" in speeded categorisation
%   Val, Lum = valence, luminance
% All four are continuous and are rank-transformed then z-scored, following
% the same policy as the main rank regression

% Per participant, per timepoint, regress the 100 illusory-image pupil
% values on [R C Val Lum]; test each coefficient across participants (BF).

illIdx = 101:200;
fl = load('results/facelike_ratings.mat');
R = fl.ratingsdat.mean(illIdx);

cat = load('results/faceobjResults.mat');
C = mean(mean(cat.res.faceresp_image(illIdx,:,:),2),3)'; % take mean across presentation times and participants

md = load('results/allmodeldata.mat','dat');
lum = md.dat.luminance.data(:); 
val = md.dat.valence.mu(:);

% rank-transform all four, then z-score
zr = @(x)(zscore(tiedrank(x(:))));
Rz   = zr(R);
Cz   = zr(C);
Valz = zr(val(illIdx));
Lumz = zr(lum(illIdx));

% predictors
X = [Rz Cz Valz Lumz];        % face-likeness, categorisation, valence, luminance
pnames = {'facelikeness','categorisation','valence','luminance'};

%% get data
load('results/allres.mat','dat')

pd       = dat.pupil_perim;     % [nTime x 300 x nSubj]  (mean per image)
timevect = dat.timevect;

%% run regression
nTime = size(pd,1);
nStim = size(pd,2);
nSub  = size(pd,3);

betas = nan(4,nTime,nSub);
for s = 1:nSub
    fprintf('Regression: sub-%02i\n',s);
    for t = 1:nTime
        y = squeeze(pd(t,illIdx,s))';
        mdl = fitlm(X,y);
        betas(:,t,s) = mdl.Coefficients.Estimate(2:end);
    end
end

%% BF timecourses
stats = struct('timevect',timevect,'B',betas,'pnames',{pnames});

bf = nan(nTime,4);
for k = 1:4
    s=struct();
    dat = squeeze(betas(k,:,:));
    s.mu = mean(dat,2);
    s.se = std(dat,[],2)/sqrt(size(dat,2));
    v = bayesfactor_R_wrapper(dat,'returnindex',2,'verbose',false, ...
        'args','mu=0,rscale="medium",nullInterval=c(-0.5,0.5)');
    bf(:,k) = v(:);

    s.bf = bf(:,k);
    stats.results.(pnames{k}) = s;

end

save('results/stats_illusory_graded.mat','stats','-v7.3');

%% report
fprintf('\n=== Within-illusory graded model (outcome = illusory pupil) ===\n');
betas= stats.B;pnames = stats.pnames;
for k = 1:4
    mb = mean(betas(k,:,:),3);
    [~,pk] = max(abs(mb));
    fprintf('%-15s peak beta %+0.4f at %4d ms, BF=%.3g  | max BF %.3g\n', ...
        pnames{k}, mb(pk), round(stats.timevect(pk)), stats.results.(pnames{k}).bf(pk), max(stats.results.(pnames{k}).bf));
end
fprintf(['\nRead face-likeness and categorisation as the graded predictors; ' ...
    'valence and luminance are controls.\n']);

