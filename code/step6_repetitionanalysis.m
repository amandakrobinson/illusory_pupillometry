%% Repetition analysis: does the illusory effect attenuate across sessions?
%
% Each image is presented once per session across 25 sequences/sessions, so session
% number indexes how many times that image has been seen. If the illusory
% dilation is driven by novelty or surprise, it should decline as images
% repeat; if it reflects a stimulus-locked process (e.g. perceptual conflict
% re-instantiated on every presentation), it should not.
%
% DIFFERENCE-SCORE APPROACH. For each participant and timepoint we
% calculate illusory-minus-object difference within each session (mean over that
% session's illusory trials minus mean over its object trials), giving one
% difference per session. Subtracting the object mean removes any general
% across-session drift (fatigue, arousal decline) that affects both
% categories, so the residual is the illusory-specific effect. We regress
% this per-session difference on session number (1-25); the slope indexes
% how the illusory effect changes per repetition, and is tested across
% participants with a Bayes factor

datafiles = dir('results/sub-*.mat');
nSub = numel(datafiles);
tv = load(fullfile('results',datafiles(1).name),'timevect_reduced');
timevect = tv.timevect_reduced; nT = numel(timevect);

slope = nan(nSub,nT);   % per-session-difference regressed on session, per subj

for d = 1:nSub
    S = load(fullfile('results',datafiles(d).name), ...
        'repTrial_pupil','repTrial_category','repTrial_session','repTrial_image');
    pup  = S.repTrial_pupil;         % [nTime x nTrials]
    cat  = S.repTrial_category(:);   % 1=face 2=illusory 3=object
    sess = S.repTrial_session(:);
    img  = S.repTrial_image(:);

    sessions = unique(sess(:))';
    nSess = numel(sessions);
    diffBySession = nan(nT, nSess);   % illusory-minus-object per session

    for k = 1:nSess
        se = sessions(k);
        illTr = pup(:, sess==se & cat==2);
        objTr = pup(:, sess==se & cat==3);
        if isempty(illTr) || isempty(objTr), continue; end
        diffBySession(:,k) = mean(illTr,2,'omitnan') - mean(objTr,2,'omitnan');
    end

    % regress the per-session difference on session number, per timepoint
    good = ~isnan(diffBySession(1,:));           % sessions with both cats
    sv   = sessions(good)';
    svz  = (sv - mean(sv)) ./ std(sv);           % z-score session
    Xd   = [ones(numel(sv),1) svz];
    for t = 1:nT
        y = diffBySession(t,good)';
        b = Xd \ y;
        slope(d,t) = b(2);                        % change in effect per session (z)
    end
    fprintf('rep: sub %02d (%d sessions used)\n', d, sum(good));
end

%% BF timecourse for the session slope
bf = bayesfactor_R_wrapper(slope','returnindex',2,'verbose',false, ...
    'args','mu=0,rscale="medium",nullInterval=c(-0.5,0.5)');
bf = bf(:);

stats = struct('timevect',timevect,'slope',slope,'bf',bf);
save('results/stats_repetition.mat','stats','-v7.3');

%% summarise
nNull = sum(bf < 1/3);
nRel  = sum(bf > 3);
[~,pk] = max(abs(mean(slope,1)));
fprintf('\n=== Illusory-object difference vs session (repetition) ===\n');
fprintf('timepoints BF<1/3 (no change with repetition): %d / %d\n', nNull, nT);
fprintf('timepoints BF>3  (change with repetition):     %d / %d\n', nRel,  nT);
fprintf('peak slope %+0.5f at %d ms | BF there %.3g | max BF %.3g\n', ...
    mean(slope(:,pk)), round(timevect(pk)), bf(pk), max(bf));

%% plot
figure; set(gcf,'Position',[100 100 1000 640]);
subplot(2,1,1); hold on
mu = mean(slope,1); se = std(slope,[],1)/sqrt(nSub);
fill([timevect fliplr(timevect)],[mu+se fliplr(mu-se)],[.3 .3 .6], ...
    'FaceAlpha',.2,'LineStyle','none');
plot(timevect,mu,'Color',[.3 .3 .6],'LineWidth',2);
plot(timevect,zeros(1,nT),'k:');
set(gca,'FontSize',13); ylabel('\Delta(illusory-object) per session');
title('Does the illusory effect change across repetitions?');
subplot(2,1,2); hold on
plot(timevect,log10(bf),'Color',[.3 .3 .6],'LineWidth',1.6);
plot(timevect,log10(3)*ones(1,nT),'k--');
plot(timevect,log10(1/3)*ones(1,nT),'k--');
plot(timevect,zeros(1,nT),'k:');
set(gca,'FontSize',13); ylabel('log_{10} BF'); xlabel('Time from image onset (ms)');
saveas(gcf,'figures/repetition_effect.png');