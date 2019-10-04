function [ mean_precision, mean_recall ] = evaluation2( predict_label, true_label)
%EVALUATION Summary of this function goes here
%   Detailed explanation goes here

% true attribute of testing set
[row, col] = size(predict_label);
true_label = true_label(:,1:col);
num = size(predict_label,1);
comp = abs(predict_label - true_label);
acc = 1-sum(comp)/size(comp,1);

pred = sum(predict_label');
true = sum(true_label');
comp_sum = sum(comp');

precision = [];
recall = [];
for k=1:num,
    predict1 = predict_label(k,:);
    true1 = true_label(k,:);
    precision = [precision, sum(predict1==true1 & predict1==1)/(sum(predict1==1)+0.01)];
    recall = [recall, sum(predict1==true1 & predict1==1)/(sum(true1==1)+0.01)];
end
mean_precision = mean(precision);
mean_recall = mean(recall);

% plot bar graph for true label and predicted label
figure('Units','characters','Position',[30 30 120 35]);
[ax,b,p1] = plotyy(1:num,pred,1:num,true,'bar','plot');
hold on
%[ax,b,p2] = plotyy(1:40,pred,1:40,comp_sum,'bar','plot');
xlabel('training sample')
set(p1,'marker','o','color','red')
ylabel(ax(1),'predicted attributes') % left y-axis
ylabel(ax(2),'true attributes') % right y-axis
tmp = col/10;

set(ax(1),'YLim',[1 col])
set(ax(1),'YTick',[1:tmp:col])
set(ax(2),'YLim',[1 col])
set(ax(2),'YTick',[1:tmp:col])
tmp = num + 1;
set(ax(1),'xlim',[0 tmp]);
set(ax(2),'xlim',[0 tmp]);
legend('number of predicted 1s','number of true 1s','Location','northwest')

% accuracy rate
acc = 1-sum(comp)/size(comp,1);
mean(acc)



end

