%% plot pupil data
% by top/bottom luminance
% by top/bottom valence

load('results/allres.mat')
pd_perim = dat.pupil_perim;
allres = dat;

load('results/allmodeldata.mat')
timevect= allres.timevect;

%% plot category
datcat=[];
for a=1:3 % faces, illusory faces, objects
    n = ((a-1)*100+1):((a-1)*100+100);
    datcat(:,a,:) = mean(pd_perim(:,n,:),2);
end

mu = mean(datcat,3);
se = std(datcat,[],3)/sqrt(size(datcat,3));

co = tab10(4);

figure(1);clf;
set(gcf,'Position',[1 274 1600 470])
subplot(1,3,1)
hold on
for a = 1:3

    fill([timevect fliplr(timevect)],[mu(:,a)'+se(:,a)' fliplr(mu(:,a)'-se(:,a)')],co(a,:),...
        'FaceAlpha',.2,'LineStyle','none','HandleVisibility','off');
    plot(timevect,mu(:,a),'LineWidth',2,'Color',co(a,:))
end
ylim([-1.5 .7])
title('Category')
legend({'Human face' 'Illusory face' 'Non-face object'},...
    'Box','off','Location','best')
set(gca,'FontSize',18)
ylabel('Change in pupil diameter')
xlabel('Time from image onset (ms)')
xlim([-267 1500])

% plot luminance

% sort luminance
[~,j] = sort(dat.luminance.data); % image indices from low to high luminance

nlevels = 10;
co = plasma(10);

l = subplot(1,3,2);
hold on
for a = 1:nlevels

    idx = ((a-1)*(300/nlevels)+1):(a*(300/nlevels));
    lumims = j(idx);
    lumdat = squeeze(mean(pd_perim(:,lumims,:),2));

    mu = mean(lumdat,2);
    se = std(lumdat,[],2)/sqrt(size(lumdat,2));

    fill([timevect fliplr(timevect)],[mu'+se' fliplr(mu'-se')],co(a,:),...
        'FaceAlpha',.2,'LineStyle','none','HandleVisibility','off');
    plot(timevect,mu,'LineWidth',2,'Color',co(a,:))
end
colormap(l,flipud(co))
c=colorbar(l,'Ticks',[.05 .95],'TickLabels',{'brightest\newline10%' 'darkest\newline10%'});
c.Position = [.57 .16 .01 .3];
title('Luminance')
set(l,'FontSize',18)
ylabel('Change in pupil diameter')
xlabel('Time from image onset (ms)')
ylim([-1.5 .7])
xlim([-267 1500])

% plot valence
[i,j] = sort(dat.valence.mu);

nlevels = 10;
co = viridis(11);

v=subplot(1,3,3);
hold on
for a = 1:nlevels

    idx = ((a-1)*(300/nlevels)+1):(a*(300/nlevels));
    valims = j(idx);
    valdat = squeeze(mean(pd_perim(:,valims,:),2));

    mu = mean(valdat,2);
    se = std(valdat,[],2)/sqrt(size(valdat,2));

    fill([timevect fliplr(timevect)],[mu'+se' fliplr(mu'-se')],co(a,:),...
        'FaceAlpha',.2,'LineStyle','none','HandleVisibility','off');
    plot(timevect,mu,'LineWidth',2,'Color',co(a,:))
end
colormap(v,co(1:10,:))

c=colorbar(v,'Ticks',[.05 .95],...
    'TickLabels',{'most\newlinenegative\newline10%' 'most\newlinepositive\newline10%'...
    });
c.Position = [.85 .16 .01 .3];
title('Valence')
set(v,'FontSize',18)
ylabel('Change in pupil diameter')
xlabel('Time from image onset (ms)')
ylim([-1.5 .7])
xlim([-267 1500])

%%
annotation('textbox',[0.09 .88 .1 .1],...
    'String','A','FontSize',30,'LineStyle','none')

annotation('textbox',[0.365 .88 .1 .1],...
    'String','B','FontSize',30,'LineStyle','none')

annotation('textbox',[0.645 .88 .1 .1],...
    'String','C','FontSize',30,'LineStyle','none')

%%
fn = 'figures/Figure2_pupildiameter';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=1;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');