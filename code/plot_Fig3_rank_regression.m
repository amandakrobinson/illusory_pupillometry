%% plot rank regression results

load('results/stats_rank_regression.mat')

preds = stats.predictors;
labels = {'Human face vs Object' 'Illusory face vs object' 'Illusory face vs human face' 'Luminance' 'Valence'};
timevect=stats.timevect;

%% plot betas

co = tab10(5);

figure(1);clf;
set(gcf,'Position',[1836 -73 1037 947])

l = subplot(2,1,1);
hold on
plot(timevect,timevect*0,'LineWidth',1,'Color',[.7 .7 .7],'HandleVisibility','off')

for a = 1:length(preds)

    mu = stats.results.(preds{a}).mu';
    se = stats.results.(preds{a}).se';

    fill([timevect fliplr(timevect)],[mu+se fliplr(mu-se)],co(a,:),...
        'FaceAlpha',.2,'LineStyle','none','HandleVisibility','off');
    plot(timevect,mu,'LineWidth',2,'Color',co(a,:))
end
legend(labels,'Box','off','Location','best')
set(l,'FontSize',18)
ylabel('Betas')
xlabel('Time from image onset (ms)')
xlim([-267 1500])

for n = 1:length(preds)
    a=subplot(10,1,5+n);
    hold on
    a.FontSize=18;
    bf = stats.results.(preds{n}).bf;

    plot(timevect,1+0*timevect,'k-');
    co3 = [.5 .5 .5;1 1 1;co(n,:)];
    idx = [bf<1/3,1/3<bf & bf<3,bf>3]';
    for i=1:3
        x = timevect(idx(i,:));
        y = bf(idx(i,:));
        if ~isempty(x)
            stem(x,y,'Marker','o','Color',.6*[1 1 1],'BaseValue',1,'MarkerSize',5,'MarkerFaceColor',co3(i,:),'Clipping','off');
            plot(x,y,'o','Color',.6*[1 1 1],'MarkerSize',5,'MarkerFaceColor',co3(i,:),'Clipping','off');
        end
    end
    a.YScale='log';
    ylim([10.^-5 10.^17])
    a.YTick = 10.^([-5 0 10 20]);
    xlim(minmax(timevect))
    text(0,10e10,labels{n},'Color',co(n,:),'FontSize',18)
    ylabel('BF')
    if n==length(preds)
        xlabel('Time (ms)')
    else
        set(gca,'XTickLabels',[])
    end
end


fn = 'figures/Figure3_RankRegression';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');