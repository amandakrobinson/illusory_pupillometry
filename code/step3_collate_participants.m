%% collate eye data

datfiles = dir('results/sub*.mat');

timevect = load(sprintf('results/%s',datfiles(1).name),'timevect_reduced');
timevect = timevect.timevect_reduced;

pd_perim=[];ntrials=[];baseline_size_mm=[];
for d = 1:length(datfiles)
    fprintf('Loading %s...\n',datfiles(d).name)
    pdat = load(sprintf('results/%s',datfiles(d).name),'DATA_pupilSize_sorted_im','repTrial_baseline');

    % get mean diameter per image and number of trials
    for i = 1:300
        stimdat = pdat.DATA_pupilSize_sorted_im.(sprintf('stim%d',i));
        pd_perim(:,i,d) = mean(stimdat,2); % mean diameter for each image
        ntrials(i,d) = size(stimdat,2); % number of trials taken for mean
    end

    baseline_size_mm(d) = mean(pdat.repTrial_baseline)*.07;
end


dat.pupil_perim = pd_perim;
dat.ntrials_perim = ntrials;
dat.timevect = timevect;
dat.stimorder = {'face' 'illusory' 'objects'};
dat.baseline_pupil_mm = baseline_size_mm;

nt = dat.ntrials_perim;
sup = sum(nt,1);
mutotal = mean(sup);

mup = mean(nt,1);
mu = mean(mup);
sd = std(mup);
minpp = min(mup);
fprintf(['From %d subjs, there are a total mean of %.06g valid trials per participant\n' ...
    ': %.06g per image (SD = %04g; MIN = %d)\n'],length(mup),mutotal,mu,sd,minpp)
fprintf(['Mean baseline pupil size is:' ...
    ': %.03g mm (SD = %03g; MIN = %.05g; MAX = %.05g)\n'],mean(baseline_size_mm),std(baseline_size_mm),min(baseline_size_mm),max(baseline_size_mm))


save('results/allres.mat','dat','-v7.3')
