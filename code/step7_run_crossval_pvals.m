%% Cross-validated peak test for the rank regression (complements step4)
%
% Addresses multiple comparisons across timepoints (Mathot & Vilotijevic,
% 2023, Behav Res Methods, "Cross-validation testing"), adapted to a
% two-stage design (per-participant betas -> group test):
%
%   1. Split participants into k folds (interleaved, deterministic).
%   2. For each fold, find the peak |t| of the group effect in the TRAINING
%      participants, within a search window fixed in advance.
%   3. Each held-out participant contributes their beta at that peak
%   4. One permutation p-value test across all participants, once per predictor.
%

%% settings

k         = 4;          % number of folds (fewer folds = less dependence)
searchwin = [0 1500];   % ms; window searched for the training peak
nperm     = 5000;       % sign-flip permutations
seed      = 1;          % for reproducible permutations

%% run full rank regression peak test

infile    = 'results/stats_rank_regression.mat';
outfile   = 'results/stats_rank_regression_cv.mat';

load(infile,'stats')
betas    = stats.betas;                 % [nTime x nSub x nPred]
timevect = stats.timevect(:)';
names    = stats.predictors;
[nTime, nSub, nPred] = size(betas);

dt     = median(diff(timevect));
search = find(timevect >= searchwin(1) & timevect <= searchwin(2));
folds  = mod(0:nSub-1, k) + 1;          % 1 2 3 4 1 2 3 4 ...

rng(seed);
flips = sign(rand(nSub, nperm) - 0.5);  % same flips for every predictor
flips = [ones(nSub,1) flips];           % column 1 = observed (no flip)

cv = struct();
cv.settings = struct('k',k,'searchwin',searchwin, ...
    'nperm',nperm,'seed',seed);
cv.folds = folds;
cv.predictors = names;

fprintf('\n=== Cross-validated peak test (%i folds, search %i-%i ms, %i perms) ===\n', ...
    k, searchwin(1), searchwin(2), nperm);

% run
for p = 1:nPred
    B = betas(:,:,p);                   % [nTime x nSub]
    tall = nan(1, nperm+1);             % t for observed (1) and each permutation

    for i = 1:nperm+1 % 1 is actual values
        Bi   = B .* flips(:,i)';        % flip whole timecourses per participant
        vals = nan(1, nSub);
        pkI  = nan(1, k);
        pkS  = nan(1, k);

        for f = 1:k % for each fold
            te = folds == f; % test fold
            tr = ~te; % training fold
            % group t-value in training participants at each timepoint
            tv = mean(Bi(:,tr),2) ./ (std(Bi(:,tr),[],2) ./ sqrt(sum(tr)));
            [~, j] = max(abs(tv(search)));
            pk = search(j);
            pkI(f) = pk;
            pkS(f) = sign(tv(pk));
            vals(te) = Bi(pk, te);
        end

        tall(i) = mean(vals) / (std(vals) / sqrt(nSub));

        if i == 1                       % actual results
            obsVals = vals;
            peakIdx = pkI;
            peakSign = pkS;
        end
    end

    tobs  = tall(1);
    tnull = tall(2:end);
    pperm = (1 + sum(abs(tnull) >= abs(tobs))) / (nperm + 1);

    r = struct();
    r.values      = obsVals;            % sign-aligned held-out betas
    r.mean        = mean(obsVals);
    r.se          = std(obsVals) / sqrt(nSub);
    r.t           = tobs;
    r.p_perm      = pperm;
    r.peakIdx     = peakIdx;
    r.peakTime    = timevect(peakIdx);
    r.peakSign    = peakSign;
    r.meanLatency = mean(timevect(peakIdx));


    cv.results.(names{p}) = r;

    % report
    fprintf('%-12s p_perm = %-7.4f t = %+6.2f', names{p}, pperm, tobs);
    fprintf('| peaks %s ms (mean %i)', mat2str(round(r.peakTime)), round(r.meanLatency));
    if numel(unique(peakSign)) > 1
        fprintf('  [peak sign differs across folds]');
    end
    fprintf('\n');
end

save(outfile,'cv','-v7.3');



%% run illusory regression peak test

infile    = 'results/stats_illusory_graded.mat';
outfile   = 'results/stats_illusory_graded_cv.mat';

load(infile,'stats')
betas    = stats.B;                 % [nPred x time x nSub]
timevect = stats.timevect(:)';
names    = stats.pnames;
[nPred, nTime, nSub] = size(betas);

dt     = median(diff(timevect));
search = find(timevect >= searchwin(1) & timevect <= searchwin(2));
folds  = mod(0:nSub-1, k) + 1;          % 1 2 3 4 1 2 3 4 ...

rng(seed);
flips = sign(rand(nSub, nperm) - 0.5);  % same flips for every predictor
flips = [ones(nSub,1) flips];           % column 1 = observed (no flip)

cv = struct();
cv.settings = struct('k',k,'searchwin',searchwin, ...
    'nperm',nperm,'seed',seed);
cv.folds = folds;
cv.predictors = names;

fprintf('\n=== Cross-validated peak test (%i folds, search %i-%i ms, %i perms) ===\n', ...
    k, searchwin(1), searchwin(2), nperm);

% run
for p = 1:nPred
    B = squeeze(betas(p,:,:));                   % [nTime x nSub]
    tall = nan(1, nperm+1);             % t for observed (1) and each permutation

    for i = 1:nperm+1 % 1 is actual values
        Bi   = B .* flips(:,i)';        % flip whole timecourses per participant
        vals = nan(1, nSub);
        pkI  = nan(1, k);
        pkS  = nan(1, k);

        for f = 1:k % for each fold
            te = folds == f; % test fold
            tr = ~te; % training fold
            % group t-value in training participants at each timepoint
            tv = mean(Bi(:,tr),2) ./ (std(Bi(:,tr),[],2) ./ sqrt(sum(tr)));
            [~, j] = max(abs(tv(search)));
            pk = search(j);
            pkI(f) = pk;
            pkS(f) = sign(tv(pk));
            vals(te) = Bi(pk, te);
        end

        tall(i) = mean(vals) / (std(vals) / sqrt(nSub));

        if i == 1                       % actual results
            obsVals = vals;
            peakIdx = pkI;
            peakSign = pkS;
        end
    end

    tobs  = tall(1);
    tnull = tall(2:end);
    pperm = (1 + sum(abs(tnull) >= abs(tobs))) / (nperm + 1); 

    r = struct();
    r.values      = obsVals;            % sign-aligned held-out betas
    r.mean        = mean(obsVals);
    r.se          = std(obsVals) / sqrt(nSub);
    r.t           = tobs;
    r.p_perm      = pperm;
    r.peakIdx     = peakIdx;
    r.peakTime    = timevect(peakIdx);
    r.peakSign    = peakSign;
    r.meanLatency = mean(timevect(peakIdx));


    cv.results.(names{p}) = r;

    % report
    fprintf('%-12s p_perm = %-7.4f t = %+6.2f', names{p}, pperm, tobs);
    fprintf('| peaks %s ms (mean %i)', mat2str(round(r.peakTime)), round(r.meanLatency));
    if numel(unique(peakSign)) > 1
        fprintf('  [peak sign differs across folds]');
    end
    fprintf('\n');
end

save(outfile,'cv','-v7.3');


%% run repetition regression peak test

infile    = 'results/stats_repetition.mat';
outfile   = 'results/stats_repetition_cv.mat';

load(infile,'stats')
betas    = stats.slope;                 % [nSub x nTime]
timevect = stats.timevect(:)';
[nSub, nTime] = size(betas);

dt     = median(diff(timevect));
search = find(timevect >= searchwin(1) & timevect <= searchwin(2));
folds  = mod(0:nSub-1, k) + 1;          % 1 2 3 4 1 2 3 4 ...

rng(seed);
flips = sign(rand(nSub, nperm) - 0.5);  % same flips for every predictor
flips = [ones(nSub,1) flips];           % column 1 = observed (no flip)

cv = struct();
cv.settings = struct('k',k,'searchwin',searchwin, ...
    'nperm',nperm,'seed',seed);
cv.folds = folds;

fprintf('\n=== Cross-validated peak test (%i folds, search %i-%i ms, %i perms) ===\n', ...
    k, searchwin(1), searchwin(2), nperm);

% run
B = betas';                   % [nTime x nSub]
tall = nan(1, nperm+1);             % t for observed (1) and each permutation

for i = 1:nperm+1 % 1 is actual values
    Bi   = B .* flips(:,i)';        % flip whole timecourses per participant
    vals = nan(1, nSub);
    pkI  = nan(1, k);
    pkS  = nan(1, k);

    for f = 1:k % for each fold
        te = folds == f; % test fold
        tr = ~te; % training fold
        % group t-value in training participants at each timepoint
        tv = mean(Bi(:,tr),2) ./ (std(Bi(:,tr),[],2) ./ sqrt(sum(tr)));
        [~, j] = max(abs(tv(search)));
        pk = search(j);
        pkI(f) = pk;
        pkS(f) = sign(tv(pk));
        vals(te) = Bi(pk, te);
    end

    tall(i) = mean(vals) / (std(vals) / sqrt(nSub));

    if i == 1                       % actual results
        obsVals = vals;
        peakIdx = pkI;
        peakSign = pkS;
    end
end

tobs  = tall(1);
tnull = tall(2:end);
pperm = (1 + sum(abs(tnull) >= abs(tobs))) / (nperm + 1);

r = struct();
r.values      = obsVals;            % sign-aligned held-out betas
r.mean        = mean(obsVals);
r.se          = std(obsVals) / sqrt(nSub);
r.t           = tobs;
r.p_perm      = pperm;
r.peakIdx     = peakIdx;
r.peakTime    = timevect(peakIdx);
r.peakSign    = peakSign;
r.meanLatency = mean(timevect(peakIdx));


cv.results = r;

% report
fprintf('repetition p_perm = %-7.4f t = %+6.2f', pperm, tobs);
fprintf('| peaks %s ms (mean %i)', mat2str(round(r.peakTime)), round(r.meanLatency));
if numel(unique(peakSign)) > 1
    fprintf('  [peak sign differs across folds]');
end
fprintf('\n');


save(outfile,'cv','-v7.3');