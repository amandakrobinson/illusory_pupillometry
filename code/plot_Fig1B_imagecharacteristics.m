load('results/allmodeldata.mat')

lum = dat.luminance.data;
valence = dat.valence.mu;
val_se = dat.valence.se;

%% set up for plotting
cols = viridis(4);
X = 1:300;
catnames = {'Human faces' 'Illusory faces' 'Non-face objects'};
labels = cellfun(@(x) strrep(x,' ','\newline'), catnames,'UniformOutput',false);

%% plot luminance and valence

fs = 30;
figure(1);clf;
set(gcf,'Position',[1500 80 1500 900])

% plot mean valence and luminance scores
a=subplot(2,2,1);
a.Position(4) = a.Position(4)-.04;
hold on
for i=1:3
    idx = (i-1)*100+1;
    plot(X(idx:(idx+99)),lum(idx:(idx+99)),'.','MarkerSize',30,'Color',cols(i,:))
end
set(gca,'XTick',50:100:250)
set(gca,'XTickLabels',labels)
ylabel('Mean Luminance')
xlim([1 300])
ylim([0 1])
title('Luminance')
set(gca,'LineWidth',2)
set(gca,'FontSize',fs)

a=subplot(2,2,2);
a.Position(4) = a.Position(4)-.04;
hold on
for i=1:3
    idx = (i-1)*100+1;
    plot(X(idx:(idx+99)),valence(idx:(idx+99)),'.','MarkerSize',30,'Color',cols(i,:))
    errorbar(idx:(idx+99),valence(idx:(idx+99)),val_se(idx:(idx+99)),...
        'Color',cols(i,:),'LineStyle','none','CapSize',2,'HandleVisibility','off')
end
set(gca,'XTick',50:100:250)
set(gca,'XTickLabels',labels)
ylabel('Mean rating')
xlim([1 300])
ylim([0 10])
title('Valence')
set(gca,'LineWidth',2)
set(gca,'FontSize',fs)

% plot face judgement results

load('results/facelike_ratings.mat')
rate = ratingsdat;

% ratings per item
datm = rate.alldat;
datmu = mean(datm,1);
datse = std(datm,[],1)/sqrt(size(datm,1));

% plot ratings
a=subplot(2,2,3);
set(a,'FontSize',fs)
a.Position(4) = a.Position(4)-.04;

hold on
for i = 1:3
    idx = (i-1)*100+(1:100);
    % plot(idx,datmu(idx),'o','MarkerFaceColor',cols(i,:),'MarkerEdgeColor','none')
    plot(idx,datmu(idx),'.','MarkerSize',30, 'Color',cols(i,:))
    errorbar(idx,datmu(idx),datse(idx),...
        'Color',cols(i,:),'LineStyle','none','CapSize',2,'HandleVisibility','off')
end
set(gca,'XTick',50:100:250)
set(gca,'XTickLabels',labels)
ylabel('Mean Rating')
xlim([1 300])
title('Face-like ratings')


% face/object categorisation

load('results/faceobjResults.mat','res')
resp = squeeze(mean(res.faceresp_image,2));
mu = mean(resp,2);
se = std(resp,[],2)/sqrt(size(resp,2));

% plot image stuff
a=subplot(2,2,4)
a.Position(4) = a.Position(4)-.04;
set(a,'FontSize',fs)
hold on
for i = 1:3
    idx = (i-1)*100+(1:100);
    plot(idx,mu(idx),'.','Color',cols(i,:),'MarkerSize',30)
    errorbar(idx,mu(idx),se(idx),...
        'Color',cols(i,:),'LineStyle','none','CapSize',2,'HandleVisibility','off')
end
ylabel('Proportion "face" choice')
xlim([1 300])
xt=50:100:250;
set(gca,'XTick',xt)
set(gca,'XTickLabel',labels)
title('Face/object categorisation')

fn = 'figures/Figure1B_imagecharacteristics';
set(gcf,'Renderer','painters')
print(gcf,'-dpng','-r500',fn)
im=imread([fn '.png']);
[i,j]=find(mean(im,3)<255);margin=2;
imwrite(im(min(i-margin):max(i+margin),min(j-margin):max(j+margin),:),[fn '.png'],'png');
