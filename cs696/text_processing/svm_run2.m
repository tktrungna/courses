% Training SVM classifiers and testing accuracy on the first 
% training-testing dataset, generate figures
clear; close all

load('../mat/crossvalid.mat')
predict = [];
for i=1:size(FEAT.TRAIN{1},2),
    group = FEAT.TRAIN{1}(:,i);
    if sum(group==1)==0,
        label = zeros(40,1);
        predict = [predict,label];
        continue;
    end
    if sum(group==0)==0,
        label = ones(40,1);
        predict = [predict,label];
        continue;
    end
    svmStruct = svmtrain(DATA.TRAIN{1},group);
    label = svmclassify(svmStruct,DATA.TEST{1});
    predict = [predict,label];
end
%predict
%%
close all
comp = abs(predict - FEAT.TEST{1});
acc = 1-sum(comp)/size(comp,1);
attr = load('../mat/attr_type.mat');
attr = attr.attr_type;
attr = [attr,num2cell(acc')];

for id=1:40,
    attr = [attr,num2cell(predict(id,:)'),...
        num2cell(FEAT.TEST{1}(id,:)')];
end
% compare predicted labels and true labels (number of 1s)
pred = sum(predict');
true = sum(FEAT.TEST{1}');
comp_sum = sum(comp');
figure('Units','characters','Position',[30 30 120 35]);
[ax,b,p1] = plotyy(1:40,pred,1:40,true,'bar','plot');
hold on
%[ax,b,p2] = plotyy(1:40,pred,1:40,comp_sum,'bar','plot');
xlabel('training sample')
set(p1,'marker','o','color','red')
ylabel(ax(1),'predicted attributes') % left y-axis
ylabel(ax(2),'true attributes') % right y-axis
%set(p2,'marker','s','color','green')
%set(ax,'YLim',1:300,1:300)
set(ax(1),'YLim',[1 312])
set(ax(1),'YTick',[1:30:312])
set(ax(2),'YLim',[1 312])
set(ax(2),'YTick',[1:30:312])
set(ax(1),'xlim',[0 41]);
set(ax(2),'xlim',[0 41]);
legend('number of predicted 1s','number of true 1s','Location','northwest')
% figure error rate (compare predicted and true labels)
figure('Units','characters','Position',[30 30 120 35]);
err = sum(comp');
cor = ones(1,40)*312-err;
bar([cor;err]','stacked');
set(gca,'XLim',[0 41]);
set(gca,'YLim',[0 312]);
xlabel('training sample')

mean_acc = mean(acc)
mean_err = mean(err)/312
mean_1slables = mean(true)/312
mean_0slables = 1-mean(true)/312

%% precision and recall
precision = [];recall = [];
for k=1:40,
    predict1 = predict(k,:);
    true1 = FEAT.TEST{1}(k,:);
    precision = [precision, sum(predict1==true1 & predict1==1)/sum(predict1==1)];
    recall = [recall, sum(predict1==true1 & predict1==1)/sum(true1==1)];
end
mean(precision)
mean(recall)